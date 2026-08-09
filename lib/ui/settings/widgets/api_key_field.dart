import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../theme/app_colors.dart';
import 'settings_text_field.dart';

/// A secure API-key entry field. Once a key is saved it is **never displayed
/// in full** — only the first 4 and last 4 characters are shown (e.g.
/// `sk-1…wXYZ`). To change the key the user must clear it first, then type a
/// new one.
///
/// The raw value lives in [SettingsController] and is only ever passed to the
/// downstream consumer (tile provider, LLM client, etc.) — no widget in the
/// tree can read it back.
class ApiKeyField extends StatefulWidget {
  const ApiKeyField({
    super.key,
    required this.controller,
    required this.currentValue,
    required this.onCommit,
    required this.label,
    required this.hint,
    this.placeholder,
    this.maxWidth = 320,
  });

  final SettingsController controller;
  final String? currentValue;
  final ValueChanged<String?> onCommit;
  final String label;
  final String hint;
  final String? placeholder;
  final double maxWidth;

  @override
  State<ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<ApiKeyField> {
  late TextEditingController _input;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  bool get _isSet {
    final v = widget.currentValue;
    return v != null && v.isNotEmpty;
  }

  void _commit() {
    final text = _input.text.trim();
    widget.onCommit(text.isEmpty ? null : text);
    _input.clear();
    setState(() {});
  }

  void _clear() => widget.onCommit(null);

  static String _mask(String key) {
    if (key.length <= 4) return key;
    if (key.length <= 8) {
      return '${key.substring(0, 2)}…${key.substring(key.length - 2)}';
    }
    return '${key.substring(0, 4)}…${key.substring(key.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    // State A: key is set → masked display + Clear button.
    if (_isSet) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surfaceLowered,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 13, color: colors.success),
                const SizedBox(width: 6),
                Text(
                  _mask(widget.currentValue!),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _clear,
            icon: const Icon(Icons.close_rounded, size: 16),
            tooltip: 'Clear',
            color: colors.danger,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      );
    }

    // State B: not set → TextField for entering a new key.
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: SettingsTextField(
        initialValue: '',
        placeholder: widget.placeholder ?? widget.hint,
        obscure: true,
        onCommit: (_) => _commit(),
      ),
    );
  }
}
