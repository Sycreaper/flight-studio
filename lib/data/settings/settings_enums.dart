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
