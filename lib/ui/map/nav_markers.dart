import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/navdata/navdata_types.dart';
import '../../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Builds a flutter_map [MarkerLayer] from a list of [NavPoint]s whose
/// category is currently visible.
///
/// Each marker is Little Navmap's own SVG icon ([NavPoint.svgAsset]). Hovering
/// shows a tooltip with ident, name and frequency — there are no nameplates
/// under the icons. Double-tapping a marker reports it to [onInspect] (the
/// inspector drawer).
MarkerLayer buildNavMarkerLayer(
  BuildContext context,
  List<NavPoint> points,
    Set<NavPointCategory> visible, {
      ValueChanged<NavPoint>? onInspect,
    }) {
  final markers = <Marker>[];
  for (final point in points) {
    if (!visible.contains(point.category)) continue;
    markers.add(
      Marker(
        point: LatLng(point.latitude, point.longitude),
        child: _NavMarker(point: point, onInspect: onInspect),
      ),
    );
  }
  return MarkerLayer(markers: markers);
}

class _NavMarker extends StatelessWidget {
  const _NavMarker({required this.point, this.onInspect});

  final NavPoint point;
  final ValueChanged<NavPoint>? onInspect;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${point.ident} — ${point.name}'
          '${point.frequency != null ? '\n${point.frequency}' : ''}',
      preferBelow: false,
      child: GestureDetector(
        // Double-tap opens the inspector (single taps fall through to the
        // map); claiming the double-tap here also keeps the map's own
        // double-tap-zoom from firing on markers.
        onDoubleTap: onInspect == null
            ? null
            : () => onInspect!(point),
        child: SizedBox(
          width: 22,
          height: 22,
          child: SvgPicture.asset(point.svgAsset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Localized display name for a nav category — shared by the legend bar and
/// the inspector's type row.
String navCategoryLabel(AppLocalizations l10n, NavPointCategory cat) =>
    switch (cat) {
      NavPointCategory.airport => l10n.legendAirport,
      NavPointCategory.vor => l10n.legendVor,
      NavPointCategory.vordme => l10n.legendVordme,
      NavPointCategory.vortac => l10n.legendVortac,
      NavPointCategory.tacan => l10n.legendTacan,
      NavPointCategory.dme => l10n.legendDme,
      NavPointCategory.ndb => l10n.legendNdb,
      NavPointCategory.waypoint => l10n.legendWaypoint,
      NavPointCategory.ils => l10n.legendIls,
      NavPointCategory.gs => l10n.legendGs,
      NavPointCategory.marker => l10n.legendMarker,
    };

/// Horizontal legend / filter bar below the Map toolbar. One toggle per
/// navaid category — clicking shows/hides that category's markers. Icons are
/// the same LNM SVGs the markers use.
class NavLegendBar extends StatelessWidget {
  const NavLegendBar({
    super.key,
    required this.visible,
    required this.onToggle,
    this.wrap = false,
    this.enabled = true,
  });

  final Set<NavPointCategory> visible;
  final ValueChanged<NavPointCategory> onToggle;

  /// When `true`, toggles flow onto multiple lines instead of scrolling —
  /// used by the search drawer where the narrow width would otherwise cut
  /// the row off and the scrollbar would show as a dark strip.
  final bool wrap;

  /// When `false` the bar stays visible but is non-interactive: clicks are
  /// swallowed, hover shows the OS "forbidden" cursor and contents are
  /// dimmed — the native disabled-control feel.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final toggles = <Widget>[
      for (final cat in NavPointCategory.values)
        _LegendToggle(
          category: cat,
          active: visible.contains(cat),
          colors: colors,
          onTap: () => onToggle(cat),
        ),
    ];

    Widget bar;
    if (wrap) {
      bar = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Wrap(spacing: 6, runSpacing: 4, children: toggles),
      );
    } else {
      bar = Container(
        height: 36,
        decoration: BoxDecoration(color: colors.chrome),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < toggles.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                toggles[i],
              ],
            ],
          ),
        ),
      );
    }

    if (!enabled) {
      return MouseRegion(
        cursor: SystemMouseCursors.forbidden,
        child: IgnorePointer(
          child: Opacity(opacity: 0.5, child: bar),
        ),
      );
    }
    return bar;
  }
}

class _LegendToggle extends StatelessWidget {
  const _LegendToggle({
    required this.category,
    required this.active,
    required this.colors,
    required this.onTap,
  });

  final NavPointCategory category;
  final bool active;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final iconColor = active
        ? navCategoryColor(category, colors)
        : colors.textDisabled;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active
                ? navCategoryColor(category, colors).withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active
                  ? navCategoryColor(category, colors)
                  : colors.border,
              width: active ? 1.2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 15,
                height: 15,
                child: SvgPicture.asset(
                  _svgAsset,
                  fit: BoxFit.contain,
                  // Recolour the LNM icon to the category colour so legend
                  // states read clearly; originals are multi-tone.
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _label(l10n),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? navCategoryColor(category, colors)
                      : colors.textDisabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(AppLocalizations l10n) => navCategoryLabel(l10n, category);

  String get _svgAsset => switch (category) {
    NavPointCategory.airport => 'assets/icons/map/airport.svg',
    NavPointCategory.vor => 'assets/icons/map/vor.svg',
    NavPointCategory.vordme => 'assets/icons/map/userpoint_VORDME.svg',
    NavPointCategory.vortac => 'assets/icons/map/userpoint_VORTAC.svg',
    NavPointCategory.tacan => 'assets/icons/map/userpoint_TACAN.svg',
    NavPointCategory.dme => 'assets/icons/map/userpoint_DME.svg',
    NavPointCategory.ndb => 'assets/icons/map/ndb.svg',
    NavPointCategory.waypoint => 'assets/icons/map/waypoint.svg',
    NavPointCategory.ils => 'assets/icons/map/ils.svg',
    NavPointCategory.gs => 'assets/icons/map/loc.svg',
    NavPointCategory.marker => 'assets/icons/map/userpoint_Marker.svg',
  };

  Color navCategoryColor(NavPointCategory cat, AppColors colors) =>
      switch (cat) {
        NavPointCategory.airport => colors.accent,
        NavPointCategory.vor ||
        NavPointCategory.vordme ||
        NavPointCategory.vortac ||
        NavPointCategory.tacan ||
        NavPointCategory.dme => colors.success,
        NavPointCategory.ndb => colors.warning,
        NavPointCategory.waypoint => colors.textPrimary,
        NavPointCategory.ils ||
        NavPointCategory.gs ||
        NavPointCategory.marker => colors.danger,
      };
}
