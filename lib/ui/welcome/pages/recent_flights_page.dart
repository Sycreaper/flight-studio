import 'package:flutter/material.dart';

import '../../../features/flights/flight_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../widgets/flight_card.dart';

/// Recent Flights page. Shows an empty-state CTA when there are no records,
/// otherwise a search field followed by a list of [FlightCard]s.
class RecentFlightsPage extends StatefulWidget {
  const RecentFlightsPage({
    super.key,
    required this.repository,
    this.onCreateFlight,
    this.onWorldMap,
    this.onFlightAcademy,
  });

  final FlightRepository repository;
  final VoidCallback? onCreateFlight;
  final VoidCallback? onWorldMap;
  final VoidCallback? onFlightAcademy;

  @override
  State<RecentFlightsPage> createState() => _RecentFlightsPageState();
}

class _RecentFlightsPageState extends State<RecentFlightsPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final v = _search.text;
      if (v != _query) setState(() => _query = v);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final all = widget.repository.all();
    final isEmpty = all.isEmpty;

    if (isEmpty) {
      return _EmptyState(
        title: l10n.createFirstFlight,
        onCreateFlight: widget.onCreateFlight,
        onWorldMap: widget.onWorldMap,
        onFlightAcademy: widget.onFlightAcademy,
      );
    }

    final results = _query.isEmpty ? all : widget.repository.search(_query);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchField(controller: _search),
        const SizedBox(height: 14),
        Expanded(
          child: results.isEmpty
              ? _Hint(text: l10n.noResults)
              : ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => FlightCard(
                    flight: results[i],
                    onTap: () {},
                  ),
                ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: l10n.searchFlights,
          prefixIcon: Icon(Icons.search_rounded,
              size: 18, color: colors.textSecondary),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: controller.clear,
                icon: Icon(Icons.close_rounded,
                    size: 16, color: colors.textSecondary),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    this.onCreateFlight,
    this.onWorldMap,
    this.onFlightAcademy,
  });

  final String title;
  final VoidCallback? onCreateFlight;
  final VoidCallback? onWorldMap;
  final VoidCallback? onFlightAcademy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flight_takeoff_rounded,
                  size: 56, color: colors.accent.withValues(alpha: 0.7)),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 28),
              // Three identical-sized action tiles. Wrap in an
              // [IntrinsicHeight] with `CrossAxisAlignment.stretch` so every
              // tile expands to match the tallest — and each tile also gets a
              // fixed `width` and `height` so they look uniform regardless of
              // how the hint text wraps in either language.
              Center(
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionTile(
                        icon: Icons.edit_note_rounded,
                        label: l10n.createFlight,
                        hint: l10n.createFlightHint,
                        onTap: onCreateFlight,
                      ),
                      const SizedBox(width: 16),
                      _ActionTile(
                        icon: Icons.public_rounded,
                        label: l10n.worldMap,
                        hint: l10n.worldMapHint,
                        onTap: onWorldMap,
                      ),
                      const SizedBox(width: 16),
                      _ActionTile(
                        icon: Icons.school_rounded,
                        label: l10n.flightAcademy,
                        hint: l10n.flightAcademyHint,
                        onTap: onFlightAcademy,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback? onTap;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          width: 168,
          // Fixed height so all three tiles line up even if the hint text
          // wraps differently per language.
          height: 168,
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: _hovering
                ? colors.accent.withValues(alpha: 0.10)
                : colors.surfaceRaised,
            border: Border.all(
              color: _hovering ? colors.accent : colors.border,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size: 30,
                  color: _hovering ? colors.accent : colors.textPrimary),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _hovering ? colors.accent : colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                widget.hint,
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Text(text, style: TextStyle(fontSize: 13, color: colors.textDisabled)),
    );
  }
}
