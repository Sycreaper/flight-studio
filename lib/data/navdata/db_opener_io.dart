import 'dart:io';

import 'package:drift/native.dart';

import '../db/database.dart';

/// Opens (or creates) the navdata SQLite database at [path] on a background
/// isolate. Native platforms only — see `db_opener.dart`.
NavdataDatabase openNavdataDatabase(String path) {
  return NavdataDatabase(NativeDatabase.createInBackground(File(path)));
}
