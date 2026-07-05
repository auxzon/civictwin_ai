"""Unit tests for services/impact_engine.py — pure function, no mocking needed."""

from services.impact_engine import calculate_deterministic_impact


def test_full_marks_when_all_factors_maximized() -> None:
    """Beneficiaries == population, high evidence count, cheap budget, low infra count."""
    score = calculate_deterministic_impact(
        brief_budget=100_000,
        brief_beneficiaries=10_000,
        brief_evidence_len=5,
        target_ward_population=10_000,
        target_ward_infra_count=1,
    )
    assert score == 100


def test_zero_beneficiaries_still_scores_fixed_severity_component() -> None:
    """Severity (25%) is a fixed baseline regardless of other factors."""
    score = calculate_deterministic_impact(
        brief_budget=10_000_000,
        brief_beneficiaries=0,
        brief_evidence_len=0,
        target_ward_population=100_000,
        target_ward_infra_count=100,
    )
    # pop_impact=0, severity=25, efficiency=0, infra=0.15, signals=0
    assert score == 25


def test_score_is_bounded_between_0_and_100() -> None:
    score = calculate_deterministic_impact(
        brief_budget=1,
        brief_beneficiaries=999_999_999,
        brief_evidence_len=999,
        target_ward_population=1,
        target_ward_infra_count=1,
    )
    assert 0 <= score <= 100


def test_hand_calculated_example_matches_exactly() -> None:
    """
    budget=4_000_000, beneficiaries=24_830, evidence=3,
    population=62_400, infra=3 (matches the mock Ward 14 / sig_8829 scenario).
    """
    score = calculate_deterministic_impact(
        brief_budget=4_000_000,
        brief_beneficiaries=24_830,
        brief_evidence_len=3,
        target_ward_population=62_400,
        target_ward_infra_count=3,
    )

    pop_impact = min(24_830 / 62_400, 1.0) * 30
    severity = 25.0
    efficiency = min((3 * 100_000) / 4_000_000, 1.0) * 20
    infra = min(1.0 / 3, 1.0) * 15
    signals = min(3 / 5, 1.0) * 10
    expected = int(max(min(pop_impact + severity + efficiency + infra + signals, 100), 0))

    assert score == expected


def test_division_by_zero_guarded_for_population_and_infra() -> None:
    """max(x, 1) guards must prevent ZeroDivisionError."""
    score = calculate_deterministic_impact(
        brief_budget=0,
        brief_beneficiaries=100,
        brief_evidence_len=1,
        target_ward_population=0,
        target_ward_infra_count=0,
    )
    assert isinstance(score, int)
    assert 0 <= score <= 100
