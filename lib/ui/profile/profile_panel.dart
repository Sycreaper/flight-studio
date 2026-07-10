import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Profile chart content (altitude / fuel / speed / weather). Rendered inside a
/// [WorkspaceDrawer]; the drawer provides the header and visibility toggling, so
/// this widget only draws the tab strip and the chart placeholder.
class ProfilePanel extends StatelessWidget {
  const ProfilePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final tabs = ['Altitude', 'Fuel', 'Speed', 'Weather'];
    return Container(
      color: colors.surfaceRaised,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Text(
                    tabs[i].toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: i == 0 ? colors.accent : colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart_rounded,
                      size: 28, color: colors.textDisabled),
                  const SizedBox(height: 8),
                  Text(
                    'Altitude/fuel profile will render here',
                    style:
                        TextStyle(fontSize: 12, color: colors.textDisabled),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
