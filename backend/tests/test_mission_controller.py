"""
Integration tests for POST /api/v1/mission/generate.

The Firestore repository and AI pipeline are replaced via FastAPI
dependency overrides with in-memory fakes — these tests verify the
controller's orchestration logic (auth wiring, cache short-circuit,
budget checks, deterministic score injection) without touching real
Firebase or Gemini.
"""

from datetime import UTC, datetime
from unittest.mock import AsyncMock

import pytest
from fastapi.testclient import TestClient

from api.v1.controllers import mission as mission_controller
from core.security import verify_firebase_token
from domain.models.firestore import Constituency, GeoPointModel, Signal, Ward
from services.ai_pipeline import AIMissionBrief, AIRawResponse


def _sample_constituency(budget_utilized: int = 0) -> Constituency:
    return Constituency(
        id="const_mumbai_north",
        name="Mumbai North",
        state="Maharashtra",
        total_budget_allocated=50_000_000,
        budget_utilized=budget_utilized,
        center=GeoPointModel(latitude=19.1154, longitude=72.8624),
    )


def _sample_ward() -> Ward:
    return Ward(
        id="ward_14",
        ward_number="14",
        name="Malad East",
        population=62_400,
        critical_infrastructure_count=3,
        polygon_coordinates=[],
    )


def _sample_signal() -> Signal:
    return Signal(
        id="sig_8829",
        ward_id="ward_14",
        category="Water",
        severity=9,
        coords=GeoPointModel(latitude=19.183, longitude=72.848),
        description="No water",
        status="Open",
        timestamp=datetime.now(UTC),
    )


def _sample_ai_response() -> AIRawResponse:
    brief_kwargs = {
        "priority": "HIGH",
        "budget": 4_000_000,
        "confidence": 96,
        "confidence_explanation": "High confidence.",
        "beneficiaries": 24_830,
        "estimated_completion": "6 Months",
        "department": "Public Health Engineering",
        "evidence": ["sig_8829"],
        "risks": "Monsoon delays.",
        "action_items": ["a", "b", "c"],
        "success_metrics": ["m1", "m2"],
        "timeline_decay_rate": 0.15,
        "alternative": "ward_17",
    }
    return AIRawResponse(
        command_summary="Water Allocation Plan",
        briefs=[
            AIMissionBrief(mission_id="brief_01", mission="Plan A", **brief_kwargs),
            AIMissionBrief(mission_id="brief_02", mission="Plan B", **brief_kwargs),
            AIMissionBrief(mission_id="brief_03", mission="Plan C", **brief_kwargs),
        ],
    )


def _request_body() -> dict:
    return {
        "constituency_id": "const_mumbai_north",
        "command": "Allocate funds for drinking water in Ward 14",
        "map_bounds": {
            "ne": {"lat": 19.1654, "lng": 72.8524},
            "sw": {"lat": 19.0760, "lng": 72.8300},
        },
    }


@pytest.fixture
def client_with_mocks():
    """A TestClient with auth, Firestore, and Gemini all replaced by fakes."""
    from main import app

    mock_repo = AsyncMock()
    mock_repo.check_ai_cache.return_value = None
    mock_repo.get_constituency.return_value = _sample_constituency()
    mock_repo.get_wards.return_value = [_sample_ward()]
    mock_repo.get_signals_within_bounds.return_value = [_sample_signal()]

    mock_ai_service = AsyncMock()
    mock_ai_service.execute_inference.return_value = _sample_ai_response()
    mock_ai_service.calculate_deterministic_impact = lambda brief, wards, signals: 87
    mock_ai_service.normalize_decay_rate = staticmethod(lambda brief: 0.15)

    app.dependency_overrides[verify_firebase_token] = lambda: "test-user-uid"
    app.dependency_overrides[mission_controller._get_firestore_repository] = lambda: mock_repo
    app.dependency_overrides[mission_controller._get_ai_pipeline_service] = lambda: mock_ai_service

    with TestClient(app) as client:
        yield client, mock_repo, mock_ai_service

    app.dependency_overrides.clear()


