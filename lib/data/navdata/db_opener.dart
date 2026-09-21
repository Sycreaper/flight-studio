/// Conditional export: opens the Drift navdata database with the native
/// SQLite driver on platforms that have `dart:ffi` (desktop), or a throwing
/// stub on the web (where dart:ffi does not exist).
library;

export 'db_opener_stub.dart' if (dart.library.ffi) 'db_opener_io.dart';
