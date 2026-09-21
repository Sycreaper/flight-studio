import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geo/geo_math.dart';
import '../../../core/geo/sun_times.dart';
import '../../../core/navdata/navdata_types.dart';
import '../../../core/weather/metar_decoder.dart';
import '../../../data/navdata/airport_details.dart';
import '../../../data/navdata/navdata_service.dart';
import '../../../data/weather/weather_service.dart';
import '../../../l10n/app_localizations.dart';
import '../map/nav_markers.dart';
import '../theme/app_colors.dart';
import 'inspector_service.dart';

/// Right drawer: LNM-style information dock for the currently inspected nav
/// point (set by double-clicking a map marker or a search result).
///
/// Airports get five native [TabBar] tabs — Overview / Runways / Comms /
/// METAR / TAF (active label in accent colour with an accent underline).
/// Weather tables decode the raw reports into the same label/value fact-row
/// style, with the raw source text underneath. Non-airport points keep a
/// plain fact sheet.
class InspectorPanel extends StatefulWidget {
  const InspectorPanel({super.key, this.onFlyTo});

  /// Called with the inspected point's coordinates when the user presses the
  /// fly-to action. `null` hides the action (e.g. in tests).
  final ValueChanged<LatLng>? onFlyTo;

  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  /// Extra airport facts (incl. runways + ATC frequencies) for the inspected
  /// airport, fetched from the database on selection. `null` for
  /// non-airports / unknown ids.
  AirportDetails? _airport;

  /// Live weather (METAR/TAF) for the inspected airport, fetched online.
  AirportWeather? _weather;
  bool _weatherLoading = false;

  @override
  void initState() {
    super.initState();
    InspectorService.instance.addListener(_onInspected);
    _loadAirportDetails(InspectorService.instance.point);
    _loadWeather(InspectorService.instance.point);
  }

  @override
  void dispose() {
    InspectorService.instance.removeListener(_onInspected);
    super.dispose();
  }

  void _onInspected() {
    if (!mounted) return;
    final point = InspectorService.instance.point;
    setState(() {
      _airport = null;
      _weather = null;
      _weatherLoading = false;
    });
    _loadAirportDetails(point);
    _loadWeather(point);
  }

  Future<void> _loadAirportDetails(NavPoint? point) async {
    if (point == null || point.category != NavPointCategory.airport) return;
    final details =
    await NavdataService.instance.queryAirportDetails(point.ident);
    // Ignore a stale response (selection changed while the query ran).
    if (!mounted ||
        !identical(InspectorService.instance.point, point)) {
      return;
    }
    setState(() => _airport = details);
  }

