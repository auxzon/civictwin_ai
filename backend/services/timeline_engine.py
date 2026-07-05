"""
Configurable visual models for optimization simulations (EDD V2, Document 01).

Two responsibilities, both deterministic (no LLM, no I/O):

1. Clamp/validate the `timeline_decay_rate` Gemini produces into the
   frozen [0.01, 0.50] bound before it reaches the client — the AI schema
   *requests* that range but never *enforces* it server-side.
2. Mirror the exact client-side opacity formula from
   `lib/features/map_dashboard/providers/map_state_notifier.dart`
   (EDD V2, Document 05) so backend logic and frontend simulation stay
   provably in sync, and so this formula is unit-testable without a
   running Flutter app.
"""

DECAY_RATE_MIN = 0.01
DECAY_RATE_MAX = 0.50

# Mirrors AppUIStateNotifier.activeTimelineStep semantics (Document 05).
TIMELINE_STEP_TODAY = 0
TIMELINE_STEP_SIX_MONTHS = 1
TIMELINE_STEP_ONE_YEAR = 2


def clamp_decay_rate(decay_rate: float) -> float:
    """Clamp a Gemini-produced decay rate into the frozen valid range."""
    return max(DECAY_RATE_MIN, min(decay_rate, DECAY_RATE_MAX))


def project_signal_opacity(step: int, decay_rate: float) -> float:
    """
    Compute the signal-marker opacity at a given timeline step.

    Exact parity with the Flutter client's `updateTimeline`:
        step 0 (Today)     -> 1.0
        step 1 (6 Months)  -> 1.0 - (decay_rate * 3), clamped to [0, 1]
        step 2 (1 Year)    -> 0.0
    """
    if step == TIMELINE_STEP_TODAY:
        opacity = 1.0
    elif step == TIMELINE_STEP_SIX_MONTHS:
        opacity = 1.0 - (decay_rate * 3)
    else:
        opacity = 0.0

    return max(0.0, min(opacity, 1.0))
