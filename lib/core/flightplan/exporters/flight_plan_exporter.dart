import '../../../plugins/extension_registry.dart';

/// One route waypoint handed to an exporter.
///
/// Deliberately minimal — Phase 3's full flight-plan model will replace this
/// value type without changing the [FlightPlanExporter] seam itself.
class ExportRoutePoint {
  const ExportRoutePoint({
    this.ident,
    required this.latitude,
    required this.longitude,
    this.altitudeFt,
  });

  final String? ident;
  final double latitude;
  final double longitude;
  final double? altitudeFt;
}

/// The plan payload exporters consume.
class ExportableFlightPlan {
  const ExportableFlightPlan({
    this.title = 'Flight Plan',
    this.departure,
    this.arrival,
    this.cruiseAltitudeFt,
    this.aircraftIcao,
    this.waypoints = const [],
  });

  final String title;
  final String? departure;
  final String? arrival;
  final double? cruiseAltitudeFt;
  final String? aircraftIcao;
  final List<ExportRoutePoint> waypoints;
}

/// Seam for turning a flight plan into a simulator-ready file — one
/// implementation per format (FMS 11, PLN, FLP, GPX, ...). Built-in formats
/// register in Phase 3; third-party plugins can register their own.
abstract class FlightPlanExporter {
  /// Stable registry id (e.g. `'fms11'`, `'pln'`, `'gpx'`).
  String get formatId;

  /// Human-readable format name shown in export menus.
  String get displayName;

  /// File extensions this format owns, lowercase without dots (`['fms']`).
  List<String> get fileExtensions;

  /// Serialises [plan]; returns the encoded file bytes.
  Future<List<int>> export(ExportableFlightPlan plan);
}

/// Registry of export formats. Lookup goes by [FlightPlanExporter.formatId]
/// or by owned file extension — never by enum/switch.
class ExporterRegistry extends ExtensionRegistry<FlightPlanExporter> {
  ExporterRegistry() : super(idOf: (e) => e.formatId);

  /// Finds the exporter that owns [fileExtension] (case-insensitive).
  FlightPlanExporter? forExtension(String fileExtension) {
    final ext = fileExtension.toLowerCase();
    return first((e) => e.fileExtensions.contains(ext));
  }

  static final ExporterRegistry instance = ExporterRegistry();
}
