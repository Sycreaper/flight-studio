import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/tool_button.dart';

/// Toolbar shown when a Map tab is active.
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
    this.onSettings,
  });

  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback? onExport;
  final VoidCallback? onCalculate;
  final VoidCallback? onConnect;
  final VoidCallback? onPause;
  final VoidCallback? onProjection;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
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
            tooltip: 'New flight plan',
            onPressed: onNew,
            accent: true,
          ),
          ToolButton(
            icon: Icons.folder_open_rounded,
            tooltip: 'Open flight plan',
            onPressed: onOpen,
          ),
          const ToolDivider(),
          ToolButton(
            icon: Icons.ios_share_rounded,
            tooltip: 'Export',
            onPressed: onExport ?? () {},
          ),
          ToolButton(
            icon: Icons.route_rounded,
            tooltip: 'Calculate route',
            onPressed: onCalculate ?? () {},
          ),
          const ToolDivider(),
          ToolButton(
            icon: Icons.play_arrow_rounded,
            tooltip: 'Connect simulator',
            onPressed: onConnect ?? () {},
          ),
          ToolButton(
            icon: Icons.pause_circle_outline_rounded,
            tooltip: 'Pause simulator',
            onPressed: onPause ?? () {},
          ),
          const Spacer(),
          ToolButton(
            icon: Icons.public_rounded,
            tooltip: 'Toggle projection',
            onPressed: onProjection ?? () {},
          ),
          ToolButton(
            icon: Icons.settings_rounded,
            tooltip: 'Settings',
            onPressed: onSettings ?? () {},
          ),
        ],
      ),
    );
  }
}
