import 'package:flutter/material.dart';

import 'floating_window.dart';

/// Shows a [FloatingWindow]-style dialog as an overlay on top of the app.
///
/// Unlike Flutter's built-in [showDialog] (which renders a centred
/// [AlertDialog] that can't be moved), this produces the in-app floating
/// window with a draggable title bar, ✕ close button, and the balance-scale
/// icon — the same chrome the settings window used before it became a tab.
///
/// The dialog is **not** modal: the underlying app stays interactive. Tapping
/// outside the window dismisses it (unless [barrierDismissable] is `false`).
///
/// Example:
/// ```dart
/// showFloatingDialog(
///   context,
///   title: l10n.settingsAboutLicense,
///   body: Padding(
///     padding: EdgeInsets.all(24),
///     child: SingleChildScrollView(child: Text(licenseText)),
///   ),
/// );
/// ```
OverlayEntry showFloatingDialog(
  BuildContext context, {
  required String title,
  required Widget body,
  IconData titleIcon = Icons.balance_rounded,
  double width = 520,
  double height = 400,
  bool barrierDismissable = true,
}) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => FloatingWindow(
      title: title,
      titleIcon: titleIcon,
      width: width,
      height: height,
      barrierDismissable: barrierDismissable,
      onClose: () => entry.remove(),
      child: body,
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  return entry;
}
