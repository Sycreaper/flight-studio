import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../settings/settings_window.dart';
import '../theme/app_colors.dart';
import '../widgets/tool_button.dart';

/// Toolbar shown when a Map tab is active.
///
/// Right side, in order: home (back to welcome), projection toggle, gear (opens
/// the gear menu — Settings / About / Updates / Help / Exit). The gear is the
/// single entry point for everything not on the toolbar.
class MapToolbar extends StatelessWidget {
  const MapToolbar({
    super.key,
    required this.onNew,
    required this.onOpen,
    this.onExport,
    this.onCalculate,
    this.onConnect,
    this.onPause,
    this.onProjection,
  });

  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback? onExport;
  final VoidCallback? onCalculate;
  final VoidCallback? onConnect;
  final VoidCallback? onPause;
  final VoidCallback? onProjection;

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
          const Spacer(),
          ToolButton(
            icon: Icons.public_rounded,
            tooltip: l10n.ttToggleProjection,
            onPressed: onProjection ?? () {},
          ),
          Builder(
            builder: (gearContext) =>
                ToolButton(
                  icon: Icons.settings_rounded,
                  tooltip: l10n.gearMenuTooltip,
                  onPressed: () => showGearMenu(gearContext),
                ),
          ),
        ],
      ),
    );
  }
}
