import 'package:flutter/material.dart';

import '../../../data/navdata/navdata_service.dart';
import '../../../data/navdata/startup_scan.dart';
import '../../../data/settings/settings_controller.dart';
import '../../../data/settings/simulator_install.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/floating_window.dart';
import '../settings_page.dart';
import 'add_navdata_dialog.dart';

/// Navigation-data management section — a dynamic list of navdata sources,
/// each linked to a simulator install. One source is the ACTIVE one (native
/// [Radio] selection): it is the target of "check all" and the startup scan.
/// Each card shows its source's AIRAC cycle (read from the install's
/// `cycle_info.txt`).
class NavDataSection extends StatefulWidget {
  const NavDataSection({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<NavDataSection> createState() => _NavDataSectionState();
}

class _NavDataSectionState extends State<NavDataSection> {
  /// AIRAC cycle per simulator-install path (null = none found yet/ever).
  final Map<String, String?> _airacByInstallPath = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAiracCycles();
  }

  /// Fetches the AIRAC cycle for every install referenced by a source that
  /// has not been resolved yet. Individual failures just leave '—'.
  void _loadAiracCycles() {
    final s = widget.controller.value;
    for (final source in s.navdataSources) {
      for (final sim in s.simulators) {
        if (sim.id != source.simulatorId) continue;
        if (_airacByInstallPath.containsKey(sim.path)) continue;
        _airacByInstallPath[sim.path] = null; // pending marker
        NavdataService.instance.readAiracCycle(sim).then((cycle) {
          if (!mounted) return;
          setState(() => _airacByInstallPath[sim.path] = cycle);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.value;
        final sources = s.navdataSources;
        final sims = s.simulators;
        final activeId = s.activeNavdataSourceId;
        _loadAiracCycles();
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
                    onPressed: () => importSelectedNavdata(s),
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
            // Native Flutter radio group — exactly one active navdata
            // source; the group value is the persisted selection.
              RadioGroup<String>(
                groupValue: activeId,
                onChanged: (id) => controller.setActiveNavdataSource(id),
                child: Column(
                  children: [
                    for (final src in sources)
                      _NavListTile(
                        source: src,
                        controller: controller,
                        simulator: sims.cast<SimulatorInstall?>().firstWhere(
                              (s) => s?.id == src.simulatorId,
                          orElse: () => null,
                        ),
                        airac: _airacByInstallPath[
                        _installPathFor(sims, src.simulatorId)],
                        selected: activeId == src.id,
                        onDelete: () => _confirmDelete(context, src.id),
                      ),
                  ],
                ),
              ),
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
                      // Deleting the ACTIVE source clears the selection so
                      // the fallback (first compatible install) resumes.
                      if (widget.controller.value.activeNavdataSourceId ==
                          id) {
                        widget.controller.setActiveNavdataSource(null);
                      }
                      widget.controller.removeNavdataSource(id);
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

  String? _installPathFor(List<SimulatorInstall> sims, String simulatorId) {
    for (final sim in sims) {
      if (sim.id == simulatorId) return sim.path;
    }
    return null;
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
  const _NavListTile({
    required this.source,
    required this.controller,
    this.simulator,
    this.airac,
    required this.selected,
    required this.onDelete,
  });

  final NavdataSource source;
  final SettingsController controller;
  final SimulatorInstall? simulator;

  /// AIRAC cycle of the source's install (e.g. `'2608'`), or null while
  /// loading / when the install carries no `cycle_info.txt`.
  final String? airac;

  /// Whether this source is the ACTIVE one (radio group value).
  final bool selected;
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
    final selected = widget.selected;
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Clicking anywhere on the row also selects the source.
        onTap: () =>
            widget.controller.setActiveNavdataSource(widget.source.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: selected
                ? colors.accent.withValues(alpha: 0.10)
                : _hovering
                ? colors.surfaceLowered.withValues(alpha: 0.5)
                : colors.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? colors.accent : colors.border,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(children: [
            // Native Flutter radio — the RadioGroup ancestor owns the
            // group value; tapping here just selects this source.
            Radio<String>(
              value: widget.source.id,
              activeColor: colors.accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Text(simLabel, style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary)),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.navActiveSource,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: colors.accent,
                            ),
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(
                        widget.airac == null
                            ? dataLabel
                            : '$dataLabel · AIRAC ${widget.airac}',
                        style: TextStyle(
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
