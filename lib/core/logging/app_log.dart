import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Severity levels for the app log.
enum LogLevel { debug, info, warn, error }

/// Lightweight structured file logger for the Flutter side.
///
/// Format (one line per entry):
///   2026-10-05T14:30:16.123+08:00 [INFO] [chat] message
///
/// Files live in `<app support>/logs/` (Windows:
/// `%APPDATA%\FlightStudio\logs\`) as `app-yyyy-mm-dd.log`. The GATEWAY
/// writes its own `gateway-yyyy-mm-dd.log` in the same directory — the two
/// never mix. Entries logged before [init] completes are buffered and
/// flushed in order. Files older than [retentionDays] are deleted at init.
class AppLog {
  AppLog._();

  static String? _dirPath;
  static DateTime _fileDay = DateTime.now();
  static final List<String> _pending = [];
  static const retentionDays = 7;

  /// Resolves the log directory and flushes any buffered entries. Called
  /// once at app startup; safe to call again (no-op).
  static Future<void> init() async {
    if (_dirPath != null) return;
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory('${support.path}${Platform.pathSeparator}logs');
      await dir.create(recursive: true);
      _dirPath = dir.path;
      await _prune();
      final buffered = List<String>.from(_pending);
      _pending.clear();
      for (final line in buffered) {
        await _write(line);
      }
      i('log', 'App logging initialised: $_dirPath');
    } on Exception catch (e) {
      debugPrint('[AppLog] init failed: $e');
    }
  }

  /// The shared log directory (null before init) — the gateway spawn uses
  /// it for FS_LOG_DIR.
  static String? get dirPath => _dirPath;

  static void d(String category, String message) =>
      _log(LogLevel.debug, category, message);

  static void i(String category, String message) =>
      _log(LogLevel.info, category, message);

  static void w(String category, String message) =>
      _log(LogLevel.warn, category, message);

  static void e(String category, String message, [Object? error]) => _log(
    LogLevel.error,
    category,
    error == null ? message : '$message | $error',
  );

  static void _log(LogLevel level, String category, String message) {
    final line =
        '${_timestamp()} [${level.name.toUpperCase().padRight(5)}] [$category] $message';
    if (kDebugMode) debugPrint('[AppLog] $line');
    if (_dirPath == null) {
      _pending.add(line);
      if (_pending.length > 200) _pending.removeRange(0, _pending.length - 200);
      return;
    }
    _write(line);
  }

  static String _timestamp() {
    final now = DateTime.now();
    final iso = now.toIso8601String(); // yyyy-mm-ddTHH:mm:ss.mmm+zz:zz
    return iso;
  }

  static Future<void> _write(String line) async {
    try {
      _rotateIfNeeded();
      final file = File(
        '$_dirPath${Platform.pathSeparator}app-$_fileDayStr.log',
      );
      await file.writeAsString('$line\n', mode: FileMode.append);
    } on Exception {
      // Never let logging break the app.
    }
  }

  static String get _fileDayStr =>
      '${_fileDay.year.toString().padLeft(4, '0')}-'
      '${_fileDay.month.toString().padLeft(2, '0')}-'
      '${_fileDay.day.toString().padLeft(2, '0')}';

  static void _rotateIfNeeded() {
    final now = DateTime.now();
    if (now.year != _fileDay.year ||
        now.month != _fileDay.month ||
        now.day != _fileDay.day) {
      _fileDay = now;
    }
  }

  /// Deletes app-*.log / gateway-*.log / gateway-stdout-*.log files older
  /// than [retentionDays].
  static Future<void> _prune() async {
    final dir = _dirPath;
    if (dir == null) return;
    try {
      final cutoff = DateTime.now().subtract(
        const Duration(days: retentionDays),
      );
      await for (final entity in Directory(dir).list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (!name.startsWith('app-') && !name.startsWith('gateway-')) {
          continue;
        }
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoff)) {
          await entity.delete();
        }
      }
    } on Exception {
      // Best-effort.
    }
  }
}
