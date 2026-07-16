import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

/// The center card for a Flight Plan tab: a sticky summary header plus the
/// scrollable route-building form. The surrounding workspace (drawers, docks,
/// sizes) is owned by the app shell and shared across all tabs, so switching
/// tabs only swaps this center — drawer layout and state are preserved.
class FlightPlanFormTab extends StatefulWidget {
  const FlightPlanFormTab({super.key});

  @override
  State<FlightPlanFormTab> createState() => _FlightPlanFormTabState();
}

class _FlightPlanFormTabState extends State<FlightPlanFormTab> {
  final _aircraft = TextEditingController();
  final _airframe = TextEditingController();
  final _airline = TextEditingController();
  final _flightNumber = TextEditingController();
  final _callsign = TextEditingController();
  final _departure = TextEditingController();
  final _destination = TextEditingController();
  final _alternate = TextEditingController();
  final _cruiseLevel = TextEditingController();
  final _costIndex = TextEditingController();
  final _route = TextEditingController();
  final _contingency = TextEditingController();
  final _reserve = TextEditingController();
  final _taxiFuel = TextEditingController();
  final _extraFuel = TextEditingController();
  final _sid = TextEditingController();
  final _star = TextEditingController();
  final _approach = TextEditingController();

  String _units = 'kg';
  String _planDetail = 'detailed';

  @override
  void dispose() {
    for (final c in [
      _aircraft,
      _airframe,
      _airline,
      _flightNumber,
      _callsign,
      _departure,
      _destination,
      _alternate,
      _cruiseLevel,
      _costIndex,
      _route,
      _contingency,
      _reserve,
      _taxiFuel,
      _extraFuel,
      _sid,
      _star,
      _approach,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StickyHeader(
          departure: _departure,
          destination: _destination,
          aircraft: _aircraft,
          onCalculate: () {},
          onReset: _reset,
        ),
        Expanded(child: _buildFormBody(l10n)),
      ],
    );
  }

