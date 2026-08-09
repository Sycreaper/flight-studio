/// Abstract interface for a BYOK LLM provider. Concrete implementations
/// (Phase 9) translate between this interface and the provider-specific API
/// (OpenAI Chat Completions, Anthropic Messages, Ollama generate).
///
/// The AI copilot UI calls [chat] with a conversation history and the tool
/// registry; the provider handles the wire protocol and returns either a text
/// response or a tool-call request that the UI surfaces to the user.
sealed class LlmProvider {
  const LlmProvider(this.apiKey, {this.endpoint, this.model});

  final String apiKey;
  final String? endpoint;
  final String? model;

  /// Sends a chat completion request. Returns the provider's text response or
  /// a tool-call directive.
  Future<LlmResponse> chat({
    required List<LlmMessage> messages,
    List<Map<String, dynamic>>? toolDefinitions,
  });
}

/// A message in the conversation history.
class LlmMessage {
  const LlmMessage({required this.role, required this.content});

  /// `'system'`, `'user'`, `'assistant'`, or `'tool'`.
  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// The response from the LLM — either a text reply or a tool-call request.
class LlmResponse {
  const LlmResponse({this.text, this.toolCall});

  /// Non-null when the model produced a text response.
  final String? text;

  /// Non-null when the model wants to call a tool. The UI must execute the
  /// tool (via [McpToolRegistry]) and send the result back.
  final ToolCall? toolCall;
}

/// A tool-call directive from the model.
class ToolCall {
  const ToolCall({required this.toolName, required this.arguments});

  final String toolName;
  final Map<String, dynamic> arguments;
}

// ── Concrete provider stubs (Phase 9 implementation) ────────────────────────

class OpenAiCompatibleProvider extends LlmProvider {
  const OpenAiCompatibleProvider(super.apiKey, {super.endpoint, super.model});

  @override
  Future<LlmResponse> chat({
    required List<LlmMessage> messages,
    List<Map<String, dynamic>>? toolDefinitions,
  }) {
    throw UnimplementedError('Wired in Phase 9.');
  }
}

class AnthropicProvider extends LlmProvider {
  const AnthropicProvider(super.apiKey, {super.endpoint, super.model});

  @override
  Future<LlmResponse> chat({
    required List<LlmMessage> messages,
    List<Map<String, dynamic>>? toolDefinitions,
  }) {
    throw UnimplementedError('Wired in Phase 9.');
  }
}

class OllamaProvider extends LlmProvider {
  const OllamaProvider(super.apiKey, {super.endpoint, super.model});

  @override
  Future<LlmResponse> chat({
    required List<LlmMessage> messages,
    List<Map<String, dynamic>>? toolDefinitions,
  }) {
    throw UnimplementedError('Wired in Phase 9.');
  }
}
