import '../../core/network/api_client.dart';
import 'models/mission_history_item.dart';

/// Calls the additive `GET /mission/history` endpoint (see
/// DECISIONS.md — not part of the original frozen API contract, added
/// to support Document 01's "History Mode" state).
class HistoryRepository {
  HistoryRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<MissionHistoryItem>> fetchHistory({
    required String constituencyId,
  }) async {
    final json = await _apiClient.get(
      '/mission/history',
      queryParams: {'constituency_id': constituencyId},
    );
    final items = json['items'] as List;
    return items
        .map((i) => MissionHistoryItem.fromJson(i as Map<String, dynamic>))
        .toList();
  }
}
