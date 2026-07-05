import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/auth_provider.dart';
import 'history_repository.dart';
import 'models/mission_history_item.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(apiClientProvider));
});

/// Fetches mission history for a given constituency ID. Used by the
/// "History Mode" drawer (Document 01).
final missionHistoryProvider = FutureProvider.family<
  List<MissionHistoryItem>,
  String
>((ref, constituencyId) {
  return ref
      .watch(historyRepositoryProvider)
      .fetchHistory(constituencyId: constituencyId);
});
