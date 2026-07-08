"""
Central request lifecycle handling controller (EDD V2, Document 03).

Implements the full pipeline: auth -> rate limit -> cache check -> context
hydration -> Gemini inference -> deterministic scoring -> response
build -> persistence. Business rules (budget bounds, cache TTL, exactly-3
briefs) are enforced here or in the services/repository layers they
delegate to — this controller's job is orchestration, not calculation.
"""

import asyncio
import hashlib
import time
from collections import defaultdict

from fastapi import APIRouter, Depends, HTTPException, status

from config.settings import Settings, get_settings
from core.exceptions import BudgetExhaustedError, ConstituencyNotFoundError, MissionPipelineError
from core.logging import get_logger
from core.security import verify_firebase_token
from domain.schemas.requests import MissionGenerationRequest
from domain.schemas.responses import (
    MapLayersResponse,
    MapSignalResponse,
    MapWardResponse,
    MissionBrief,
    MissionHistoryItem,
    MissionHistoryListResponse,
    MissionResponse,
)
from infrastructure.firestore_repo import FirestoreRepository
from services.ai_pipeline import AIPipelineService

logger = get_logger(__name__)
router = APIRouter()


class _InMemoryRateLimiter:
    """
    Fixed-window rate limiter: max N requests per 60s window, per user.

    In-memory and per-process by design for this MVP — acceptable given
    the single-instance Cloud Run deployment target in EDD V2 Document 01.
    A multi-instance deployment would need a shared store (e.g. Firestore
    or Redis) instead; noted as a known limitation, not implemented here
    since no such store was specified in the frozen architecture.
    """

    def __init__(self) -> None:
        self._hits: dict[str, list[float]] = defaultdict(list)

    def check(self, key: str, max_per_minute: int) -> None:
        now = time.monotonic()
        window_start = now - 60.0
        recent_hits = [t for t in self._hits[key] if t >= window_start]

        if len(recent_hits) >= max_per_minute:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Rate limit exceeded: max {max_per_minute} requests per minute.",
            )

        recent_hits.append(now)
        self._hits[key] = recent_hits


_rate_limiter = _InMemoryRateLimiter()


def _get_firestore_repository() -> FirestoreRepository:
    return FirestoreRepository()


def _get_ai_pipeline_service() -> AIPipelineService:
    return AIPipelineService()


@router.post("/mission/generate", response_model=MissionResponse, status_code=status.HTTP_200_OK)
async def generate_mission_briefs(
    request: MissionGenerationRequest,
    user_id: str = Depends(verify_firebase_token),
    repo: FirestoreRepository = Depends(_get_firestore_repository),
    ai_service: AIPipelineService = Depends(_get_ai_pipeline_service),
    settings: Settings = Depends(get_settings),
) -> MissionResponse:
    _rate_limiter.check(user_id, settings.rate_limit_per_minute)

    command_raw = f"{request.command.strip().lower()}_{request.constituency_id}"
    command_hash = hashlib.sha256(command_raw.encode("utf-8")).hexdigest()

    # Cache interceptor execution layer
    cached_response = await repo.check_ai_cache(command_hash)
    if cached_response:
        logger.info("ai_cache hit for hash '%s'.", command_hash)
        return MissionResponse.model_validate(cached_response)

    constituency = await repo.get_constituency(request.constituency_id)
    if not constituency:
        raise ConstituencyNotFoundError(request.constituency_id)

    if constituency.remaining_budget <= 0:
        raise BudgetExhaustedError(request.constituency_id)

    wards = await repo.get_wards(request.constituency_id)
    active_signals = await repo.get_signals_within_bounds(
        request.constituency_id, request.map_bounds
    )

    try:
        raw_ai_response = await asyncio.wait_for(
            ai_service.execute_inference(
                command=request.command,
                signals=active_signals,
                wards=wards,
                remaining_budget=constituency.remaining_budget,
            ),
            timeout=settings.request_timeout_seconds,
        )
    except TimeoutError as exc:
        raise MissionPipelineError(
            "AI pipeline timed out.", status_code=status.HTTP_504_GATEWAY_TIMEOUT
        ) from exc

    final_briefs: list[MissionBrief] = []
    for brief in raw_ai_response.briefs:
        budget = min(brief.budget, constituency.remaining_budget)
        impact_score = ai_service.calculate_deterministic_impact(brief, wards, active_signals)
        decay_rate = ai_service.normalize_decay_rate(brief)

        final_briefs.append(
            MissionBrief(
                mission_id=brief.mission_id,
                mission=brief.mission,
                priority=brief.priority,
                budget=budget,
                impact_score=impact_score,
                confidence=brief.confidence,
                confidence_explanation=brief.confidence_explanation,
                beneficiaries=brief.beneficiaries,
                estimated_completion=brief.estimated_completion,
                department=brief.department,
                evidence=brief.evidence[:3],
                risks=brief.risks,
                action_items=brief.action_items,
                success_metrics=brief.success_metrics,
                timeline_decay_rate=decay_rate,
                alternative=brief.alternative,
            )
        )

    response_payload = MissionResponse(
        mission_id=f"plan_{command_hash[:8]}",
        command_summary=raw_ai_response.command_summary,
        briefs=final_briefs,
    )

    response_dict = response_payload.model_dump(mode="json")
    await repo.save_mission_history(
        user_id, request.constituency_id, request.command, response_dict
    )
    await repo.write_ai_cache(command_hash, request.command, response_dict)

    return response_payload


@router.get(
    "/mission/history",
    response_model=MissionHistoryListResponse,
    status_code=status.HTTP_200_OK,
)
async def get_mission_history(
    constituency_id: str,
    user_id: str = Depends(verify_firebase_token),
    repo: FirestoreRepository = Depends(_get_firestore_repository),
) -> MissionHistoryListResponse:
    """
    Fetch the authenticated user's mission history for a constituency.

    Not part of the literal EDD V2 Document 03 contract — added to fill
    the "History Mode" requirement in Document 01's state machine, which
    has no corresponding read endpoint in the frozen API spec. See
    DECISIONS.md for the full rationale.
    """
    raw_items = await repo.get_mission_history(user_id, constituency_id)
    return MissionHistoryListResponse(
        items=[MissionHistoryItem.model_validate(item) for item in raw_items]
    )


@router.get(
    "/constituency/{constituency_id}/map_layers",
    response_model=MapLayersResponse,
    status_code=status.HTTP_200_OK,
)
async def get_map_layers(
    constituency_id: str,
    user_id: str = Depends(verify_firebase_token),
    repo: FirestoreRepository = Depends(_get_firestore_repository),
) -> MapLayersResponse:
    """
    Fetch ward polygons and open signals for a constituency.
    Satisfies Decision 8: served through backend APIs only.
    """
    wards = await repo.get_wards(constituency_id)
    signals = await repo.get_all_signals(constituency_id)
    return MapLayersResponse(
        wards=[MapWardResponse(**w.model_dump()) for w in wards],
        signals=[MapSignalResponse(**s.model_dump(exclude={"timestamp"})) for s in signals]
    )

