import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Shows the standard confirmation dialog (reference: JetBrains-style
/// compact confirm) and awaits the user's answer — `true` on confirm,
/// `false` on cancel or dismissing the barrier.
///
/// Layout per the design reference: icon block + bold title on one
/// left-aligned row, left-aligned body text (pass [bodySpans] to
/// highlight names in accent / danger words), and the button row
/// bottom-right with the PRIMARY filled button left and the secondary
/// outlined button right.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? body,
  List<InlineSpan>? bodySpans,
  required String confirmLabel,
  IconData icon = Icons.warning_amber_rounded,
  bool destructive = true,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _ConfirmDialog(
      title: title,
      body: body,
      bodySpans: bodySpans,
      confirmLabel: confirmLabel,
      cancelLabel: l10n.settingsCancel,
      icon: icon,
      destructive: destructive,
    ),
  ).then((confirmed) => confirmed ?? false);
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.destructive,
    this.body,
    this.bodySpans,
  });

  final String title;
  final String? body;
  final List<InlineSpan>? bodySpans;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = destructive ? colors.danger : colors.accent;

    return Dialog(
      backgroundColor: colors.surfaceRaised,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.10),
              blurRadius: 16,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon block + bold title, one left-aligned row.
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 17, color: tone),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (body != null || bodySpans != null) ...[
              const SizedBox(height: 14),
              Text.rich(
                TextSpan(
                  children: bodySpans ??
                      [
                        TextSpan(
                          text: body,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.55,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Button row, bottom-right: primary (filled) LEFT, secondary
            // (outlined) RIGHT — per the reference design.
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: tone,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmLabel),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    side: BorderSide(color: colors.border),
                    backgroundColor: colors.surfaceBase,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
