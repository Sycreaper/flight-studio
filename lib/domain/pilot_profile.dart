/// A Flight Studio user's profile. Designed with stable id + timestamps so an
/// optional cloud sync layer can be added later without rework.
///
/// Plain Dart class with manual JSON serDe — no codegen dependency.
class PilotProfile {
  PilotProfile({
    required this.id,
    required this.displayName,
    this.homeBaseIcao,
    this.totalHours = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String displayName;
  final String? homeBaseIcao;
  final double totalHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  PilotProfile copyWith({
    String? displayName,
    String? homeBaseIcao,
    double? totalHours,
    DateTime? updatedAt,
  }) => PilotProfile(
    id: id,
    displayName: displayName ?? this.displayName,
    homeBaseIcao: homeBaseIcao ?? this.homeBaseIcao,
    totalHours: totalHours ?? this.totalHours,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'homeBaseIcao': homeBaseIcao,
    'totalHours': totalHours,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PilotProfile.fromJson(Map<String, dynamic> json) => PilotProfile(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    homeBaseIcao: json['homeBaseIcao'] as String?,
    totalHours: (json['totalHours'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  @override
  String toString() =>
      'PilotProfile($displayName, ${totalHours.toStringAsFixed(1)}h)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PilotProfile && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
