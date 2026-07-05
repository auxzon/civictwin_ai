"""
Unit tests for services/ai_pipeline.py deterministic components.

`execute_inference` (the actual Gemini call) is intentionally not tested
here — it requires a real network call and API key. What's tested is
everything downstream of the LLM response, since that's exactly the
logic that must never be trusted to the LLM itself.
"""

from datetime import UTC, datetime

from domain.models.firestore import GeoPointModel, Signal, Ward
from services.ai_pipeline import AIMissionBrief, AIPipelineService


def _make_ward(ward_id: str, population: int, infra: int) -> Ward:
    return Ward(
        id=ward_id,
        ward_number="14",
        name="Malad East",
        population=population,
        critical_infrastructure_count=infra,
        polygon_coordinates=[],
    )


def _make_signal(sig_id: str, ward_id: str) -> Signal:
    return Signal(
        id=sig_id,
        ward_id=ward_id,
        category="Water",
        severity=9,
        coords=GeoPointModel(latitude=19.18, longitude=72.85),
        description="No water",
        status="Open",
        timestamp=datetime.now(UTC),
    )


def _make_brief(evidence: list[str], alternative: str = "ward_17") -> AIMissionBrief:
    return AIMissionBrief(
        mission_id="brief_01",
        mission="Ward 14 Water Grid",
        priority="HIGH",
        budget=4_000_000,
        confidence=96,
        confidence_explanation="High confidence.",
        beneficiaries=24_830,
        estimated_completion="6 Months",
        department="Public Health Engineering",
        evidence=evidence,
        risks="Monsoon delays.",
        action_items=["a", "b", "c"],
        success_metrics=["m1", "m2"],
        timeline_decay_rate=0.15,
        alternative=alternative,
    )


def test_calculate_deterministic_impact_resolves_ward_via_evidence() -> None:
    # Avoid constructing a real GeminiClient (which reads GEMINI_API_KEY etc.)
    service = AIPipelineService.__new__(AIPipelineService)

    wards = [_make_ward("ward_14", population=62_400, infra=3), _make_ward("ward_17", 74_100, 5)]
    signals = [_make_signal("sig_8829", "ward_14"), _make_signal("sig_9102", "ward_14")]
    brief = _make_brief(evidence=["sig_8829", "sig_9102"])

    score = service.calculate_deterministic_impact(brief, wards, signals)

    assert isinstance(score, int)
    assert 0 <= score <= 100


def test_calculate_deterministic_impact_falls_back_to_alternative_ward() -> None:
    service = AIPipelineService.__new__(AIPipelineService)

    wards = [_make_ward("ward_17", population=74_100, infra=5)]
    signals: list[Signal] = []  # no evidence resolvable
    brief = _make_brief(evidence=["sig_unknown"], alternative="ward_17")

    score = service.calculate_deterministic_impact(brief, wards, signals)

    assert isinstance(score, int)
    assert 0 <= score <= 100


def test_calculate_deterministic_impact_uses_safe_defaults_when_ward_unresolvable() -> None:
    service = AIPipelineService.__new__(AIPipelineService)

    score = service.calculate_deterministic_impact(
        _make_brief(evidence=["sig_unknown"], alternative="ward_unknown"), [], []
    )

    assert isinstance(score, int)
    assert 0 <= score <= 100


def test_normalize_decay_rate_clamps_out_of_range_value() -> None:
    brief = _make_brief(evidence=["sig_8829"])
    brief.timeline_decay_rate = 0.99

    normalized = AIPipelineService.normalize_decay_rate(brief)

    assert normalized == 0.50
