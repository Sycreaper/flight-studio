/// LNM-style airport detail payload for the inspector drawer — the airport
/// row plus its runways and ATC frequencies, fetched on demand from the
/// navdata database.
class AirportDetails {
  const AirportDetails({
    required this.icao,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.iata,
    this.city,
    this.country,
    this.elevationFt,
    this.magvarDeg,
    required this.type,
    required this.source,
    this.runways = const [],
    this.frequencies = const [],
    this.runwayStripCount = 0,
    this.longestRunway,
  });

  final String icao;
  final String? iata;
  final String name;
  final String? city;
  final String? country;
  final double latitude;
  final double longitude;
  final double? elevationFt;

  /// Magnetic declination in degrees (apt.dat row 1 field 3, deprecated by
  /// X-Plane but still populated by many datasets).
  final double? magvarDeg;

  /// `'airport' | 'heliport' | 'seaplane'`.
  final String type;

  /// Where the data came from (`'xplane' | 'ourairports' | 'navigraph'`) —
  /// LNM's "Data source" line.
  final String source;
  final List<RunwayDetails> runways;
  final List<FrequencyDetails> frequencies;

  /// Number of physical runway strips (LNM's runway count).
  final int runwayStripCount;

  /// The longest strip, or `null` when the airport has none (LNM's "longest
  /// runway" line).
  final RunwayDetails? longestRunway;
}

/// Groups runway ENDS into physical strips by [RunwayDetails.stripIndex];
/// untagged ends (pre-v3 data) each stand alone. Order preserved — shared by
/// the importer's longest-runway computation and the inspector UI.
List<List<RunwayDetails>> groupRunwayStrips(List<RunwayDetails> ends) {
  final groups = <int?, List<RunwayDetails>>{};
  for (final end in ends) {
    groups.putIfAbsent(end.stripIndex, () => []).add(end);
  }
  return groups.values.toList();
}

/// One runway END of an [AirportDetails] — ends sharing a [stripIndex] form
/// a physical strip and are displayed as `16L/34R` in the inspector.
class RunwayDetails {
  const RunwayDetails({
    required this.ident,
    required this.headingDeg,
    required this.lengthFt,
    this.widthFt,
    this.surface,
    this.stripIndex,
  });

  final String ident;

  /// True heading in degrees (from this end's threshold).
  final double headingDeg;
  final double lengthFt;
  final double? widthFt;

  /// `'asphalt' | 'concrete' | 'grass' | ...` (as stored from apt.dat).
  final String? surface;

  /// Physical strip both ends of a pair belong to (see Runways table).
  final int? stripIndex;
}

/// One ATC frequency of an [AirportDetails] (from apt.dat rows 50–56).
class FrequencyDetails {
  const FrequencyDetails({
    required this.type,
    required this.frequencyKhz,
    this.description,
  });

  /// `'ATIS' | 'CTAF' | 'GND' | 'TWR' | 'CLD' | 'APP' | 'DEP'`.
  final String type;
  final int frequencyKhz;

  /// Free-text station name from the apt.dat row (often empty).
  final String? description;

  /// kHz → MHz display string, e.g. `119500` → `'119.50'`.
  String get mhz {
    final value = frequencyKhz / 1000.0;
    var text = value.toStringAsFixed(3);
    // Trim to two decimals (X-Plane apt.dat precision), e.g. 121.900 → 121.90.
    if (text.endsWith('0')) text = text.substring(0, text.length - 1);
    return text;
  }
}
