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
      height: 380,
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

  @override
  void dispose() {
    _valueCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final value = _valueCtrl.text.trim();
    if (value.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    final label = _labelCtrl.text.trim();
    widget.controller.addApiKey(
      _type,
      value,
      label: label.isEmpty ? null : label,
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
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: 16),
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
              decoration: _inputDecoration(colors, hint: l10n.apiKeyLabelHint),
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
                FilledButton(onPressed: _save, child: Text(l10n.settingsSave)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        // Trigger button.
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceLowered,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _expanded ? colors.accent : colors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _icon(widget.value),
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _label(widget.value, l10n),
                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Inline expansion panel — renders inside the dialog body, no overlay
        // or z-order issues.
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
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _icon(t),
                          size: 16,
                          color: selected
                              ? colors.accent
                              : colors.textSecondary,
                        ),
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
                          Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: colors.accent,
                          ),
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
    ApiKeyType.aiCopilot => Icons.smart_toy_rounded,
    ApiKeyType.flightAware => Icons.flight_rounded,
    ApiKeyType.customTileUrl => Icons.link_rounded,
  };

  static String _label(ApiKeyType t, AppLocalizations l10n) => switch (t) {
    ApiKeyType.osmToken => l10n.apiKeyTypeOsmToken,
    ApiKeyType.mapboxToken => l10n.apiKeyTypeMapboxToken,
    ApiKeyType.aiCopilot => l10n.apiKeyTypeAiCopilot,
    ApiKeyType.flightAware => l10n.apiKeyTypeFlightAware,
    ApiKeyType.customTileUrl => l10n.apiKeyTypeCustomTileUrl,
  };
}
