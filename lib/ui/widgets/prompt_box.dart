import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// The floating AI prompt box used on the welcome **Start** page and the chat
/// tab. White pill with a double soft shadow; morphs into a rounded rectangle
/// (and grows up to 6 lines) once text is entered. The send button is
/// intentionally inert until the Letta chat loop is wired.
///
/// Layout note: the TextField node sits in a SINGLE stable Row in both states
/// — swapping child trees on text changes would recreate its element and drop
/// input focus after the first character.
class PromptBox extends StatelessWidget {
  const PromptBox({
    super.key,
    required this.controller,
    this.onSend,
    this.onStop,
    this.isStreaming = false,
  });

  final TextEditingController controller;

  /// Called with the trimmed text on send (Enter or the round button).
  /// `null` disables sending entirely.
  final ValueChanged<String>? onSend;

  /// Called when the stop button is pressed while [isStreaming].
  final VoidCallback? onStop;

  /// While streaming, the round button turns into a stop control and Enter
  /// is ignored.
  final bool isStreaming;

  void _submit() {
    if (isStreaming) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;
    onSend?.call(text);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = controller.text.isNotEmpty;
    final radius = hasText ? 18.0 : 28.0;

    final plusButton = IconButton(
      onPressed: () {},
      icon: Icon(Icons.add_rounded, size: 22, color: colors.textSecondary),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
    );

    // Black circular send / stop button (img style).
    final sendButton = GestureDetector(
      onTap: isStreaming ? onStop : _submit,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isStreaming
              ? colors.accent.withValues(alpha: 0.2)
              : isDark
              ? colors.accent
              : colors.textPrimary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isStreaming ? Icons.stop_rounded : Icons.arrow_upward_rounded,
          size: 18,
          color: isStreaming
              ? colors.textPrimary
              : isDark
              ? Colors.black
              : Colors.white,
        ),
      ),
    );

    final textField = TextField(
      controller: controller,
      // Static min/max lines — the SAME TextField widget must persist across
      // the empty→has-text rebuild, otherwise its element is recreated and
      // input focus is dropped after the first character.
      minLines: 1,
      maxLines: 6,
      style: TextStyle(fontSize: 14.5, color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: l10n.startPromptHint,
        hintStyle: TextStyle(fontSize: 14.5, color: colors.textDisabled),
        // The global theme fills fields with surfaceLowered and draws
        // enabled/focused outlines — inside the white pill both render as a
        // stray grey block / wireframe. Sit the placeholder directly on the
        // pill with no fill and no borders.
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );

    // Enter sends (suppressing the newline); Shift+Enter keeps the newline.
    final enterToSend = Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.enter): const _SendIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SendIntent: CallbackAction<_SendIntent>(
            onInvoke: (_) {
              _submit();
              return null;
            },
          ),
        },
        child: textField,
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      // Single stable Row in BOTH states — only the container's corner radius
      // morphs (pill ↔ rounded rect as the field grows to 6 lines).
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          plusButton,
          const SizedBox(width: 6),
          Expanded(child: enterToSend),
          const SizedBox(width: 8),
          sendButton,
        ],
      ),
    );
  }
}

class _SendIntent extends Intent {
  const _SendIntent();
}
