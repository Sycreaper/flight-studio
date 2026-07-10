import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Right drawer: contextual inspector for the currently selected waypoint or
/// leg. Placeholder content until the route engine is wired up.
class InspectorPanel extends StatelessWidget {
  const InspectorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
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
            'Select a waypoint or leg on the map\nto inspect its details.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
