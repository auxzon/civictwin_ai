/// Mirrors `domain.schemas.responses.MissionBrief` on the backend exactly.
/// Field names and types match the frozen API contract (Document 03).
class MissionBrief {
  const MissionBrief({
    required this.missionId,
    required this.mission,
    required this.priority,
    required this.budget,
    required this.impactScore,
    required this.confidence,
    required this.confidenceExplanation,
    required this.beneficiaries,
    required this.estimatedCompletion,
    required this.department,
    required this.evidence,
    required this.risks,
    required this.actionItems,
    required this.successMetrics,
    required this.timelineDecayRate,
    required this.alternative,
  });

  factory MissionBrief.fromJson(Map<String, dynamic> json) {
    return MissionBrief(
      missionId: json['mission_id'] as String,
      mission: json['mission'] as String,
      priority: json['priority'] as String,
      budget: json['budget'] as int,
      impactScore: json['impact_score'] as int,
      confidence: json['confidence'] as int,
      confidenceExplanation: json['confidence_explanation'] as String,
      beneficiaries: json['beneficiaries'] as int,
      estimatedCompletion: json['estimated_completion'] as String,
      department: json['department'] as String,
      evidence: List<String>.from(json['evidence'] as List),
      risks: json['risks'] as String,
      actionItems: List<String>.from(json['action_items'] as List),
      successMetrics: List<String>.from(json['success_metrics'] as List),
      timelineDecayRate: (json['timeline_decay_rate'] as num).toDouble(),
      alternative: json['alternative'] as String,
    );
  }

  final String missionId;
  final String mission;
  final String priority; // HIGH | MEDIUM | LOW
  final int budget;
  final int impactScore;
  final int confidence;
  final String confidenceExplanation;
  final int beneficiaries;
  final String estimatedCompletion;
  final String department;
  final List<String> evidence;
  final String risks;
  final List<String> actionItems;
  final List<String> successMetrics;
  final double timelineDecayRate;
  final String alternative;
}

/// Mirrors `domain.schemas.responses.MissionResponse` on the backend exactly.
class MissionResponse {
  const MissionResponse({
    required this.missionId,
    required this.commandSummary,
    required this.briefs,
  });

  factory MissionResponse.fromJson(Map<String, dynamic> json) {
    return MissionResponse(
      missionId: json['mission_id'] as String,
      commandSummary: json['command_summary'] as String,
      briefs: (json['briefs'] as List)
          .map((b) => MissionBrief.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  final String missionId;
  final String commandSummary;
  final List<MissionBrief> briefs;
}

/// Mirrors the request body for POST /api/v1/mission/generate exactly
/// (Document 03).
class MissionGenerationRequest {
  const MissionGenerationRequest({
    required this.constituencyId,
    required this.command,
    required this.mapBounds,
  });

  final String constituencyId;
  final String command;
  final MapBoundsDto mapBounds;

  Map<String, dynamic> toJson() => {
    'constituency_id': constituencyId,
    'command': command,
    'map_bounds': mapBounds.toJson(),
  };
}

class MapBoundsDto {
  const MapBoundsDto({required this.ne, required this.sw});

  final LatLngDto ne;
  final LatLngDto sw;

  Map<String, dynamic> toJson() => {'ne': ne.toJson(), 'sw': sw.toJson()};
}

class LatLngDto {
  const LatLngDto({required this.lat, required this.lng});

  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}