  /// Online weather (free NOAA feed) — airports only, best-effort.
  Future<void> _loadWeather(NavPoint? point) async {
    if (point == null || point.category != NavPointCategory.airport) return;
    setState(() => _weatherLoading = true);
    final weather = await WeatherService.instance.fetch(point.ident);
    if (!mounted ||
        !identical(InspectorService.instance.point, point)) {
      return;
    }
    setState(() {
      _weather = weather;
      _weatherLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final point = InspectorService.instance.point;
    if (point == null) return const _InspectorHint();
    return _InspectorDetails(
      point: point,
      airport: _airport,
      weather: _weather,
      weatherLoading: _weatherLoading,
      onFlyTo: widget.onFlyTo,
    );
  }
}

/// Empty state — explains how to inspect something.
class _InspectorHint extends StatelessWidget {
  const _InspectorHint();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 32,
              color: colors.textDisabled,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.inspectorHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header + tabbed content for one inspected point.
class _InspectorDetails extends StatelessWidget {
  const _InspectorDetails({
    required this.point,
    required this.airport,
    required this.weatherLoading,
    this.weather,
    this.onFlyTo,
  });

  final NavPoint point;
  final AirportDetails? airport;
  final AirportWeather? weather;
  final bool weatherLoading;
  final ValueChanged<LatLng>? onFlyTo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final isAirport = point.category == NavPointCategory.airport;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header: icon + ident + name + actions ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 0),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(point.svgAsset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      point.ident,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      point.name,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onFlyTo != null)
                IconButton(
                  tooltip: l10n.inspectorFlyTo,
                  onPressed: () =>
                      onFlyTo!(
                          LatLng(point.latitude, point.longitude)),
                  icon: Icon(Icons.flight_takeoff_rounded,
                      size: 16, color: colors.accent),
                  constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              IconButton(
                tooltip: l10n.inspectorClear,
                onPressed: InspectorService.instance.clear,
                icon: Icon(Icons.close_rounded,
                    size: 15, color: colors.textSecondary),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        // ── Content: tabs for airports, plain fact sheet otherwise ────────
        Expanded(
          child: isAirport
              ? DefaultTabController(
            length: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicatorColor: colors.accent,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: colors.accent,
                  unselectedLabelColor: colors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: [
                    Tab(text: l10n.inspectorTabOverview),
                    Tab(text: l10n.inspectorRunways),
                    Tab(text: l10n.inspectorTabComms),
                    const Tab(text: 'METAR'),
                    const Tab(text: 'TAF'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OverviewTab(airport: airport, point: point),
                      _RunwaysTab(airport: airport),
                      _CommsTab(airport: airport),
                      _MetarTab(
                          weather: weather,
                          weatherLoading: weatherLoading),
                      _TafTab(
                          weather: weather,
                          weatherLoading: weatherLoading),
                    ],
                  ),
                ),
              ],
            ),
          )
              : _NavaidSheet(point: point),
        ),
      ],
    );
  }
}

/// Localized airport type (overview row).
String _airportTypeLabel(String type, AppLocalizations l10n) =>
    switch (type) {
      'heliport' => l10n.airportTypeHeliport,
      'seaplane' => l10n.airportTypeSeaplane,
      _ => l10n.airportTypeAirport,
    };

/// Brand-name data source label (overview row).
String _sourceLabel(String source) =>
    switch (source) {
      'xplane' => 'X-Plane',
      'ourairports' => 'OurAirports',
      'navigraph' => 'Navigraph',
      _ => source,
    };

/// `3,928 m × 60 m · asphalt` — metres, same format as the runways tab.
String _longestRunwayText(RunwayDetails runway) {
  String meters(double ft) =>
      (ft * 0.3048).round().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
      );
  final dims = runway.widthFt != null
      ? '${meters(runway.lengthFt)} m × ${meters(runway.widthFt!)} m'
      : '${meters(runway.lengthFt)} m';
  final surface = runway.surface;
  final surfaceText =
  (surface == null || surface.isEmpty) ? '' : ' · $surface';
  return '$dims$surfaceText';
}

/// Fact sheet for non-airport points (navaids, waypoints) — no tabs.
class _NavaidSheet extends StatelessWidget {
  const _NavaidSheet({required this.point});

  final NavPoint point;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coords =
        '${formatLatDMS(point.latitude)} ${formatLonDMS(point.longitude)}';
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: [
        _FactRow(
            label: l10n.inspectorType,
            value: navCategoryLabel(l10n, point.category)),
        _FactRow(label: l10n.inspectorCoordinates, value: coords),
        _FactRow(label: '',
            value: '${point.latitude.toStringAsFixed(5)}, ${point.longitude
                .toStringAsFixed(5)}',
            muted: true),
        if (point.frequency != null)
          _FactRow(label: l10n.inspectorFrequency, value: point.frequency!),
        if (point.elevationFt != null)
          _FactRow(
            label: l10n.inspectorElevation,
            value:
            '${point.elevationFt} ft / ${(point.elevationFt! * 0.3048)
                .round()} m',
          ),
      ],
    );
  }
}

// ── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.airport, required this.point});

  final AirportDetails? airport;
  final NavPoint point;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = airport;
    final na = l10n.inspectorNotAvailable;
    final sun = computeSunTimes(point.latitude, point.longitude);
    String sunText = na;
    if (sun.sunrise != null && sun.sunset != null) {
      String hm(DateTime t) =>
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(
              2, '0')}';
      sunText = '${hm(sun.sunrise!)} / ${hm(sun.sunset!)} UTC';
    }
    final magvar = a?.magvarDeg;
    final magvarText = magvar == null
        ? na
        : '${magvar > 0 ? '+' : ''}${magvar.toStringAsFixed(1)}°';
    // Prefer the DB row; fall back to the NavPoint's own elevation when the
    // database has no details for this airport (e.g. before an import).
    final elevationFt = a?.elevationFt ?? point.elevationFt?.toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: [
        _FactRow(label: l10n.inspectorIcao, value: a?.icao ?? point.ident),
        _FactRow(label: l10n.inspectorIata, value: a?.iata ?? na),
        _FactRow(label: l10n.inspectorXplaneIdent, value: a?.icao ?? na),
        _FactRow(
          label: l10n.inspectorType,
          value: a == null ? na : _airportTypeLabel(a.type, l10n),
        ),
        _FactRow(
          label: l10n.inspectorDataSource,
          value: a == null ? na : _sourceLabel(a.source),
        ),
        // Region = first two ICAO letters (e.g. ZSQD → ZS), LNM-style.
        _FactRow(
          label: l10n.inspectorRegion,
          value: (a?.icao ?? point.ident).length >= 2
              ? (a?.icao ?? point.ident).substring(0, 2)
              : na,
        ),
        _FactRow(label: l10n.inspectorCity, value: a?.city ?? na),
        _FactRow(label: l10n.inspectorCountry, value: a?.country ?? na),
        _FactRow(
          label: l10n.inspectorElevation,
          value: elevationFt == null
              ? na
              : '${elevationFt.round()} ft / ${(elevationFt * 0.3048)
              .round()} m',
        ),
        _FactRow(label: l10n.inspectorMagvar, value: magvarText),
        _FactRow(
          label: l10n.inspectorRunwayCount,
          value: a == null ? na : '${a.runwayStripCount}',
        ),
        _FactRow(
          label: l10n.inspectorLongestRunway,
          value: a?.longestRunway == null
              ? na
              : _longestRunwayText(a!.longestRunway!),
        ),
        _FactRow(label: l10n.inspectorSunTimes, value: sunText),
        _FactRow(
          label: l10n.inspectorCoordinates,
          value:
          '${formatLatDMS(point.latitude)} ${formatLonDMS(point.longitude)}',
        ),
        _FactRow(
          label: '',
          value:
          '${point.latitude.toStringAsFixed(5)}, ${point.longitude
              .toStringAsFixed(5)}',
          muted: true,
        ),
      ],
    );
  }
}

// ── Runways tab ──────────────────────────────────────────────────────────────

class _RunwaysTab extends StatelessWidget {
  const _RunwaysTab({required this.airport});

  final AirportDetails? airport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final strips = airport == null || airport!.runways.isEmpty
        ? const <List<RunwayDetails>>[]
        : groupRunwayStrips(airport!.runways);
    if (strips.isEmpty) {
      return _NotAvailable(text: l10n.inspectorNotAvailable);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: [
        for (final strip in strips) _RunwayRow(strip: strip),
      ],
    );
  }
}

// ── Comms tab ────────────────────────────────────────────────────────────────

class _CommsTab extends StatelessWidget {
  const _CommsTab({required this.airport});

  final AirportDetails? airport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final freqs = airport?.frequencies ?? const <FrequencyDetails>[];
    if (freqs.isEmpty) {
      return _NotAvailable(text: l10n.inspectorNotAvailable);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: [
        for (final f in freqs) _FrequencyRow(frequency: f),
      ],
    );
  }
}

// ── Weather tabs (METAR / TAF) ───────────────────────────────────────────────

class _MetarTab extends StatelessWidget {
  const _MetarTab({required this.weather, required this.weatherLoading});

