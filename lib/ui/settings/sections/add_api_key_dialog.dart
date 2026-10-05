import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../data/settings/api_key_entry.dart';
import '../../../data/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/floating_window.dart';

/// Shows a [FloatingWindow]-style dialog for adding a new API key.
void showAddApiKeyDialog(BuildContext context, SettingsController controller) {
  final l10n = AppLocalizations.of(context)!;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => FloatingWindow(
      title: l10n.apiKeyAddTitle,
      titleIcon: Icons.vpn_key_rounded,
      width: 460,
      height: 500,
      onClose: () => entry.remove(),
      child: _AddApiKeyBody(
        controller: controller,
        onClose: () => entry.remove(),
      ),
    ),
  );
  Overlay.of(context).insert(entry);
}

class _AddApiKeyBody extends StatefulWidget {
  const _AddApiKeyBody({required this.controller, required this.onClose});

  final SettingsController controller;
  final VoidCallback onClose;

  @override
  State<_AddApiKeyBody> createState() => _AddApiKeyBodyState();
}

class _AddApiKeyBodyState extends State<_AddApiKeyBody> {
  ApiKeyType _type = ApiKeyType.mapboxToken;
  final _valueCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  bool _showError = false;

  // ── OpenAI-compatible extras ────────────────────────────────────────────
  OpenAiProvider _provider = OpenAiProvider.glm;
  final _baseUrlCtrl = TextEditingController();
  bool _testing = false;
  String? _testResult; // 'ok' | 'fail:...' | null (not tested)
  Dio? _dio;

  bool get _isOpenAi => _type == ApiKeyType.openAiCompatible;

  @override
  void dispose() {
    _valueCtrl.dispose();
    _labelCtrl.dispose();
    _baseUrlCtrl.dispose();
    _dio?.close();
    super.dispose();
  }

  void _onTypeChanged(ApiKeyType t) {
    setState(() {
      _type = t;
      _showError = false;
      _testResult = null;
      if (t == ApiKeyType.openAiCompatible) {
        _baseUrlCtrl.text = _provider.defaultBaseUrl;
      }
    });
  }

  void _onProviderChanged(OpenAiProvider p) {
    setState(() {
      _provider = p;
      _testResult = null;
      _baseUrlCtrl.text = p.defaultBaseUrl;
    });
  }

