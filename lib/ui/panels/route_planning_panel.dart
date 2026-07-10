import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/collapsible_panel.dart';

/// Left drawer: flight-plan input form. The user builds a route here by entering
/// departure/destination, cruise altitude, route type and procedures, then the
/// engine produces the route that renders on the map.
class RoutePlanningPanel extends StatefulWidget {
  const RoutePlanningPanel({super.key});

  @override
  State<RoutePlanningPanel> createState() => _RoutePlanningPanelState();
}

class _RoutePlanningPanelState extends State<RoutePlanningPanel> {
  final _departure = TextEditingController();
  final _destination = TextEditingController();
  final _cruiseAlt = TextEditingController();
  String _routeType = 'Airways';
  bool _includeSid = true;
  bool _includeStar = true;

  @override
  void dispose() {
    _departure.dispose();
    _destination.dispose();
    _cruiseAlt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabeledField(
          label: 'Departure',
          child: TextField(
            controller: _departure,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'ICAO e.g. KSEA'),
          ),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          label: 'Destination',
          child: TextField(
            controller: _destination,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'ICAO e.g. KSFO'),
          ),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          label: 'Cruise altitude (ft)',
          child: TextField(
            controller: _cruiseAlt,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'e.g. 35000'),
          ),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          label: 'Route type',
          child: _SegmentedControl(
            value: _routeType,
            options: const ['Airways', 'Direct', 'Navaids'],
            onChanged: (v) => setState(() => _routeType = v),
          ),
        ),
        const SizedBox(height: 12),
        _SwitchRow(
          label: 'Include SID',
          value: _includeSid,
          onChanged: (v) => setState(() => _includeSid = v),
        ),
        _SwitchRow(
          label: 'Include STAR',
          value: _includeStar,
          onChanged: (v) => setState(() => _includeStar = v),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
          label: const Text('Calculate route'),
        ),
        const SizedBox(height: 16),
        CollapsiblePanel(
          title: 'Route Legs',
          isExpanded: false,
          onToggle: () {},
          scrollable: false,
          child: const _EmptyHint(text: 'No route yet — calculate to populate.'),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: colors.textSecondary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowered,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: options.map((opt) {
          final selected = opt == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? colors.accent.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? colors.accent : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 12, color: colors.textDisabled),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