def test_generate_mission_returns_three_briefs_with_injected_scores(client_with_mocks) -> None:
    client, mock_repo, mock_ai_service = client_with_mocks

    response = client.post("/api/v1/mission/generate", json=_request_body())

    assert response.status_code == 200
    body = response.json()
    assert len(body["briefs"]) == 3
    assert all(brief["impact_score"] == 87 for brief in body["briefs"])
    mock_repo.save_mission_history.assert_awaited_once()
    mock_repo.write_ai_cache.assert_awaited_once()


def test_generate_mission_returns_cached_response_without_calling_ai(client_with_mocks) -> None:
    client, mock_repo, mock_ai_service = client_with_mocks

    cached_payload = {
        "mission_id": "plan_cached01",
        "command_summary": "Cached Plan",
        "briefs": [],
    }
    mock_repo.check_ai_cache.return_value = cached_payload

    response = client.post("/api/v1/mission/generate", json=_request_body())

    assert response.status_code == 200
    assert response.json()["mission_id"] == "plan_cached01"
    mock_ai_service.execute_inference.assert_not_called()


def test_generate_mission_returns_404_for_unknown_constituency(client_with_mocks) -> None:
    client, mock_repo, _ = client_with_mocks
    mock_repo.get_constituency.return_value = None

    response = client.post("/api/v1/mission/generate", json=_request_body())

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "constituency_not_found"


def test_generate_mission_returns_400_when_budget_exhausted(client_with_mocks) -> None:
    client, mock_repo, _ = client_with_mocks
    mock_repo.get_constituency.return_value = _sample_constituency(budget_utilized=50_000_000)

    response = client.post("/api/v1/mission/generate", json=_request_body())

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "budget_exhausted"


def test_generate_mission_caps_budget_at_remaining_amount(client_with_mocks) -> None:
    client, mock_repo, _ = client_with_mocks
    # Only 2,000,000 remaining, but the AI briefs each request 4,000,000.
    mock_repo.get_constituency.return_value = _sample_constituency(budget_utilized=48_000_000)

    response = client.post("/api/v1/mission/generate", json=_request_body())

    assert response.status_code == 200
    for brief in response.json()["briefs"]:
        assert brief["budget"] <= 2_000_000


def test_generate_mission_requires_authentication() -> None:
    from main import app

    app.dependency_overrides.clear()
    with TestClient(app) as client:
        response = client.post("/api/v1/mission/generate", json=_request_body())

    assert response.status_code in (400, 401, 422)


def test_get_mission_history_returns_items(client_with_mocks) -> None:
    client, mock_repo, _ = client_with_mocks
    mock_repo.get_mission_history.return_value = [
        {
            "id": "hist_1",
            "command": "Allocate funds for Ward 14",
            "selected_plan_payload": {
                "mission_id": "plan_abc123",
                "command_summary": "Water Plan",
                "briefs": [],
            },
            "is_implemented": False,
            "created_at": "2026-07-01T00:00:00+00:00",
        }
    ]

    response = client.get(
        "/api/v1/mission/history", params={"constituency_id": "const_mumbai_north"}
    )

    assert response.status_code == 200
    body = response.json()
    assert len(body["items"]) == 1
    assert body["items"][0]["id"] == "hist_1"
    mock_repo.get_mission_history.assert_awaited_once_with("test-user-uid", "const_mumbai_north")


def test_get_mission_history_empty_when_no_history(client_with_mocks) -> None:
    client, mock_repo, _ = client_with_mocks
    mock_repo.get_mission_history.return_value = []

    response = client.get(
        "/api/v1/mission/history", params={"constituency_id": "const_mumbai_north"}
    )

    assert response.status_code == 200
    assert response.json()["items"] == []


def test_get_mission_history_requires_authentication() -> None:
    from main import app

    app.dependency_overrides.clear()
    with TestClient(app) as client:
        response = client.get(
            "/api/v1/mission/history", params={"constituency_id": "const_mumbai_north"}
        )

    assert response.status_code in (400, 401, 422)
