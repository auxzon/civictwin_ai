import '../../mission/models/mission_models.dart';

/// Mirrors `domain.schemas.responses.MissionHistoryItem`. This endpoint
/// is an additive gap-fill (see DECISIONS.md / CHANGELOG.md) — not part
/// of the literal EDD V2 Document 03 contract.
class MissionHistoryItem {
  const MissionHistoryItem({
    required this.id,
    required this.command,
    required this.selectedPlan,
    required this.isImplemented,
    required this.createdAt,
  });

  factory MissionHistoryItem.fromJson(Map<String, dynamic> json) {
    return MissionHistoryItem(
      id: json['id'] as String,
      command: json['command'] as String,
      selectedPlan: MissionResponse.fromJson(
        json['selected_plan_payload'] as Map<String, dynamic>,
      ),
      isImplemented: json['is_implemented'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String command;
  final MissionResponse selectedPlan;
  final bool isImplemented;
  final DateTime createdAt;
}