  /// Connectivity + discovery probe: GET `{baseUrl}/models` with the key.
  /// Returns the discovered model ids (empty when the endpoint lists none).
  Future<List<String>> _fetchModels() async {
    final base = _baseUrlCtrl.text.trim().replaceAll(RegExp(r'/+$'), '');
    final key = _valueCtrl.text.trim();

    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      _dio ??= Dio()
        ..options.connectTimeout = const Duration(seconds: 8)
        ..options.receiveTimeout = const Duration(seconds: 10);
      final res = await _dio!.get<Map<String, dynamic>>(
        '$base/models',
        options: Options(headers: {
          if (key.isNotEmpty) 'Authorization': 'Bearer $key',
        }),
      );
      final data = res.data?['data'];
      final models = data is List
          ? data
          .map((e) => e is Map ? e['id'] as String? : null)
          .whereType<String>()
          .where((id) =>
      id
          .trim()
          .isNotEmpty)
          .toList()
          : const <String>[];
      if (!mounted) return models;
      setState(() {
        _testing = false;
        _testResult = 'ok';
      });
      return models;
    } on Exception catch (e) {
      final status = e is DioException
          ? 'HTTP ${e.response?.statusCode}'
          : e.toString();
      if (!mounted) return const [];
      setState(() {
        _testing = false;
        _testResult = 'fail:$status';
      });
      return const [];
    }
  }

  /// Quick check button — same probe, result shown inline.
  Future<void> _testConnection() => _fetchModels();

  Future<void> _save() async {
    final value = _valueCtrl.text.trim();
    if (value.isEmpty) {
      setState(() => _showError = true);
      return;
    }

    // OpenAI-compatible keys are only saved after a MANDATORY connection
    // check that also discovers the model list (shown later in the chat
    // model picker, not here).
    List<String> models = const [];
    if (_isOpenAi) {
      models = await _fetchModels();
      if (!mounted) return;
      if (_testResult != 'ok') {
        setState(() => _showError = false);
        return; // failure already rendered next to the test button
      }
    }

    final label = _labelCtrl.text.trim();
    final baseUrl = _baseUrlCtrl.text.trim();

    await widget.controller.addApiKey(
      _type,
      value,
      label: label.isEmpty ? null : label,
      provider: _isOpenAi ? _provider.persistedName : null,
      baseUrl: _isOpenAi && baseUrl.isNotEmpty ? baseUrl : null,
      models: _isOpenAi ? models : null,
    );
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final isUrl = _type == ApiKeyType.customTileUrl;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FieldLabel(text: l10n.apiKeyType, colors: colors),
            const SizedBox(height: 6),
            _TypeDropdown(
              value: _type,
              onChanged: _onTypeChanged,
            ),
            const SizedBox(height: 16),

            // ── OpenAI-compatible template ────────────────────────────────
            if (_isOpenAi) ...[
              _FieldLabel(text: l10n.openAiProvider, colors: colors),
              const SizedBox(height: 6),
              _ProviderDropdown(
                value: _provider,
                onChanged: _onProviderChanged,
              ),
              const SizedBox(height: 16),
              _FieldLabel(text: l10n.openAiBaseUrl, colors: colors),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _baseUrlCtrl,
                      keyboardType: TextInputType.url,
                      style: TextStyle(
                          fontSize: 13, color: colors.textPrimary),
                      decoration: _inputDecoration(
                        colors,
                        hint: l10n.openAiBaseUrlHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TestButton(
                    testing: _testing,
                    result: _testResult,
                    onPressed: _testing ? null : _testConnection,
                  ),
                ],
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 6),
                Text(
                  _testResult == 'ok'
                      ? l10n.openAiTestOk
                      : '${l10n.openAiTestFail} (${_testResult!.substring(5)})',
                  style: TextStyle(
                    fontSize: 11,
                    color: _testResult == 'ok'
                        ? colors.success
                        : colors.danger,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // ── API key value (all types) ───────────────────────────────
            _FieldLabel(
              text: isUrl ? l10n.apiCustomTileUrl : l10n.apiKeyValue,
              colors: colors,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _valueCtrl,
              obscureText: !isUrl,
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
              decoration: _inputDecoration(
                colors,
                hint: isUrl
                    ? l10n.apiCustomTileUrlPlaceholder
                    : l10n.apiKeyValueHint,
                error: _showError ? l10n.apiKeyValue : null,
              ),
              onChanged: (_) {
                if (_showError) setState(() => _showError = false);
              },
            ),
            const SizedBox(height: 16),
            _FieldLabel(text: l10n.apiKeyLabel, colors: colors),
            const SizedBox(height: 6),
            TextField(
              controller: _labelCtrl,
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
              decoration:
              _inputDecoration(colors, hint: l10n.apiKeyLabelHint),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onClose,
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _testing ? null : _save,
                  child: _testing
                      ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(l10n.settingsSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    AppColors colors, {
    String? hint,
    String? error,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: colors.textDisabled),
      errorText: error,
      filled: true,
      fillColor: colors.surfaceLowered,
      isDense: true,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.accent, width: 1.5),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, required this.colors});

  final String text;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
    );
  }
}

/// Compact test-connection button with inline result indicator.
class _TestButton extends StatelessWidget {
  const _TestButton({
    required this.testing,
    required this.result,
    required this.onPressed,
  });

  final bool testing;
  final String? result;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final ok = result == 'ok';
    final fail = result != null && result != 'ok';

