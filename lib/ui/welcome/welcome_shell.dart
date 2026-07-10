import 'package:flutter/material.dart';

import '../../features/flights/flight_repository.dart';
import '../../l10n/app_localizations.dart';
import '../shell/app_shell.dart';
import '../theme/app_colors.dart';
import 'pages/page_placeholder.dart';
import 'pages/recent_flights_page.dart';
import 'widgets/welcome_nav_drawer.dart';

/// The welcome/home screen. A fixed left nav drawer (card style, non-collapsible)
/// plus a borderless content area that swaps between the recent-flights,
/// plugin-center and settings pages.
class WelcomeShell extends StatefulWidget {
  const WelcomeShell({
    super.key,
    required this.repository,
    this.onCreateFlight,
    this.onFlightAcademy,
  });

  final FlightRepository repository;
  final VoidCallback? onCreateFlight;
  final VoidCallback? onFlightAcademy;

  @override
  State<WelcomeShell> createState() => _WelcomeShellState();
}

class _WelcomeShellState extends State<WelcomeShell> {
  WelcomeSection _section = WelcomeSection.recentFlights;

  void _openMainPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 264,
              child: WelcomeNavDrawer(
                selected: _section,
                onSelect: (s) => setState(() => _section = s),
                onOpenSettings: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildContent(l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
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
      case WelcomeSection.settings:
        return PagePlaceholder(
          icon: Icons.tune_rounded,
          title: l10n.settingsTitle,
          description: l10n.settingsDesc,
        );
    }
  }
}
