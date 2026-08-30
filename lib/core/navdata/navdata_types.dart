/// Navigation data categories — every kind of navaid Flight Studio scans and
/// displays on the map. Mirrors Little Navmap's taxonomy (mapflags.h +
/// xpconstants.h) with the VOR family split into its subtypes:
///
/// - **VOR family** (earth_nav.dat type 3, classified by name suffix):
///   VOR, VOR/DME, VORTAC, TACAN — plus standalone DME (type 13).
/// - **ILS family**: ILS (4), LOC-only (5), GLS/GBAS (15), GS glideslope (6).
/// - **Markers**: OM (7), MM (8), IM (9) — grouped under [marker].
/// - **NDB** (2), **Waypoints** (earth_fix.dat), **Airports** (apt.dat).
enum NavPointCategory {
  airport,
  vor,
  vordme,
  vortac,
  tacan,
  dme,
  ndb,
  waypoint,
  ils,
  gs,
  marker,
}

/// A lightweight view-model for one navigational fixture on the map. Populated
/// from the Drift database (or a future in-memory cache) and consumed by the
/// map marker layer.
class NavPoint {
  const NavPoint({
    required this.category,
    required this.ident,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.frequency,
    this.elevationFt,
    this.runwayIdent,
  });

  final NavPointCategory category;
  final String ident;
  final String name;
  final double latitude;
  final double longitude;
  final String? frequency;
  final int? elevationFt;
  final String? runwayIdent;

  /// SVG asset path — Little Navmap's own map icons from
  /// `resources/icons/`, copied into `assets/icons/map/`.
  String get svgAsset => switch (category) {
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
}
