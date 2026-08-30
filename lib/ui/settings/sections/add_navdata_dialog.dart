import 'package:flutter/material.dart';

import '../../../data/navdata/navdata_service.dart';
import '../../../data/settings/settings_controller.dart';
import '../../../data/settings/simulator_install.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/floating_window.dart';

void showAddNavdataDialog(BuildContext context, SettingsController controller) {
  final l10n = AppLocalizations.of(context)!;
  final sims = controller.value.simulators;
  late OverlayEntry entry;

  // If no simulators, show a warning dialog instead.
  if (sims.isEmpty) {
    entry = OverlayEntry(
      builder: (ctx) => FloatingWindow(
        title: l10n.navAddTitle,
        titleIcon: Icons.warning_amber_rounded,
        width: 400,
        height: 220,
        onClose: () => entry.remove(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 36,
                color: Theme.of(ctx).extension<AppColors>()!.warning,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.navNoSimulator,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(ctx).extension<AppColors>()!.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => entry.remove(),
                child: Text(l10n.settingsClose),
              ),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    return;
  }

  entry = OverlayEntry(
    builder: (ctx) => FloatingWindow(
      title: l10n.navAddTitle,
      titleIcon: Icons.dataset_outlined,
      width: 460,
      height: 360,
      onClose: () => entry.remove(),
      child: _AddNavdataBody(
        controller: controller,
        onClose: () => entry.remove(),
      ),
    ),
  );
  Overlay.of(context).insert(entry);
}

class _AddNavdataBody extends StatefulWidget {
  const _AddNavdataBody({required this.controller, required this.onClose});

  final SettingsController controller;
  final VoidCallback onClose;

  @override
  State<_AddNavdataBody> createState() => _AddNavdataBodyState();
}

class _AddNavdataBodyState extends State<_AddNavdataBody> {
  String? _selectedSimId;
  NavdataDataType _dataType = NavdataDataType.defaultData;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final sims = widget.controller.value.simulators;
    final selectedSim = sims.cast<SimulatorInstall?>().firstWhere(
      (s) => s?.id == _selectedSimId,
      orElse: () => null,
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Simulator selector
            _Label(colors: colors, text: l10n.navSelectSimulator),
            const SizedBox(height: 6),
            _SimSelector(
              sims: sims,
              selectedId: _selectedSimId,
              expanded: _expanded,
              onToggle: () => setState(() => _expanded = !_expanded),
              onSelect: (id) => setState(() {
                _selectedSimId = id;
                _expanded = false;
              }),
            ),
            const SizedBox(height: 16),

            // Data type selector (only for X-Plane)
            if (selectedSim != null &&
                selectedSim.type == SimulatorType.xplane12) ...[
              _Label(colors: colors, text: l10n.navDataType),
              const SizedBox(height: 6),
              _DataTypeSelector(
                value: _dataType,
                onChanged: (t) => setState(() => _dataType = t),
                l10n: l10n,
                colors: colors,
              ),
            ],

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onClose,
                  child: Text(
                    l10n.settingsCancel,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _selectedSimId == null
                      ? null
                      : () {
                          widget.controller.addNavdataSource(
                            _selectedSimId!,
                            _dataType,
                          );
                          // Kick off the real navdata import in the background.
                          NavdataService.instance
                              .importFromSimulators(sims.toList());
                          widget.onClose();
                        },
                  child: Text(l10n.navScan),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.colors, required this.text});

  final AppColors colors;
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: colors.textSecondary,
    ),
  );
}

class _SimSelector extends StatelessWidget {
  const _SimSelector({
    required this.sims,
    required this.selectedId,
    required this.expanded,
    required this.onToggle,
    required this.onSelect,
  });

  final List<SimulatorInstall> sims;
  final String? selectedId;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final selected = sims.cast<SimulatorInstall?>().firstWhere(
      (s) => s?.id == selectedId,
      orElse: () => null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceLowered,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: expanded ? colors.accent : colors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flight_rounded,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selected != null
                        ? '${_typeLabel(selected.type, l10n)}${selected.name != null && selected.name!.isNotEmpty ? ' · ${selected.name}' : ''}'
                        : l10n.navSelectSimulator,
                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 150),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(height: 0, width: double.infinity),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: sims.map((sim) {
                final isSelected = sim.id == selectedId;
                return InkWell(
                  onTap: () => onSelect(sim.id),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flight_rounded,
                          size: 16,
                          color: isSelected
                              ? colors.accent
                              : colors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${_typeLabel(sim.type, l10n)}${sim.name != null && sim.name!.isNotEmpty ? ' · ${sim.name}' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? colors.accent
                                  : colors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: colors.accent,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

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

class _DataTypeSelector extends StatelessWidget {
  const _DataTypeSelector({
    required this.value,
    required this.onChanged,
    required this.l10n,
    required this.colors,
  });

  final NavdataDataType value;
  final ValueChanged<NavdataDataType> onChanged;
  final AppLocalizations l10n;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(NavdataDataType.defaultData),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: value == NavdataDataType.defaultData
                    ? colors.accent.withValues(alpha: 0.12)
                    : colors.surfaceLowered,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: value == NavdataDataType.defaultData
                      ? colors.accent
                      : colors.border,
                ),
              ),
              child: Text(
                l10n.navDefaultData,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: value == NavdataDataType.defaultData
                      ? colors.accent
                      : colors.textPrimary,
                  fontWeight: value == NavdataDataType.defaultData
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(NavdataDataType.custom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: value == NavdataDataType.custom
                    ? colors.accent.withValues(alpha: 0.12)
                    : colors.surfaceLowered,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: value == NavdataDataType.custom
                      ? colors.accent
                      : colors.border,
                ),
              ),
              child: Text(
                l10n.navCustomData,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: value == NavdataDataType.custom
                      ? colors.accent
                      : colors.textPrimary,
                  fontWeight: value == NavdataDataType.custom
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
