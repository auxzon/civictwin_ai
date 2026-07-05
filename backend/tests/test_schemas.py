"""Unit tests for domain/schemas request and response validation."""

import pytest
from pydantic import ValidationError

from domain.schemas.requests import MapBounds, MissionGenerationRequest
from domain.schemas.responses import MissionBrief


def _valid_bounds() -> dict:
    return {"ne": {"lat": 19.1654, "lng": 72.8524}, "sw": {"lat": 19.0760, "lng": 72.8300}}


def test_valid_map_bounds_accepted() -> None:
    bounds = MapBounds.model_validate(_valid_bounds())
    assert bounds.ne.lat == 19.1654


def test_inverted_bounds_rejected() -> None:
    """sw must be south-west of ne; a north-east sw should fail validation."""
    bad_bounds = {"ne": {"lat": 19.0, "lng": 72.0}, "sw": {"lat": 20.0, "lng": 73.0}}
    with pytest.raises(ValidationError):
        MapBounds.model_validate(bad_bounds)


def test_mission_generation_request_requires_nonempty_command() -> None:
    with pytest.raises(ValidationError):
        MissionGenerationRequest.model_validate(
            {"constituency_id": "const_mumbai_north", "command": "", "map_bounds": _valid_bounds()}
        )


def test_mission_generation_request_valid_payload() -> None:
    req = MissionGenerationRequest.model_validate(
        {
            "constituency_id": "const_mumbai_north",
            "command": "Allocate funds for drinking water in Ward 14",
            "map_bounds": _valid_bounds(),
        }
    )
    assert req.constituency_id == "const_mumbai_north"


def _valid_brief_kwargs() -> dict:
    return {
        "mission_id": "brief_01",
        "mission": "Optimized Ward 14 Water Grid System",
        "priority": "HIGH",
        "budget": 4_000_000,
        "impact_score": 94,
        "confidence": 96,
        "confidence_explanation": "High confidence.",
        "beneficiaries": 24_830,
        "estimated_completion": "6 Months",
        "department": "Public Health Engineering Department",
        "evidence": ["sig_8829", "sig_9102"],
        "risks": "Monsoon delays.",
        "action_items": ["a", "b", "c"],
        "success_metrics": ["m1", "m2"],
        "timeline_decay_rate": 0.15,
        "alternative": "ward_17",
    }


def test_mission_brief_rejects_wrong_action_item_count() -> None:
    kwargs = _valid_brief_kwargs()
    kwargs["action_items"] = ["only_one"]
    with pytest.raises(ValidationError):
        MissionBrief.model_validate(kwargs)


def test_mission_brief_rejects_wrong_success_metric_count() -> None:
    kwargs = _valid_brief_kwargs()
    kwargs["success_metrics"] = ["only_one"]
    with pytest.raises(ValidationError):
        MissionBrief.model_validate(kwargs)


def test_mission_brief_rejects_more_than_3_evidence_ids() -> None:
    kwargs = _valid_brief_kwargs()
    kwargs["evidence"] = ["a", "b", "c", "d"]
    with pytest.raises(ValidationError):
        MissionBrief.model_validate(kwargs)


def test_mission_brief_rejects_decay_rate_out_of_bounds() -> None:
    kwargs = _valid_brief_kwargs()
    kwargs["timeline_decay_rate"] = 0.99
    with pytest.raises(ValidationError):
        MissionBrief.model_validate(kwargs)


def test_mission_brief_valid_payload_accepted() -> None:
    brief = MissionBrief.model_validate(_valid_brief_kwargs())
    assert brief.mission_id == "brief_01"