  final AirportWeather? weather;
  final bool weatherLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metar = weather?.metar;
    if (weatherLoading) return const _WeatherLoading();
    if (metar == null) {
      return _NotAvailable(text: l10n.inspectorWeatherUnavailable);
    }
    final locale = l10n.localeName;
    final texts = weatherTextsFor(locale);
    final decoded = decodeMetar(metar, localeName: locale);
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: [
        for (final fact in decoded.facts(texts))
          _FactRow(label: fact.label, value: fact.value),
        const SizedBox(height: 8),
        _RawTextBlock(text: metar, header: l10n.inspectorRawReport),
      ],
    );
  }
}

class _TafTab extends StatelessWidget {
  const _TafTab({required this.weather, required this.weatherLoading});

  final AirportWeather? weather;
  final bool weatherLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final taf = weather?.taf;
    if (weatherLoading) return const _WeatherLoading();
    if (taf == null) {
      return _NotAvailable(text: l10n.inspectorWeatherUnavailable);
    }
    final locale = l10n.localeName;
    final texts = weatherTextsFor(locale);
    final decoded = decodeTaf(taf, localeName: locale);
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: [
        for (final fact in decoded.facts(texts))
          _FactRow(label: fact.label, value: fact.value),
        const SizedBox(height: 8),
        _RawTextBlock(text: taf, header: l10n.inspectorRawReport),
        if (decoded.changeGroups.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final line in decoded.changeGroups)
            _RawTextBlock(text: line, header: line
                .split(' ')
                .first),
        ],
      ],
    );
  }
}

class _WeatherLoading extends StatelessWidget {
  const _WeatherLoading();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: colors.accent),
      ),
    );
  }
}

class _NotAvailable extends StatelessWidget {
  const _NotAvailable({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Text(
          text, style: TextStyle(fontSize: 12, color: colors.textDisabled)),
    );
  }
}

// ── Shared atoms ─────────────────────────────────────────────────────────────

/// One label/value line in the fact sheet.
class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: colors.textDisabled,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: muted ? colors.textSecondary : colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One ATC frequency line: `塔台  119.50 MHz · TOWER`.
class _FrequencyRow extends StatelessWidget {
  const _FrequencyRow({required this.frequency});

  final FrequencyDetails frequency;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final desc = frequency.description;
    final descText = (desc == null || desc.isEmpty) ? '' : ' · $desc';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Text(
              _freqTypeLabel(frequency.type, l10n),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.accent,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${frequency.mhz} MHz$descText',
              style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Localized ATC frequency kind (apt.dat rows 50–56); unknown codes fall
/// back to the raw value.
String _freqTypeLabel(String type, AppLocalizations l10n) =>
    switch (type) {
      'ATIS' => l10n.navFreqAtis,
      'CTAF' => l10n.navFreqCtaf,
      'GND' => l10n.navFreqGnd,
      'TWR' => l10n.navFreqTwr,
      'CLD' => l10n.navFreqCld,
      'APP' => l10n.navFreqApp,
      'DEP' => l10n.navFreqDep,
      _ => type,
    };

/// Monospace block for raw METAR / TAF reports.
class _RawTextBlock extends StatelessWidget {
  const _RawTextBlock({required this.text, this.header});

  final String text;
  final String? header;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Text(
              header!,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: colors.textDisabled,
              ),
            ),
          const SizedBox(height: 1),
          SelectableText(
            text,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.45,
              fontFamily: 'monospace',
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One runway STRIP line: `16L/34R · 158°/338° · 3,928 m × 60 m · asphalt`.
class _RunwayRow extends StatelessWidget {
  const _RunwayRow({required this.strip});

  /// The physical strip's ends, in stored (num1, num2) order.
  final List<RunwayDetails> strip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final first = strip.first;

    String meters(double ft) =>
        (ft * 0.3048).round().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
        );
    final dims = first.widthFt != null
        ? '${meters(first.lengthFt)} m × ${meters(first.widthFt!)} m'
        : '${meters(first.lengthFt)} m';

    final idents = strip.map((r) => r.ident).join('/');
    final headings =
    strip.map((r) => '${r.headingDeg.round()}°').join('/');
    final surface = first.surface;
    final surfaceText =
    (surface == null || surface.isEmpty) ? '' : ' · $surface';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(
              idents,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.accent,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$headings · $dims$surfaceText',
              style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
