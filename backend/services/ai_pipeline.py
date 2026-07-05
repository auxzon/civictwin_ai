"""
Gemini API wrapper and context structuring (EDD V2, Document 04).

Per Decision 1, this uses the Gemini Developer API (`google-genai`), not
Vertex AI, despite the "Vertex AI / Gemini API wrapper" phrasing in the
original Document 01 folder-structure comment.

This service is the seam between LLM semantic reasoning and deterministic
post-processing: `execute_inference` only produces the *raw* AI-authored
brief content (mission narrative, priority, confidence, etc.);
`calculate_deterministic_impact` — which never touches the LLM — is what
actually assigns `impact_score` before a brief is allowed into the
outbound `MissionResponse`.
"""

import json
from collections import Counter
from pathlib import Path
from typing import Literal

from pydantic import BaseModel, Field

from core.exceptions import MissionPipelineError
from core.logging import get_logger
from domain.models.firestore import Signal, Ward
from infrastructure.gemini_client import GeminiClient
from services import impact_engine, timeline_engine

logger = get_logger(__name__)

_PROMPT_TEMPLATE_PATH = Path(__file__).resolve().parent.parent / "prompts" / "recommended_plan.txt"


class AIMissionBrief(BaseModel):
    """
    Rigid outbound schema Gemini is constrained to produce (Document 04).

    This is intentionally distinct from `domain.schemas.responses.MissionBrief`:
    this one is what the LLM is allowed to author; the response DTO is what
    the client actually receives, after deterministic post-processing
    overwrites `impact_score`.
    """

    mission_id: str = Field(
        description="Unique brief identifier format matching brief_01, brief_02..."
    )
    mission: str = Field(
        description="High-impact descriptive title string mapping recommended plan goals."
    )
    priority: Literal["HIGH", "MEDIUM", "LOW"] = Field(
        description="Priority tracking configuration tag."
    )
    budget: int = Field(description="Estimated target operational budget execution metrics in INR.")
    confidence: int = Field(description="Confidence percentage index range scaling 0-100.")
    confidence_explanation: str = Field(
        description="Detailed explainable justification citing signal density, "
        "infrastructure alignment, and budget matching variables."
    )
    beneficiaries: int = Field(
        description="Projected metric tracking total positive local population reach."
    )
    estimated_completion: str = Field(
        description="Target developmental length time-frame metadata string."
    )
    department: str = Field(
        description="Target execution branch tracking administrative ownership assignment."
    )
    evidence: list[str] = Field(description="Maximum 3 matching signal document IDs.")
    risks: str = Field(
        description="Explicit physical or local operational risk barriers identified."
    )
    action_items: list[str] = Field(
        description="Strictly 3 discrete high-velocity actionable bullet definitions."
    )
    success_metrics: list[str] = Field(
        description="Strictly 2 rigid measurable numerical KPI targets."
    )
    timeline_decay_rate: float = Field(description="Linear decay scale modifier, 0.01-0.50.")
    alternative: str = Field(description="Runner-up ward identifier string.")


class AIRawResponse(BaseModel):
    """Rigid outbound container schema Gemini is constrained to produce."""

    command_summary: str = Field(description="High-level aggregative summarization statement.")
    briefs: list[AIMissionBrief] = Field(
        description="Array containing exactly three unique brief objects."
    )


class AIPipelineService:
    """Orchestrates Gemini inference and deterministic post-processing."""

    def __init__(self) -> None:
        self._gemini = GeminiClient()
        self._prompt_template = _PROMPT_TEMPLATE_PATH.read_text(encoding="utf-8")

    def _build_prompt(
        self,
        command: str,
        signals: list[Signal],
        wards: list[Ward],
        remaining_budget: int,
    ) -> str:
        signals_json = json.dumps([s.model_dump(mode="json") for s in signals])
        wards_json = json.dumps([w.model_dump(mode="json") for w in wards])
        return self._prompt_template.format(
            remaining_budget=remaining_budget,
            signals_json_payload=signals_json,
            wards_json_payload=wards_json,
            user_command=command,
        )

    async def execute_inference(
        self,
        command: str,
        signals: list[Signal],
        wards: list[Ward],
        remaining_budget: int,
    ) -> AIRawResponse:
        """Run the Gemini structured-generation call and validate its output."""
        prompt = self._build_prompt(command, signals, wards, remaining_budget)

        try:
            raw_json = await self._gemini.generate_structured_json(prompt, AIRawResponse)
            parsed = AIRawResponse.model_validate_json(raw_json)
        except Exception as exc:
            logger.error("Gemini inference/validation failed: %s", exc)
            raise MissionPipelineError(f"AI pipeline failure: {exc}") from exc

        if len(parsed.briefs) != 3:
            raise MissionPipelineError(
                f"Expected exactly 3 briefs from Gemini, received {len(parsed.briefs)}."
            )

        return parsed

    def calculate_deterministic_impact(
        self,
        brief: AIMissionBrief,
        wards: list[Ward],
        signals: list[Signal],
    ) -> int:
        """
        Compute the final, trusted impact_score for a brief.

        The target ward for a brief is resolved from the majority ward_id
        among its cited evidence signals — the AIMissionBrief schema has
        no direct ward_id field, only evidence (signal IDs) and an
        `alternative` runner-up ward ID, so the primary ward must be
        inferred from which ward the cited signals actually belong to.
        """
        signals_by_id = {s.id: s for s in signals}
        wards_by_id = {w.id: w for w in wards}

        evidence_ward_ids = [
            signals_by_id[sig_id].ward_id for sig_id in brief.evidence if sig_id in signals_by_id
        ]

        target_ward_id = (
            Counter(evidence_ward_ids).most_common(1)[0][0]
            if evidence_ward_ids
            else brief.alternative
        )
        target_ward = wards_by_id.get(target_ward_id)

        if target_ward is None:
            logger.warning(
                "Could not resolve target ward for brief '%s' (evidence=%s); "
                "using conservative defaults for scoring.",
                brief.mission_id,
                brief.evidence,
            )
            population, infra_count = 1, 1
        else:
            population, infra_count = (
                target_ward.population,
                target_ward.critical_infrastructure_count,
            )

        return impact_engine.calculate_deterministic_impact(
            brief_budget=brief.budget,
            brief_beneficiaries=brief.beneficiaries,
            brief_evidence_len=len(brief.evidence),
            target_ward_population=population,
            target_ward_infra_count=infra_count,
        )

    @staticmethod
    def normalize_decay_rate(brief: AIMissionBrief) -> float:
        """Clamp Gemini's timeline_decay_rate into the frozen valid range."""
        return timeline_engine.clamp_decay_rate(brief.timeline_decay_rate)
