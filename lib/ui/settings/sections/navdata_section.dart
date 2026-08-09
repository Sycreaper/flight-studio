import 'package:flutter/material.dart';

import '../../../data/background_tasks.dart';
import '../../../data/settings/settings_controller.dart';
import '../../../data/settings/simulator_install.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../settings_page.dart';
import '../../widgets/floating_window.dart';
import 'add_navdata_dialog.dart';

/// Navigation-data management section — a dynamic list of navdata sources,
/// each linked to a simulator install. Users can scan (import) navdata from
/// each source; the scan triggers the gear button to spin and shows progress
/// in the gear menu.
class NavDataSection extends StatelessWidget {
  const NavDataSection({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final sources = controller.value.navdataSources;
        final sims = controller.value.simulators;
        return SettingsSectionBody(
          title: l10n.settingsNavdataTitle,
          description: l10n.settingsNavdataDesc,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.settingsNavdataTitle} (${sources.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (sources.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      for (final src in sources) {
                        final sim = sims.cast<SimulatorInstall?>().firstWhere(
                              (s) => s?.id == src.simulatorId,
                          orElse: () => null,
                        );
                        final label = sim != null
                            ? '${sim.name ?? sim.type.persistedName} — ${src
                            .dataType == NavdataDataType.defaultData ? l10n
                            .navDefaultData : l10n.navCustomData}'
                            : l10n.navScan;
                        BackgroundTaskManager.instance.startFakeScan(label);
                      }
                    },
                    icon: Icon(
                        Icons.radar_rounded, size: 20, color: colors.accent),
                    tooltip: l10n.navCheckAll,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                  ),
                IconButton(
                  onPressed: () => showAddNavdataDialog(context, controller),
                  icon: Icon(Icons.add_rounded, size: 20, color: colors.accent),
                  tooltip: l10n.navAddTitle,
                  constraints: const BoxConstraints(
                      minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (sources.isEmpty)
              _EmptyState(colors: colors, l10n: l10n)
            else
              ...sources.map((src) {
                final sim = sims.cast<SimulatorInstall?>().firstWhere(
                      (s) => s?.id == src.simulatorId,
                  orElse: () => null,
                );
                return _NavListTile(
                  source: src,
                  simulator: sim,
                  onDelete: () => _confirmDelete(context, src.id),
                );
              }),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) =>
          FloatingWindow(
            title: l10n.navConfirmDelete,
            titleIcon: Icons.warning_amber_rounded,
            width: 400,
            height: 200,
            onClose: () => entry.remove(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Icon(Icons.delete_outline_rounded, size: 32,
                    color: colors.danger),
                const SizedBox(height: 12),
                Text(l10n.navConfirmDeleteDesc,
                    style: TextStyle(
                        fontSize: 13, color: colors.textSecondary)),
                const Spacer(),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: () => entry.remove(),
                      child: Text(l10n.settingsCancel)),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: colors.danger),
                    onPressed: () {
                      entry.remove();
                      controller.removeNavdataSource(id);
                    },
                    child: Text(l10n.navConfirmDelete.split('?')[0]),
                  ),
                ]),
              ]),
            ),
          ),
    );
    Overlay.of(context).insert(entry);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors, required this.l10n});

  final AppColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.dataset_outlined, size: 36, color: colors.textDisabled),
            const SizedBox(height: 12),
            Text(l10n.navEmpty,
                style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary)),
            const SizedBox(height: 4),
            Text(l10n.navEmptyHint,
                style: TextStyle(fontSize: 12, color: colors.accent)),
          ]),
        ),
      );
}

class _NavListTile extends StatefulWidget {
  const _NavListTile(
      {required this.source, this.simulator, required this.onDelete});

  final NavdataSource source;
  final SimulatorInstall? simulator;
  final VoidCallback onDelete;

  @override
  State<_NavListTile> createState() => _NavListTileState();
}

class _NavListTileState extends State<_NavListTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final sim = widget.simulator;
    final simLabel = sim != null
        ? '${_simTypeLabel(sim.type, l10n)}${sim.name != null &&
        sim.name!.isNotEmpty ? ' · ${sim.name}' : ''}'
        : l10n.navSelectSimulator;
    final dataLabel = widget.source.dataType == NavdataDataType.defaultData
        ? l10n.navDefaultData
        : l10n.navCustomData;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _hovering
              ? colors.surfaceLowered.withValues(alpha: 0.5)
              : colors.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Row(children: [
          Icon(Icons.dataset_outlined, size: 18, color: colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(simLabel, style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(dataLabel, style: TextStyle(
                      fontSize: 11, color: colors.textSecondary)),
                ]),
          ),
          IconButton(
            onPressed: widget.onDelete,
            icon: Icon(Icons.close_rounded, size: 16),
            color: _hovering ? colors.danger : colors.textDisabled,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ]),
      ),
    );
  }

  static String _simTypeLabel(SimulatorType t, AppLocalizations l10n) =>
      switch (t) {
        SimulatorType.xplane12 => l10n.simXplane12,
        SimulatorType.msfs2020 => l10n.simMsfs2020,
        SimulatorType.msfs2024 => l10n.simMsfs2024,
        SimulatorType.prepar3dV4 => l10n.simPrepar3dV4,
        SimulatorType.prepar3dV5 => l10n.simPrepar3dV5,
        SimulatorType.prepar3dV6 => l10n.simPrepar3dV6,
      };
}
