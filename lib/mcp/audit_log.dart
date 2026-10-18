import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Append-only audit trail for every FlightStudio Core tool invocation,
/// stored in a dedicated `mcp-audit.sqlite` next to the navdata database
/// (this process owns the file exclusively; the app reads it for the
/// future tool-audit UI). Failures never break a tool call — auditing is
/// best-effort.
class McpAuditLog {
  McpAuditLog._(this._db);

  final Database? _db;

  /// Opens (or creates) the audit database at [path]. Returns a no-op
  /// instance when [path] is empty or the file cannot be opened.
  static McpAuditLog open(String path) {
    if (path.isEmpty) return McpAuditLog._(null);
    try {
      final db = sqlite3.open(path);
      db.execute('''
        CREATE TABLE IF NOT EXISTS tool_invocations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ts TEXT NOT NULL,
          tool TEXT NOT NULL,
          level INTEGER NOT NULL,
          args_json TEXT NOT NULL,
          ok INTEGER NOT NULL,
          result_summary TEXT,
          duration_ms INTEGER NOT NULL DEFAULT 0
        )
      ''');
      db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tool_invocations_ts '
        'ON tool_invocations (ts)',
      );
      return McpAuditLog._(db);
    } on Exception {
      return McpAuditLog._(null);
    }
  }

  /// Audit file path derived from the navdata DB path (same directory).
  static String derivePath(String navdataDbPath) {
    if (navdataDbPath.isEmpty) return '';
    final file = File(navdataDbPath);
    return '${file.parent.path}${Platform.pathSeparator}mcp-audit.sqlite';
  }

  /// Records one invocation. [resultSummary] should stay short (≤ 500
  /// chars) — it is a preview for the audit UI, not the full payload.
  void record({
    required String tool,
    required int level,
    required Map<String, dynamic> args,
    required bool ok,
    String? resultSummary,
    required Duration duration,
  }) {
    final db = _db;
    if (db == null) return;
    try {
      db.execute(
        'INSERT INTO tool_invocations '
        '(ts, tool, level, args_json, ok, result_summary, duration_ms) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          DateTime.now().toUtc().toIso8601String(),
          tool,
          level,
          jsonEncode(args),
          ok ? 1 : 0,
          resultSummary == null || resultSummary.isEmpty
              ? null
              : (resultSummary.length > 500
                    ? resultSummary.substring(0, 500)
                    : resultSummary),
          duration.inMilliseconds,
        ],
      );
    } on Exception {
      // Best-effort — auditing must never fail a tool call.
    }
  }

  /// Test/read helper: the recorded rows, oldest first.
  List<Map<String, Object?>> readAll() {
    final db = _db;
    if (db == null) return const [];
    return db
        .select('SELECT * FROM tool_invocations ORDER BY id')
        .map((r) => {
              for (final e in r.entries) e.key: e.value,
            })
        .toList();
  }

  void dispose() => _db?.close();
}
