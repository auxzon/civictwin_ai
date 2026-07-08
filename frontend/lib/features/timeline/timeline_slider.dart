import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/design_system.dart';
import '../map/providers/map_state_notifier.dart';
import '../mission/mission_provider.dart';

const List<String> _kTimelineStepLabels = ['Today', '6 Months', '1 Year'];

/// Premium timeline scrubber for stepping through temporal projections.
/// Matches the glassmorphic enterprise dashboard visual language.
class TimelineSlider extends ConsumerWidget {
  const TimelineSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(appUIStateProvider);
    final missionState = ref.watch(missionControllerProvider);

    final briefs = missionState.response?.briefs ?? const [];
    final activeDecayRate = briefs.isNotEmpty
        ? briefs.first.timelineDecayRate
        : 0.15;

    final isDisabled = briefs.isEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _kTimelineStepLabels.length; i++) ...[
          if (i > 0) AppDesignSystem.width4,
          MouseRegion(
            cursor: isDisabled
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      ref
                          .read(appUIStateProvider.notifier)
                          .updateTimeline(i, activeDecayRate);
                    },
              child: AnimatedContainer(
                duration: AppDesignSystem.durationFast,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.space8,
                  vertical: AppDesignSystem.space4,
                ),
                decoration: BoxDecoration(
                  color: uiState.activeTimelineStep == i && !isDisabled
                      ? AppDesignSystem.brandNeonCyan.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: AppDesignSystem.borderRadii4,
                  border: uiState.activeTimelineStep == i && !isDisabled
                      ? Border.all(
                          color: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Text(
                  _kTimelineStepLabels[i],
                  style: AppDesignSystem.caption.copyWith(
                    color: uiState.activeTimelineStep == i && !isDisabled
                        ? AppDesignSystem.brandNeonCyan
                        : isDisabled
                            ? AppDesignSystem.textMuted.withValues(alpha: 0.5)
                            : AppDesignSystem.textMuted,
                    fontWeight: uiState.activeTimelineStep == i
                        ? FontWeight.w600
                        : FontWeight.w400,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
