import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../map/providers/map_state_notifier.dart';
import '../mission/mission_provider.dart';

const List<String> _kTimelineStepLabels = ['Today', '6 Months', '1 Year'];

/// Functional timeline control for scrubbing between Today / 6 Months /
/// 1 Year projections (Document 01: "Timeline Simulation" state).
///
/// Deliberately minimal presentation — a `Slider` and a label — per the
/// current scope. Visual polish (glassmorphic styling per Document 05)
/// is intentionally left for a follow-up pass focused on design, not
/// bundled into this functional wiring.
class TimelineSlider extends ConsumerWidget {
  const TimelineSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(appUIStateProvider);
    final missionState = ref.watch(missionControllerProvider);

    // The shared timeline decay rate is driven by the first (primary)
    // recommended brief. The frozen spec (Document 05) defines a single
    // decayRate parameter for the whole timeline simulation but does not
    // specify how to reconcile multiple briefs with different rates —
    // using the primary brief's rate is a reasonable default; a
    // per-brief timeline is a natural future enhancement, not implemented
    // here to avoid inventing UI beyond what's specified.
    final briefs = missionState.response?.briefs ?? const [];
    final activeDecayRate = briefs.isNotEmpty
        ? briefs.first.timelineDecayRate
        : 0.15;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_kTimelineStepLabels[uiState.activeTimelineStep]),
        Slider(
          value: uiState.activeTimelineStep.toDouble(),
          min: 0,
          max: 2,
          divisions: 2,
          onChanged: briefs.isEmpty
              ? null
              : (value) {
                  ref
                      .read(appUIStateProvider.notifier)
                      .updateTimeline(value.round(), activeDecayRate);
                },
        ),
      ],
    );
  }
}
