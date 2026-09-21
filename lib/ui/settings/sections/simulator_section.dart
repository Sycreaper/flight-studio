import 'dart:io';

import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../data/settings/simulator_install.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sim/simulator_connector.dart';
import '../../theme/app_colors.dart';
import '../../widgets/floating_window.dart';
import '../settings_page.dart';
import 'add_simulator_dialog.dart';

/// Simulator management section — a dynamic list of installed simulators with
/// a "+" button to add new ones. Each entry shows the type icon, label and
/// install path. Unsupported simulators show "Coming soon".
class SimulatorSection extends StatelessWidget {
  const SimulatorSection({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final sims = controller.value.simulators;
        return SettingsSectionBody(
          title: l10n.settingsSimulatorTitle,
          description: l10n.settingsSimulatorDesc,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.settingsSimulatorTitle} (${sims.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      showAddSimulatorDialog(context, controller),
                  icon:
                  Icon(Icons.add_rounded, size: 20, color: colors.accent),
                  tooltip: l10n.simAddTitle,
                  constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (sims.isEmpty)
              _EmptyState(colors: colors, l10n: l10n)
            else
              ...sims.map((sim) =>
                  _SimListTile(
                    sim: sim,
                    onDelete: () => _confirmDelete(context, sim),
                  )),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, SimulatorInstall sim) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) =>
          FloatingWindow(
            title: l10n.simConfirmDelete,
            titleIcon: Icons.warning_amber_rounded,
            width: 400,
            height: 200,
            onClose: () => entry.remove(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 32, color: colors.danger),
                  const SizedBox(height: 12),
                  Text(l10n.simConfirmDeleteDesc,
                      style:
                      TextStyle(fontSize: 13, color: colors.textSecondary)),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => entry.remove(),
                        child: Text(l10n.settingsCancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: colors.danger),
                        onPressed: () {
                          entry.remove();
                          controller.removeSimulator(sim.id);
                        },
                        child: Text(l10n.simConfirmDelete.split('?')[0]),
                      ),
                    ],
                  ),
                ],
              ),
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_takeoff_rounded,
                size: 36, color: colors.textDisabled),
            const SizedBox(height: 12),
            Text(l10n.simEmpty,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary)),
            const SizedBox(height: 4),
            Text(l10n.simEmptyHint,
                style: TextStyle(fontSize: 12, color: colors.accent)),
          ],
        ),
      ),
    );
  }
}

class _SimListTile extends StatefulWidget {
  const _SimListTile({required this.sim, required this.onDelete});

  final SimulatorInstall sim;
  final VoidCallback onDelete;

  @override
  State<_SimListTile> createState() => _SimListTileState();
}

class _SimListTileState extends State<_SimListTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final sim = widget.sim;
    final supported =
    SimConnectorRegistry.instance.isSupported(sim.type);
    final exists = supported ? Directory(sim.path).existsSync() : false;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _hovering
              ? colors.surfaceLowered.withValues(alpha: 0.5)
              : colors.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(_typeIcon(sim.type),
                size: 18,
                color: supported
                    ? colors.textSecondary
                    : colors.textDisabled),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        _typeLabel(sim.type, l10n),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (sim.name != null && sim.name!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text('· ${sim.name}',
                            style: TextStyle(
                                fontSize: 12, color: colors.textSecondary)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sim.path,
                    style: TextStyle(
                        fontSize: 11, color: colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!supported)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        l10n.simComingSoon,
                        style: TextStyle(
                            fontSize: 10,
                            color: colors.warning,
                            fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    if (exists)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 11, color: colors.success),
                            const SizedBox(width: 4),
                            Text(l10n.simValid,
                                style: TextStyle(
                                    fontSize: 10, color: colors.success)),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onDelete,
              icon: Icon(Icons.close_rounded, size: 16),
              color: _hovering ? colors.danger : colors.textDisabled,
              constraints:
              const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _typeIcon(SimulatorType t) =>
      switch (t) {
        SimulatorType.xplane12 => Icons.flight_rounded,
        SimulatorType.msfs2020 => Icons.flight_takeoff_rounded,
        SimulatorType.msfs2024 => Icons.flight_takeoff_rounded,
        SimulatorType.prepar3dV4 => Icons.flight_land_rounded,
        SimulatorType.prepar3dV5 => Icons.flight_land_rounded,
        SimulatorType.prepar3dV6 => Icons.flight_land_rounded,
      };

  static String _typeLabel(SimulatorType t, AppLocalizations l10n) =>
      switch (t) {
        SimulatorType.xplane12 => l10n.simXplane12,
        SimulatorType.msfs2020 => l10n.simMsfs2020,
        SimulatorType.msfs2024 => l10n.simMsfs2024,
        SimulatorType.prepar3dV4 => l10n.simPrepar3dV4,
        SimulatorType.prepar3dV5 => l10n.simPrepar3dV5,
        SimulatorType.prepar3dV6 => l10n.simPrepar3dV6,
      };
}
