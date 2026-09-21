import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/tool_button.dart';

/// Toolbar shown when a Map tab is active.
///
/// The gear lives in the tab bar (visible on every tab); this toolbar carries
/// only the map-specific actions.
class MapToolbar extends StatelessWidget {
  const MapToolbar({
    super.key,
    required this.onNew,
    required this.onOpen,
    this.onExport,
    this.onCalculate,
    this.onConnect,
    this.onPause,
  });

  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback? onExport;
  final VoidCallback? onCalculate;
  final VoidCallback? onConnect;
  final VoidCallback? onPause;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colors.chrome,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          ToolButton(
            icon: Icons.note_add_rounded,
            tooltip: l10n.ttNewFlightPlan,
            onPressed: onNew,
            accent: true,
          ),
          ToolButton(
            icon: Icons.folder_open_rounded,
            tooltip: l10n.ttOpenFlightPlan,
            onPressed: onOpen,
          ),
          const ToolDivider(),
          ToolButton(
            icon: Icons.ios_share_rounded,
            tooltip: l10n.ttExport,
            onPressed: onExport ?? () {},
          ),
          ToolButton(
            icon: Icons.route_rounded,
            tooltip: l10n.ttCalculateRoute,
            onPressed: onCalculate ?? () {},
          ),
          const ToolDivider(),
          ToolButton(
            icon: Icons.play_arrow_rounded,
            tooltip: l10n.ttConnectSim,
            onPressed: onConnect ?? () {},
          ),
          ToolButton(
            icon: Icons.pause_circle_outline_rounded,
            tooltip: l10n.ttPauseSim,
            onPressed: onPause ?? () {},
          ),
        ],
      ),
    );
  }
}
