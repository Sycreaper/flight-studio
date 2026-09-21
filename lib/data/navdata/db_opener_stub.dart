import '../db/database.dart';

/// Web stub — the native SQLite driver requires `dart:ffi`, which does not
/// exist on the web. Navdata import/query is desktop-only; on the web the
/// importer simply never opens a database (all queries return empty).
NavdataDatabase openNavdataDatabase(String path) {
  throw UnsupportedError(
    'The navdata database requires a desktop platform (dart:ffi).',
  );
}
