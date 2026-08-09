import 'dart:convert';
import 'dart:math' as math;

/// Every kind of API credential Flight Studio can store. Each type maps to a
/// downstream consumer (tile provider, LLM client, flight-info service, …).
enum ApiKeyType {
  osmToken,
  mapboxToken,
  aiCopilot,
  flightAware,
  customTileUrl;

  /// Stable string used for JSON serialisation and persistence.
  String get persistedName => name;

  /// Human-readable label key — resolved at render time via l10n.
  String get l10nKeyPrefix => 'apiKeyType_$name';

  static ApiKeyType fromPersistedName(String? name) {
    switch (name) {
      case 'osmToken':
        return ApiKeyType.osmToken;
      case 'aiCopilot':
        return ApiKeyType.aiCopilot;
      case 'flightAware':
        return ApiKeyType.flightAware;
      case 'customTileUrl':
        return ApiKeyType.customTileUrl;
      case 'mapboxToken':
      default:
        return ApiKeyType.mapboxToken;
    }
  }
}

/// One stored API credential. The [value] is the secret itself — it is
/// **never displayed in full** after being saved. Use [masked] in the UI.
///
/// Plain Dart class with manual JSON serDe (no codegen) — matches the rest of
/// the settings layer.
class ApiKeyEntry {
  ApiKeyEntry({
    required this.id,
    required this.type,
    required this.value,
    this.label,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final ApiKeyType type;
  final String value;
  final String? label;
  final DateTime createdAt;

  /// Returns a masked representation: first 4 + `…` + last 4 characters.
  /// For short strings (≤ 8 chars), shows first 2 + last 2 instead.
  String get masked {
    if (value.length <= 4) return value;
    if (value.length <= 8) {
      return '${value.substring(0, 2)}…${value.substring(value.length - 2)}';
    }
    return '${value.substring(0, 4)}…${value.substring(value.length - 4)}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.persistedName,
    'value': value,
    'label': label,
    'createdAt': createdAt.toIso8601String(),
  };

  static ApiKeyEntry fromJson(Map<String, dynamic> json) => ApiKeyEntry(
    id: json['id'] as String,
    type: ApiKeyType.fromPersistedName(json['type'] as String?),
    value: json['value'] as String,
    label: json['label'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
  );

  /// Serialise a list to a JSON string for SharedPreferences storage.
  static String encodeList(List<ApiKeyEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  /// Deserialise a JSON string back to a list.
  static List<ApiKeyEntry> decodeList(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => ApiKeyEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return const [];
    }
  }

  /// Generates a random 8-char id for new entries.
  static String generateId() {
    final rng = math.Random.secure();
    return List.generate(8, (_) => rng.nextInt(36).toRadixString(36)).join();
  }
}
