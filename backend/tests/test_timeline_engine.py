"""Unit tests for services/timeline_engine.py."""

import pytest

from services.timeline_engine import clamp_decay_rate, project_signal_opacity


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        (0.15, 0.15),
        (0.0, 0.01),
        (-1.0, 0.01),
        (0.99, 0.50),
        (0.50, 0.50),
        (0.01, 0.01),
    ],
)
def test_clamp_decay_rate(raw: float, expected: float) -> None:
    assert clamp_decay_rate(raw) == expected


def test_opacity_today_is_always_full() -> None:
    assert project_signal_opacity(step=0, decay_rate=0.5) == 1.0
    assert project_signal_opacity(step=0, decay_rate=0.01) == 1.0


def test_opacity_six_months_applies_triple_decay() -> None:
    # 1.0 - (0.15 * 3) = 0.55
    assert project_signal_opacity(step=1, decay_rate=0.15) == pytest.approx(0.55)


def test_opacity_six_months_clamps_at_zero_for_high_decay() -> None:
    # 1.0 - (0.50 * 3) = -0.5 -> clamped to 0.0
    assert project_signal_opacity(step=1, decay_rate=0.50) == 0.0


def test_opacity_one_year_is_always_zero() -> None:
    assert project_signal_opacity(step=2, decay_rate=0.01) == 0.0
    assert project_signal_opacity(step=2, decay_rate=0.50) == 0.0
