import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The mandatory wrapper for every workspace centre card (map, flight-plan
/// form, settings, and any future third-party plugin card).
///
/// Applies the standard rounded-corner, `surfaceRaised`-background, no-border
/// look. **Cards must never have a visible border** — the visual separation
/// between the card and the surrounding workspace comes from the colour
/// contrast between `surfaceRaised` (card) and `surfaceBase` (workspace
/// background) alone. This is enforced here so that plugin authors get the
/// correct look automatically by using this widget.
class CenterCard extends StatelessWidget {
  const CenterCard({super.key, required this.child, this.radius = 12});

  /// The card's content. Should fill the available space (typically a
  /// `Column`, `Stack`, or scroll view).
  final Widget child;

  /// Corner radius. Defaults to 12 to match the rest of the workspace.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
        // Deliberately NO border — see class docs.
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
