import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Unified state machine states (EDD V2, Document 01: "Complete Unified
/// State Machine"). This enum and the notifier below are specified
/// verbatim in Document 05 and must not be altered without an approved
/// architecture change.
enum OperationalState { idle, listening, thinking, animating, planLoaded }

class AppUIState {
  AppUIState({
    required this.state,
    required this.signalMarkers,
    required this.wardPolygons,
    required this.cameraTarget,
    required this.activeTimelineStep,
  });

  final OperationalState state;
  final Set<Marker> signalMarkers;
  final Set<Polygon> wardPolygons;
  final LatLng cameraTarget;
  final int activeTimelineStep; // 0 = Today, 1 = 6 Months, 2 = 1 Year

  AppUIState copyWith({
    OperationalState? state,
    Set<Marker>? signalMarkers,
    Set<Polygon>? wardPolygons,
    LatLng? cameraTarget,
    int? activeTimelineStep,
  }) {
    return AppUIState(
      state: state ?? this.state,
      signalMarkers: signalMarkers ?? this.signalMarkers,
      wardPolygons: wardPolygons ?? this.wardPolygons,
      cameraTarget: cameraTarget ?? this.cameraTarget,
      activeTimelineStep: activeTimelineStep ?? this.activeTimelineStep,
    );
  }
}

class AppUIStateNotifier extends StateNotifier<AppUIState> {
  AppUIStateNotifier()
    : super(
        AppUIState(
          state: OperationalState.idle,
          signalMarkers: {},
          wardPolygons: {},
          cameraTarget: const LatLng(19.1154, 72.8624),
          activeTimelineStep: 0,
        ),
      );

  void updateState(OperationalState newState) {
    state = state.copyWith(state: newState);
  }

  void loadSignals(List<Marker> markers) {
    state = state.copyWith(signalMarkers: markers.toSet());
  }

  void highlightWard(Polygon wardPolygon, LatLng center) {
    state = state.copyWith(
      state: OperationalState.animating,
      wardPolygons: {wardPolygon},
      cameraTarget: center,
    );
  }

  void updateTimeline(int step, double decayRate) {
    // A configurable visualization model used to demonstrate projected
    // improvement simulation. Mirrored exactly on the backend in
    // services/timeline_engine.py (project_signal_opacity) for parity
    // and unit-test coverage of this formula.
    final double opacity = step == 0
        ? 1.0
        : (step == 1 ? (1.0 - (decayRate * 3)) : 0.0);
    final updatedMarkers = state.signalMarkers.map((marker) {
      return marker.copyWith(alphaParam: opacity.clamp(0.0, 1.0));
    }).toSet();

    state = state.copyWith(
      activeTimelineStep: step,
      signalMarkers: updatedMarkers,
    );
  }
}

final appUIStateProvider =
    StateNotifierProvider<AppUIStateNotifier, AppUIState>((ref) {
      return AppUIStateNotifier();
    });
