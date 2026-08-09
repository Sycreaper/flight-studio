import 'package:flutter/material.dart';

/// Localised, user-selectable interface language.
///
/// [system] defers to the OS locale, falling back through Material's standard
/// locale resolution. [en] and [zh] force a specific language regardless of
/// the platform locale.
enum AppLocaleCode {
  system,
  en,
  zh;

  /// Resolves to the [Locale] actually handed to [MaterialApp], or `null` to
  /// let Flutter perform platform-default resolution.
  Locale? toLocale() {
    switch (this) {
      case AppLocaleCode.en:
        return const Locale('en');
      case AppLocaleCode.zh:
        return const Locale('zh');
      case AppLocaleCode.system:
        return null;
    }
  }

  /// Serialises to a stable string for persistence.
  String get persistedName {
    switch (this) {
      case AppLocaleCode.system:
        return 'system';
      case AppLocaleCode.en:
        return 'en';
      case AppLocaleCode.zh:
        return 'zh';
    }
  }

  /// Deserialises from [persistedName]; unknown values fall back to [system]
  /// rather than throwing, so old settings never break the boot path.
  static AppLocaleCode fromPersistedName(String? name) {
    switch (name) {
      case 'en':
        return AppLocaleCode.en;
      case 'zh':
        return AppLocaleCode.zh;
      case 'system':
      default:
        return AppLocaleCode.system;
    }
  }
}

/// Map appearance mode — system-following, forced light or forced dark.
/// When dark, the tile provider factory swaps to dark-variant tile URLs.
enum MapTheme {
  system,
  light,
  dark;

  String get persistedName => name;

  static MapTheme fromPersistedName(String? name) {
    switch (name) {
      case 'light':
        return MapTheme.light;
      case 'dark':
        return MapTheme.dark;
      case 'system':
      default:
        return MapTheme.system;
    }
  }
}

/// Which map tile provider flutter_map should fetch raster tiles from.
///
/// [osm] works out of the box (no key). [mapboxStreets] and [mapboxSatellite]
/// require a Mapbox access token stored in [AppSettings.mapboxAccessToken].
/// [custom] uses a user-supplied URL template for self-hosted tile servers.
enum MapTileProvider {
  osm,
  mapboxStreets,
  mapboxSatellite,
  custom;

  String get persistedName => name;

  static MapTileProvider fromPersistedName(String? name) {
    switch (name) {
      case 'mapboxStreets':
        return MapTileProvider.mapboxStreets;
      case 'mapboxSatellite':
        return MapTileProvider.mapboxSatellite;
      case 'custom':
        return MapTileProvider.custom;
      case 'osm':
      default:
        return MapTileProvider.osm;
    }
  }
}

/// Which BYOK LLM provider the AI Copilot should talk to.
///
/// The [openAi] bucket is intentionally broad: it covers OpenAI itself plus any
/// endpoint that mirrors the OpenAI Chat Completions API (Groq, Together,
/// OpenRouter, LM Studio, vLLM, …). The [anthropic] and [ollama] providers
/// speak their own request/response shapes.
enum AiProvider {
  openAi,
  anthropic,
  ollama;

  String get persistedName => name;

  static AiProvider fromPersistedName(String? name) {
    switch (name) {
      case 'anthropic':
        return AiProvider.anthropic;
      case 'ollama':
        return AiProvider.ollama;
      case 'openAi':
      default:
        return AiProvider.openAi;
    }
  }
}
