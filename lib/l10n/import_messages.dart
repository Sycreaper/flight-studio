/// Locale-aware navdata import progress messages.
///
/// The parsers/importer live below the widget layer (no `BuildContext`), so
/// the app records the resolved UI locale here once at startup (main.dart);
/// every progress callback reads through these getters. Chinese when the
/// locale starts with `'zh'`, English otherwise.
abstract final class ImportMessages {
  static String localeName = 'en';

  static bool get _zh => localeName.startsWith('zh');

  static String get clearingDatabase => _zh ? '正在清空数据库…' : 'Clearing database…';

  static String get creatingIndexes => _zh ? '正在创建索引…' : 'Creating indexes…';

  static String get importingAirports =>
      _zh ? '正在导入机场…' : 'Importing airports…';

  static String airportsDone(int count) =>
      _zh ? '机场导入完成（$count）' : 'Airports done ($count)';

  static String get importingNavaids => _zh ? '正在导入导航台…' : 'Importing navaids…';

  static String navaidsDone(int count) =>
      _zh ? '导航台导入完成（$count）' : 'Navaids done ($count)';

  static String get importingWaypoints =>
      _zh ? '正在导入航路点…' : 'Importing waypoints…';

  static String waypointsDone(int count) =>
      _zh ? '航路点导入完成（$count）' : 'Waypoints done ($count)';

  static String get importingAirways => _zh ? '正在导入航路…' : 'Importing airways…';

  static String airwaysDone(int count) =>
      _zh ? '航路导入完成（$count）' : 'Airways done ($count)';

  static String importingNavdata(String simName) =>
      _zh ? '正在导入导航数据 — $simName' : 'Importing navdata — $simName';

  static String get downloadingOurAirports =>
      _zh ? '正在下载 OurAirports 数据…' : 'Downloading OurAirports data…';

  static String get enrichingAirports =>
      _zh ? '正在补全机场信息（OurAirports）…' : 'Enriching airports (OurAirports)…';

  static String enrichedAirports(int count) =>
      _zh ? '已补全 $count 个机场' : 'Enriched $count airports';
}
