import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Right drawer: contextual inspector for the currently selected waypoint or
/// leg. Placeholder content until the route engine is wired up.
class InspectorPanel extends StatelessWidget {
  const InspectorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 32,
              color: colors.textDisabled,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.inspectorHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
