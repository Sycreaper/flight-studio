import '../../plugins/extension_registry.dart';
import '../db/database.dart';
import '../settings/simulator_install.dart';
import 'importer.dart';

/// Seam for "where does navigation data come from" — one implementation per
/// source (X-Plane 12 install today; OurAirports downloads, Navigraph OAuth
/// and third-party sources later).
///
/// A provider discovers its data on the user's machine, streams it into the
/// shared navdata database through the injected [NavdataImporter], and reports
/// normalized progress (0.0–1.0) for the status-bar task.
abstract class NavdataProvider {
  /// Stable registry id (e.g. `'xplane12'`).
  String get id;

  /// Human-readable source name for UI lists.
  String get displayName;

  /// Whether this provider can import for [install].
  bool canImport(SimulatorInstall install);

  /// Imports (or re-imports) the provider's data. [db] is already open and
  /// cleared; [importer] supplies file-discovery and bulk-insert helpers.
  Future<void> importInto(
    NavdataDatabase db,
    NavdataImporter importer,
    SimulatorInstall install, {
    void Function(double progress, String message)? onProgress,
  });
}

/// Registry of navdata sources. Lookup is capability-based
/// ([NavdataProvider.canImport]) — never an enum gate.
class NavdataProviderRegistry extends ExtensionRegistry<NavdataProvider> {
  NavdataProviderRegistry() : super(idOf: (p) => p.id);

  /// Finds a provider able to import [install]'s navdata, if any.
  NavdataProvider? forInstall(SimulatorInstall install) =>
      first((p) => p.canImport(install));

  static final NavdataProviderRegistry instance = NavdataProviderRegistry();
}
