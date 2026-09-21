import 'package:flutter/material.dart';

import '../../data/settings/settings_controller.dart';
import '../../features/flights/flight_repository.dart';
import '../../l10n/app_localizations.dart';
import '../adaptive/breakpoints.dart';
import '../shell/app_shell.dart';
import '../shell/window_chrome.dart';
import '../theme/app_colors.dart';
import 'pages/page_placeholder.dart';
import 'pages/recent_flights_page.dart';
import 'widgets/welcome_nav_drawer.dart';

/// The welcome/home screen. A fixed left nav drawer (card style, non-collapsible)
/// plus a borderless content area that swaps between the recent-flights and
/// plugin-center pages. Settings is intentionally NOT one of the swapped
/// pages — it lives in a floating window launched via the gear menu so the
/// entry point is identical on every screen.
class WelcomeShell extends StatefulWidget {
  const WelcomeShell({
    super.key,
    required this.repository,
    required this.settings,
    this.onCreateFlight,
    this.onFlightAcademy,
  });

  final FlightRepository repository;

  /// Injected only so it can be threaded into the [AppShell] when the user
  /// opens the world map; the welcome screen itself does not read settings.
  final SettingsController settings;
  final VoidCallback? onCreateFlight;
  final VoidCallback? onFlightAcademy;

  @override
  State<WelcomeShell> createState() => _WelcomeShellState();
}

class _WelcomeShellState extends State<WelcomeShell> {
  WelcomeSection _section = WelcomeSection.recentFlights;

  void _openMainPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppShell(settings: widget.settings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    // Narrow (phone): the card nav collapses to an icon-only rail; the
    // selected section's page fills everything else. Wide: unchanged.
    final narrow = isNarrowScreen(context);
    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: WindowDragArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (narrow) ...[
                WelcomeNavRail(
                  selected: _section,
                  onSelect: (s) => setState(() => _section = s),
                ),
                const SizedBox(width: 10),
              ] else
                ...[
                  SizedBox(
                    width: 264,
                    child: WelcomeNavDrawer(
                      selected: _section,
                      onSelect: (s) => setState(() => _section = s),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context)!;
    switch (_section) {
      case WelcomeSection.recentFlights:
        return RecentFlightsPage(
          repository: widget.repository,
          onCreateFlight: widget.onCreateFlight,
          onWorldMap: _openMainPage,
          onFlightAcademy: widget.onFlightAcademy,
        );
      case WelcomeSection.pluginCenter:
        return PagePlaceholder(
          icon: Icons.extension_rounded,
          title: l10n.pluginCenterTitle,
          description: l10n.pluginCenterDesc,
        );
    }
  }
}