    return SizedBox(
      height: 38,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: ok
                ? colors.success
                : fail
                ? colors.danger
                : colors.border,
          ),
          foregroundColor: ok
              ? colors.success
              : fail
              ? colors.danger
              : colors.textSecondary,
        ),
        icon: testing
            ? const SizedBox(
          width: 13,
          height: 13,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Icon(
          ok
              ? Icons.check_circle_rounded
              : fail
              ? Icons.cancel_rounded
              : Icons.wifi_tethering_rounded,
          size: 16,
        ),
        label: Text(l10n.openAiTest, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

/// Named-provider dropdown (GLM / Qwen / DeepSeek / Custom).
class _ProviderDropdown extends StatefulWidget {
  const _ProviderDropdown({required this.value, required this.onChanged});

  final OpenAiProvider value;
  final ValueChanged<OpenAiProvider> onChanged;

  @override
  State<_ProviderDropdown> createState() => _ProviderDropdownState();
}

class _ProviderDropdownState extends State<_ProviderDropdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    String label(OpenAiProvider p) =>
        switch (p) {
          OpenAiProvider.glm => l10n.openAiProviderGlm,
          OpenAiProvider.qwen => l10n.openAiProviderQwen,
          OpenAiProvider.deepseek => l10n.openAiProviderDeepseek,
          OpenAiProvider.minimax => l10n.openAiProviderMinimax,
          OpenAiProvider.moonshot => l10n.openAiProviderMoonshot,
          OpenAiProvider.siliconflow => l10n.openAiProviderSiliconflow,
          OpenAiProvider.openrouter => l10n.openAiProviderOpenrouter,
          OpenAiProvider.custom => l10n.openAiProviderCustom,
        };

    IconData icon(OpenAiProvider p) =>
        switch (p) {
          OpenAiProvider.glm => Icons.auto_awesome_rounded,
          OpenAiProvider.qwen => Icons.blur_on_rounded,
          OpenAiProvider.deepseek => Icons.waves_rounded,
          OpenAiProvider.minimax => Icons.maximize_rounded,
          OpenAiProvider.moonshot => Icons.nights_stay_rounded,
          OpenAiProvider.siliconflow => Icons.grain_rounded,
          OpenAiProvider.openrouter => Icons.hub_rounded,
          OpenAiProvider.custom => Icons.edit_rounded,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceLowered,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _expanded ? colors.accent : colors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(icon(widget.value), size: 16, color: colors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label(widget.value),
                    style:
                    TextStyle(fontSize: 13, color: colors.textPrimary),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.arrow_drop_down_rounded,
                      size: 20, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 150),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(height: 0, width: double.infinity),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: OpenAiProvider.values.map((p) {
                final selected = p == widget.value;
                return InkWell(
                  onTap: () {
                    widget.onChanged(p);
                    setState(() => _expanded = false);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    child: Row(
                      children: [
                        Icon(icon(p),
                            size: 16,
                            color: selected
                                ? colors.accent
                                : colors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label(p),
                            style: TextStyle(
                              fontSize: 13,
                              color: selected
                                  ? colors.accent
                                  : colors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_rounded,
                              size: 14, color: colors.accent),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Type dropdown (existing, updated for openAiCompatible) ─────────────────

class _TypeDropdown extends StatefulWidget {
  const _TypeDropdown({required this.value, required this.onChanged});

  final ApiKeyType value;
  final ValueChanged<ApiKeyType> onChanged;

  @override
  State<_TypeDropdown> createState() => _TypeDropdownState();
}

class _TypeDropdownState extends State<_TypeDropdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceLowered,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _expanded ? colors.accent : colors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(_icon(widget.value),
                    size: 16, color: colors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _label(widget.value, l10n),
                    style:
                    TextStyle(fontSize: 13, color: colors.textPrimary),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.arrow_drop_down_rounded,
                      size: 20, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 150),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(height: 0, width: double.infinity),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ApiKeyType.values.map((t) {
                final selected = t == widget.value;
                return InkWell(
                  onTap: () {
                    widget.onChanged(t);
                    setState(() => _expanded = false);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    child: Row(
                      children: [
                        Icon(_icon(t),
                            size: 16,
                            color: selected
                                ? colors.accent
                                : colors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _label(t, l10n),
                            style: TextStyle(
                              fontSize: 13,
                              color: selected
                                  ? colors.accent
                                  : colors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_rounded,
                              size: 14, color: colors.accent),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  static IconData _icon(ApiKeyType t) => switch (t) {
    ApiKeyType.osmToken => Icons.terrain_rounded,
    ApiKeyType.mapboxToken => Icons.map_rounded,
    ApiKeyType.openAiCompatible => Icons.bolt_rounded,
    ApiKeyType.flightAware => Icons.flight_rounded,
    ApiKeyType.customTileUrl => Icons.link_rounded,
  };

  static String _label(ApiKeyType t, AppLocalizations l10n) => switch (t) {
    ApiKeyType.osmToken => l10n.apiKeyTypeOsmToken,
    ApiKeyType.mapboxToken => l10n.apiKeyTypeMapboxToken,
    ApiKeyType.openAiCompatible => l10n.apiKeyTypeOpenAiCompatible,
    ApiKeyType.flightAware => l10n.apiKeyTypeFlightAware,
    ApiKeyType.customTileUrl => l10n.apiKeyTypeCustomTileUrl,
  };
}
