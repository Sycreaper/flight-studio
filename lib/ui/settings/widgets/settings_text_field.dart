import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A dense text field bound to a string setting.
///
/// Commits the value back to the controller on submit (Enter) or when the
/// field loses focus — never on every keystroke — so the rest of the UI is not
/// rebuilt while typing.
class SettingsTextField extends StatefulWidget {
  const SettingsTextField({
    super.key,
    required this.initialValue,
    required this.onCommit,
    this.placeholder,
    this.obscure = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffix,
    this.enabled = true,
    this.expand = false,
    this.minLines,
    this.maxWidth,
  });

  final String? initialValue;
  final ValueChanged<String?> onCommit;
  final String? placeholder;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffix;
  final bool enabled;
  final bool expand;
  final int? minLines;
  final double? maxWidth;

  @override
  State<SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<SettingsTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  String? _lastCommitted;

  @override
  void initState() {
    super.initState();
    _lastCommitted = widget.initialValue;
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _focus = FocusNode();
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant SettingsTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the field when the source-of-truth changes *and* the user isn't
    // actively editing it (otherwise typing would fight the controller).
    if (widget.initialValue != _lastCommitted && !_focus.hasFocus) {
      _lastCommitted = widget.initialValue;
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      _commit();
    }
  }

  void _commit() {
    final value = _controller.text.trim().isEmpty
        ? null
        : _controller.text.trim();
    if (value != _lastCommitted) {
      _lastCommitted = value;
      widget.onCommit(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colors.border),
    );
    final field = TextField(
      controller: _controller,
      focusNode: _focus,
      enabled: widget.enabled,
      obscureText: widget.obscure,
      keyboardType: widget.keyboardType,
      minLines: widget.expand ? widget.minLines ?? 2 : 1,
      maxLines: widget.expand ? null : 1,
      style: TextStyle(fontSize: 13, color: colors.textPrimary),
      onSubmitted: (_) => _commit(),
      textInputAction: widget.expand
          ? TextInputAction.newline
          : TextInputAction.done,
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.placeholder,
        hintStyle: TextStyle(fontSize: 13, color: colors.textDisabled),
        filled: true,
        fillColor: colors.surfaceLowered,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffix,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.accent, width: 1.4),
        ),
      ),
    );
    if (widget.maxWidth == null) return field;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth!),
      child: field,
    );
  }
}
