"""
Pure deterministic mathematical scoring engine (EDD V2, Document 04).

This module contains zero LLM calls and zero I/O. It is a pure function
over plain numeric/string inputs, by design — Gemini is strictly
prohibited from performing this calculation itself (see the
"Deterministic Reasoning" architecture principle in DECISIONS.md). Every
brief's `impact_score` in the final API response is always the output of
this function, regardless of whatever score value Gemini may have
produced internally.
"""


def calculate_deterministic_impact(
    brief_budget: int,
    brief_beneficiaries: int,
    brief_evidence_len: int,
    target_ward_population: int,
    target_ward_infra_count: int,
) -> int:
    """
    Compute a 0-100 impact score for a single mission brief.

    Impact Score Formula Matrix =
        (Population Impact   * 30%) +
        (Severity Baseline   * 25%) +
        (Budget Efficiency   * 20%) +
        (Infrastructure Mult * 15%) +
        (Signals Weight      * 10%)

    All five weights and the formula shape are fixed by EDD V2 Document 04
    and must not be altered without an approved architecture change.
    """
    # 1. Population Impact Calculation Factor (30% Weight Allocation)
    pop_impact = min(brief_beneficiaries / max(target_ward_population, 1), 1.0) * 30

    # 2. Structural Severity Parameter Factor (25% Weight Allocation)
    # Fixed baseline per the frozen formula — not derived from per-signal
    # severity values, which are instead reflected via evidence density
    # in the Signals Weight Factor below.
    severity_val = 25.0

    # 3. Budget Efficiency Matrix Logic (20% Weight Allocation)
    budget_ratio = (brief_evidence_len * 100_000) / max(brief_budget, 1)
    efficiency = min(budget_ratio, 1.0) * 20

    # 4. Critical Infrastructure Optimization Density Loop (15% Weight Allocation)
    infra_weight = min(1.0 / max(target_ward_infra_count, 1), 1.0) * 15

    # 5. Citizen Signals Density Scaling Loop (10% Weight Allocation)
    signals_weight = min(brief_evidence_len / 5, 1.0) * 10

    raw_score = pop_impact + severity_val + efficiency + infra_weight + signals_weight

    return int(max(min(raw_score, 100), 0))
