import '../../core/network/api_client.dart';
import 'models/mission_models.dart';

/// Calls `POST /mission/generate` on the backend. This is the sole
/// integration point for the AI mission pipeline — per Decision 5, the
/// client never talks to Firestore or Gemini directly.
class MissionRepository {
  MissionRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<MissionResponse> generateMission(
    MissionGenerationRequest request,
  ) async {
    final json = await _apiClient.post(
      '/mission/generate',
      body: request.toJson(),
    );
    return MissionResponse.fromJson(json);
  }
}
