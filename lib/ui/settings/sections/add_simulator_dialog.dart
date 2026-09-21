import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../data/settings/simulator_install.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sim/simulator_connector.dart';
import '../../theme/app_colors.dart';
import '../../widgets/floating_window.dart';

void showAddSimulatorDialog(
  BuildContext context,
  SettingsController controller,
) {
  final l10n = AppLocalizations.of(context)!;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => FloatingWindow(
      title: l10n.simAddTitle,
      titleIcon: Icons.flight_takeoff_rounded,
      width: 480,
      height: 440,
      onClose: () => entry.remove(),
      child: _AddSimulatorBody(
        controller: controller,
        onClose: () => entry.remove(),
      ),
    ),
  );
  Overlay.of(context).insert(entry);
}

class _AddSimulatorBody extends StatefulWidget {
  const _AddSimulatorBody({required this.controller, required this.onClose});

  final SettingsController controller;
  final VoidCallback onClose;

  @override
  State<_AddSimulatorBody> createState() => _AddSimulatorBodyState();
}

class _AddSimulatorBodyState extends State<_AddSimulatorBody> {
  SimulatorType _type = SimulatorType.xplane12;
  final _pathCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  String? _validationMsg;
  bool _validated = false;

  @override
  void dispose() {
    _pathCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  void _validate() {
    final path = _pathCtrl.text.trim();
    if (path.isEmpty) {
      setState(() {
        _validated = false;
        _validationMsg = null;
      });
      return;
    }
    final exe = File('$path\\${_type.validatorExe}');
    final exists = exe.existsSync();
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _validated = exists;
      _validationMsg = exists
          ? null
          : l10n.simInvalidNotFound(_type.validatorExe);
    });
  }

  Future<void> _browse() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.getDirectoryPath(
      dialogTitle: l10n.simInstallPathHint,
    );
    if (result != null && mounted) {
      _pathCtrl.text = result;
      _validate();
    }
  }

  void _save() {
    final path = _pathCtrl.text.trim();
    if (path.isEmpty || !_validated) return;
    final label = _labelCtrl.text.trim();
    widget.controller.addSimulator(
      _type,
      path,
      name: label.isEmpty ? null : label,
    );
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final supported = SimConnectorRegistry.instance.isSupported(_type);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Label(colors: colors, text: l10n.simType),
            const SizedBox(height: 6),
            _TypeDropdown(
              value: _type,
              onChanged: (t) => setState(() {
                _type = t;
                _validated = false;
                _validationMsg = null;
              }),
            ),
            const SizedBox(height: 16),
            if (supported) ...[
              _Label(colors: colors, text: l10n.simInstallPath),
              const SizedBox(height: 6),
              TextField(
                controller: _pathCtrl,
                style: TextStyle(fontSize: 13, color: colors.textPrimary),
                decoration: _input(
                  colors,
                  hint: l10n.simPathPlaceholder,
                  suffix: IconButton(
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                    onPressed: _browse,
                    tooltip: l10n.simBrowse,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
                onChanged: (_) {
                  if (_validated) setState(() => _validated = false);
                },
                onSubmitted: (_) => _validate(),
              ),
              if (_validationMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 13,
                        color: colors.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _validationMsg!,
                        style: TextStyle(fontSize: 11, color: colors.danger),
                      ),
                    ],
                  ),
                ),
              if (_validated)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: colors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.simValid,
                        style: TextStyle(fontSize: 11, color: colors.success),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _Label(colors: colors, text: l10n.simLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _labelCtrl,
                style: TextStyle(fontSize: 13, color: colors.textPrimary),
                decoration: _input(colors, hint: l10n.simLabelHint),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surfaceLowered,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      size: 32,
                      color: colors.warning,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.simComingSoon,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
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
                  onPressed: supported && _validated ? _save : null,
                  child: Text(l10n.settingsSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(AppColors colors, {String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: colors.textDisabled),
      filled: true,
      fillColor: colors.surfaceLowered,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.accent, width: 1.5),
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

/// Inline expansion dropdown for simulator type — same pattern as the API
/// key dialog's type dropdown (avoids z-order issues inside FloatingWindow).
class _TypeDropdown extends StatefulWidget {
  const _TypeDropdown({required this.value, required this.onChanged});

  final SimulatorType value;
  final ValueChanged<SimulatorType> onChanged;

  @override
  State<_TypeDropdown> createState() => _TypeDropdownState();
}

class _TypeDropdownState extends State<_TypeDropdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceLowered,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _expanded ? colors.accent : colors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _icon(widget.value),
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _label(widget.value, l10n),
                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
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
          crossFadeState: _expanded
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
              children: SimulatorType.values.map((t) {
                final selected = t == widget.value;
                return InkWell(
                  onTap: () {
                    widget.onChanged(t);
                    setState(() => _expanded = false);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _icon(t),
                          size: 16,
                          color: selected
                              ? colors.accent
                              : colors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _label(t, l10n),
                            style: TextStyle(
                              fontSize: 13,
                              color: selected
                                  ? colors.accent
                                  : colors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (!SimConnectorRegistry.instance.isSupported(t))
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              'soon',
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textDisabled,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        if (selected)
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

  static IconData _icon(SimulatorType t) => switch (t) {
    SimulatorType.xplane12 => Icons.flight_rounded,
    SimulatorType.msfs2020 => Icons.flight_takeoff_rounded,
    SimulatorType.msfs2024 => Icons.flight_takeoff_rounded,
    SimulatorType.prepar3dV4 => Icons.flight_land_rounded,
    SimulatorType.prepar3dV5 => Icons.flight_land_rounded,
    SimulatorType.prepar3dV6 => Icons.flight_land_rounded,
  };

  static String _label(SimulatorType t, AppLocalizations l10n) => switch (t) {
    SimulatorType.xplane12 => l10n.simXplane12,
    SimulatorType.msfs2020 => l10n.simMsfs2020,
    SimulatorType.msfs2024 => l10n.simMsfs2024,
    SimulatorType.prepar3dV4 => l10n.simPrepar3dV4,
    SimulatorType.prepar3dV5 => l10n.simPrepar3dV5,
    SimulatorType.prepar3dV6 => l10n.simPrepar3dV6,
  };
}
