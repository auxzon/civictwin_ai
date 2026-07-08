import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/network/api_exception.dart';
import '../authentication/auth_provider.dart';
import '../map/providers/map_state_notifier.dart';
import 'mission_repository.dart';
import 'models/mission_models.dart';

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return MissionRepository(ref.watch(apiClientProvider));
});

/// Holds the most recent successful mission response (or null before the
/// first generation / after a failure), plus any user-facing error
/// message for the "Error Toast" transition in Document 01's state
/// machine.
class MissionControllerState {
  const MissionControllerState({this.response, this.errorMessage});

  final MissionResponse? response;
  final String? errorMessage;

  MissionControllerState copyWith({
    MissionResponse? response,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MissionControllerState(
      response: response ?? this.response,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Drives the Idle -> Thinking -> Animating -> MissionLoaded state
/// machine (Document 01) in response to a submitted voice/text command.
class MissionController extends StateNotifier<MissionControllerState> {
  MissionController(this._ref) : super(const MissionControllerState());

  final Ref _ref;

  Future<void> submitCommand({
    required String constituencyId,
    required String command,
    required LatLngBounds currentMapBounds,
  }) async {
    final uiNotifier = _ref.read(appUIStateProvider.notifier);
    uiNotifier.updateState(OperationalState.thinking);
    state = state.copyWith(clearError: true);

    try {
      final repository = _ref.read(missionRepositoryProvider);
      final response = await repository.generateMission(
        MissionGenerationRequest(
          constituencyId: constituencyId,
          command: command,
          mapBounds: MapBoundsDto(
            ne: LatLngDto(
              lat: currentMapBounds.northeast.latitude,
              lng: currentMapBounds.northeast.longitude,
            ),
            sw: LatLngDto(
              lat: currentMapBounds.southwest.latitude,
              lng: currentMapBounds.southwest.longitude,
            ),
          ),
        ),
      );

      state = state.copyWith(response: response);
      uiNotifier.updateState(OperationalState.animating);
      // The map screen listens for `animating` and, once camera/overlay
      // animations complete, transitions to `planLoaded` itself (Document
      // 01: Animating -> MissionLoaded is a UI-driven transition, not an
      // immediate state change).
    } on ApiException catch (exc) {
      state = state.copyWith(errorMessage: exc.message);
      uiNotifier.updateState(OperationalState.idle);
    } catch (exc) {
      state = state.copyWith(
        errorMessage: 'Something went wrong generating this mission.',
      );
      uiNotifier.updateState(OperationalState.idle);
    }
  }

  void setMissionResponse(MissionResponse response) {
    state = state.copyWith(response: response);
    _ref.read(appUIStateProvider.notifier).updateState(OperationalState.planLoaded);
  }
}

final missionControllerProvider =
    StateNotifierProvider<MissionController, MissionControllerState>((ref) {
      return MissionController(ref);
    });
