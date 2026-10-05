import 'dart:convert';
import 'dart:math' as math;

/// Every kind of API credential Flight Studio can store. Each type maps to a
/// downstream consumer (tile provider, LLM provider, flight-info service, …).
enum ApiKeyType {
  osmToken,
  mapboxToken,
  openAiCompatible,
  flightAware,
  customTileUrl;

  /// Stable string used for JSON serialisation and persistence.
  String get persistedName => name;

  /// Human-readable label key — resolved at render time via l10n.
  String get l10nKeyPrefix => 'apiKeyType_$name';

  /// Whether this type is an OpenAI-compatible LLM provider (shows the
  /// provider / base-URL / test-connection template in the add dialog).
  bool get isModelProvider => this == ApiKeyType.openAiCompatible;

  /// Legacy 'aiCopilot' entries migrate to openAiCompatible.
  static ApiKeyType fromPersistedName(String? name) {
    switch (name) {
      case 'osmToken':
        return ApiKeyType.osmToken;
      case 'openAiCompatible':
      case 'aiCopilot':
        return ApiKeyType.openAiCompatible;
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

/// Named OpenAI-compatible providers offered inside the add-key dialog when
/// [ApiKeyType.openAiCompatible] is selected. 'custom' lets the user fill
/// their own base URL. Models are DISCOVERED from each endpoint's
/// `/models` listing when the key is created — no model typing anywhere.
enum OpenAiProvider {
  glm,
  qwen,
  deepseek,
  minimax,
  moonshot,
  siliconflow,
  openrouter,
  custom,
}

extension OpenAiProviderX on OpenAiProvider {
  String get persistedName => name;

  /// Official OpenAI-compatible base URL (chat completions at `{base}/chat/
  /// completions`, model discovery at `{base}/models`).
  String get defaultBaseUrl => switch (this) {
    OpenAiProvider.glm => 'https://open.bigmodel.cn/api/paas/v4',
    OpenAiProvider.qwen => 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    OpenAiProvider.deepseek => 'https://api.deepseek.com/v1',
    OpenAiProvider.minimax => 'https://api.minimax.chat/v1',
    OpenAiProvider.moonshot => 'https://api.moonshot.cn/v1',
    OpenAiProvider.siliconflow => 'https://api.siliconflow.cn/v1',
    OpenAiProvider.openrouter => 'https://openrouter.ai/api/v1',
    OpenAiProvider.custom => '',
  };

  static OpenAiProvider fromPersistedName(String? name) {
    return OpenAiProvider.values
            .where((p) => p.persistedName == name)
            .firstOrNull ??
        OpenAiProvider.custom;
  }
}

/// One stored API credential. The [value] is the secret itself — it is
/// **never displayed in full** after being saved. Use [masked] in the UI.
///
/// For [ApiKeyType.openAiCompatible] entries the optional [provider],
/// [baseUrl] and [models] fields carry the LLM provider details. [models]
/// is discovered automatically (GET `{baseUrl}/models`) when the key is
/// created — the user never types model names.
class ApiKeyEntry {
  ApiKeyEntry({
    required this.id,
    required this.type,
    required this.value,
    this.label,
    this.provider,
    this.baseUrl,
    List<String>? models,
    DateTime? createdAt,
  }) : models = models ?? const [],
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final ApiKeyType type;
  final String value;
  final String? label;

  /// OpenAI-compatible only: which named provider (or 'custom').
  final String? provider;

  /// OpenAI-compatible only: API base URL (the provider's real path, e.g.
  /// `.../api/paas/v4` — the gateway proxies around path conventions).
  final String? baseUrl;

  /// OpenAI-compatible only: model ids discovered from the endpoint's
  /// `/models` listing at creation time.
  final List<String> models;
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
    if (provider != null) 'provider': provider,
    if (baseUrl != null) 'baseUrl': baseUrl,
    if (models.isNotEmpty) 'models': models,
    'createdAt': createdAt.toIso8601String(),
  };

  static ApiKeyEntry fromJson(Map<String, dynamic> json) => ApiKeyEntry(
    id: json['id'] as String,
    type: ApiKeyType.fromPersistedName(json['type'] as String?),
    value: json['value'] as String,
    label: json['label'] as String?,
    provider: json['provider'] as String?,
    baseUrl: json['baseUrl'] as String?,
    models: _decodeModels(json['models'] ?? json['model']),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
  );

  /// Accepts the current list form or the legacy single-model string.
  static List<String> _decodeModels(Object? raw) {
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return [raw.trim()]; // legacy single-model entries
    }
    return const [];
  }

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
