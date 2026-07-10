import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/tool_button.dart';

/// Toolbar shown when a Flight Plan Form tab is active.
class FormToolbar extends StatelessWidget {
  const FormToolbar({
    super.key,
    required this.onCalculate,
    required this.onReset,
    this.onImport,
    this.onExport,
    this.onSave,
    this.onFetch,
  });

  final VoidCallback onCalculate;
  final VoidCallback onReset;
  final VoidCallback? onImport;
  final VoidCallback? onExport;
  final VoidCallback? onSave;
  final VoidCallback? onFetch;

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
            icon: Icons.auto_fix_high_rounded,
            tooltip: 'Calculate plan',
            onPressed: onCalculate,
            accent: true,
          ),
          ToolButton(
            icon: Icons.restart_alt_rounded,
            tooltip: 'Reset form',
            onPressed: onReset,
          ),
          const ToolDivider(),
          ToolButton(
            icon: Icons.download_rounded,
            tooltip: 'Import route',
            onPressed: onImport ?? () {},
          ),
          ToolButton(
            icon: Icons.ios_share_rounded,
            tooltip: 'Export plan',
            onPressed: onExport ?? () {},
          ),
          ToolButton(
            icon: Icons.cloud_download_rounded,
            tooltip: 'Fetch from SimBrief',
            onPressed: onFetch ?? () {},
          ),
          const Spacer(),
          ToolButton(
            icon: Icons.save_rounded,
            tooltip: 'Save plan',
            onPressed: onSave ?? () {},
          ),
        ],
      ),
    );
  }
}