  Widget _buildFormBody(AppLocalizations l10n) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Section(
                title: l10n.sectionFlightInfo,
                children: [
                  _FieldRow([
                    _Field(l10n.fieldAircraft, _aircraft,
                        hint: 'e.g. A320'),
                    _Field(l10n.fieldAirframe, _airframe,
                        hint: 'e.g. B-32DK'),
                  ]),
                  _FieldRow([
                    _Field(l10n.fieldAirline, _airline, hint: 'e.g. CSN'),
                    _Field(l10n.fieldFlightNumber, _flightNumber,
                        hint: 'e.g. 3101'),
                    _Field(l10n.fieldCallsign, _callsign,
                        hint: 'e.g. CHINA SOUTH'),
                  ]),
                ],
              ),
              _Section(
                title: l10n.sectionRoute,
                children: [
                  _FieldRow([
                    _Field(l10n.fieldDeparture, _departure,
                        hint: 'ICAO', caps: true),
                    _Field(l10n.fieldDestination, _destination,
                        hint: 'ICAO', caps: true),
                    _Field(l10n.fieldAlternate, _alternate,
                        hint: 'ICAO', caps: true),
                  ]),
                  _FieldRow([
                    _Field(l10n.fieldCruiseLevel, _cruiseLevel,
                        hint: 'e.g. 350'),
                    _Field(l10n.fieldCostIndex, _costIndex,
                        hint: 'e.g. 60'),
                  ]),
                  _Field(l10n.fieldRoute, _route,
                      hint: 'e.g. SID GWD V609 ETO STAR', maxLines: 3),
                ],
              ),
              _Section(
                title: l10n.sectionProcedures,
                children: [
                  _FieldRow([
                    _Field(l10n.fieldSid, _sid, hint: 'SID name'),
                    _Field(l10n.fieldStar, _star, hint: 'STAR name'),
                    _Field(l10n.fieldApproach, _approach, hint: 'e.g. ILS23'),
                  ]),
                ],
              ),
              _Section(
                title: l10n.sectionPerformance,
                children: [
                  _FieldRow([
                    _Field(l10n.fieldContingency, _contingency, hint: '%'),
                    _Field(l10n.fieldReserve, _reserve, hint: 'min'),
                    _Field(l10n.fieldTaxiFuel, _taxiFuel, hint: 'kg'),
                    _Field(l10n.fieldExtraFuel, _extraFuel, hint: 'kg'),
                  ]),
                  const SizedBox(height: 8),
                  _SegmentedRow(
                    label: l10n.fieldUnits,
                    value: _units,
                    labels: [l10n.unitsKg, l10n.unitsLb],
                    onTap: (i) =>
                        setState(() => _units = i == 0 ? 'kg' : 'lb'),
                    selectedIndex: _units == 'kg' ? 0 : 1,
                  ),
                  const SizedBox(height: 8),
                  _SegmentedRow(
                    label: l10n.fieldPlanDetail,
                    value: _planDetail,
                    labels: [l10n.detailFull, l10n.detailRouteOnly],
                    onTap: (i) => setState(
                        () => _planDetail = i == 0 ? 'detailed' : 'route'),
                    selectedIndex: _planDetail == 'detailed' ? 0 : 1,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reset() {
    for (final c in [
      _aircraft,
      _airframe,
      _airline,
      _flightNumber,
      _callsign,
      _departure,
      _destination,
      _alternate,
      _cruiseLevel,
      _costIndex,
      _route,
      _contingency,
      _reserve,
      _taxiFuel,
      _extraFuel,
      _sid,
      _star,
      _approach,
    ]) {
      c.clear();
    }
    setState(() {
      _units = 'kg';
      _planDetail = 'detailed';
    });
  }
}

/// Sticky summary bar pinned to the top of the form.
class _StickyHeader extends StatelessWidget {
  const _StickyHeader({
    required this.departure,
    required this.destination,
    required this.aircraft,
    required this.onCalculate,
    required this.onReset,
  });

  final TextEditingController departure;
  final TextEditingController destination;
  final TextEditingController aircraft;
  final VoidCallback onCalculate;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(10),
        ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge(
                  [departure, destination, aircraft]),
              builder: (context, _) {
                final dep = departure.text.trim();
                final dst = destination.text.trim();
                final ac = aircraft.text.trim();
                final route = (dep.isEmpty && dst.isEmpty)
                    ? '\u2014 \u2192 \u2014'
                    : '${dep.isEmpty ? '\u2014' : dep} \u2192 ${dst.isEmpty ? '\u2014' : dst}';
                return Row(
                  children: [
                    Text(
                      route,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ac.isEmpty ? 'Aircraft \u2014' : ac,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.accent,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          FilledButton.icon(
            onPressed: onCalculate,
            icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
            label: Text(l10n.calculatePlan),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt_rounded, size: 16),
            label: Text(l10n.resetForm),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.accent,
              side: BorderSide(color: colors.accent, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: colors.accent,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i < children.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.controller,
      {this.hint, this.maxLines = 1, this.caps = false});
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final bool caps;

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
        TextField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: caps
              ? TextCapitalization.characters
              : TextCapitalization.none,
          decoration: InputDecoration(
            hintText: hint,
            alignLabelWithHint: maxLines > 1,
          ),
        ),
      ],
    );
  }
}

class _SegmentedRow extends StatelessWidget {
  const _SegmentedRow({
    required this.label,
    required this.value,
    required this.labels,
    required this.onTap,
    required this.selectedIndex,
  });

  final String label;
  final String value;
  final List<String> labels;
  final void Function(int index) onTap;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        SizedBox(
          width: 110,
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
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceLowered,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              children: [
                for (int i = 0; i < labels.length; i++) ...[
                  Expanded(
                    child: _Seg(
                      label: labels[i],
                      selected: i == selectedIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
                  if (i < labels.length - 1) const SizedBox(width: 2),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? colors.accent.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? colors.accent : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
