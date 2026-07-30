import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../settings/settings_window.dart';
import '../theme/app_colors.dart';
import '../widgets/tool_button.dart';

/// Toolbar shown when a Flight Plan Form tab is active.
///
/// Right side, in order: home (back to welcome), save, gear (opens the gear
/// menu — same as on the welcome screen). The gear is the single entry point
/// for settings / about / updates / help / exit.
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
            icon: Icons.auto_fix_high_rounded,
            tooltip: l10n.ttCalculatePlan,
            onPressed: onCalculate,
            accent: true,
          ),
          ToolButton(
            icon: Icons.restart_alt_rounded,
            tooltip: l10n.ttResetForm,
            onPressed: onReset,
          ),
          const ToolDivider(),
          ToolButton(
            icon: Icons.download_rounded,
            tooltip: l10n.ttImportRoute,
            onPressed: onImport ?? () {},
          ),
          ToolButton(
            icon: Icons.ios_share_rounded,
            tooltip: l10n.ttExportPlan,
            onPressed: onExport ?? () {},
          ),
          ToolButton(
            icon: Icons.cloud_download_rounded,
            tooltip: l10n.ttFetchSimBrief,
            onPressed: onFetch ?? () {},
          ),
          const Spacer(),
          ToolButton(
            icon: Icons.save_rounded,
            tooltip: l10n.ttSavePlan,
            onPressed: onSave ?? () {},
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
