import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Enumerates the font families installed on the machine.
///
/// Windows-only: queries `InstalledFontFontCollection` via a single PowerShell
/// invocation and caches the sorted result. On the web / inside `flutter
/// test` / non-Windows platforms the list is empty and the settings dropdown
/// shows only the “Default” entry.
class FontService {
  FontService._();

  static final FontService instance = FontService._();

  List<String>? _cache;

  /// Sorted, de-duplicated font family names (e.g. `Segoe UI`, `Arial`).
  /// Empty on unsupported platforms.
  Future<List<String>> installedFonts() async {
    if (_cache != null) return _cache!;
    if (kIsWeb || !Platform.isWindows) return const [];
    if (Platform.environment.containsKey('FLUTTER_TEST')) return const [];
    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        'Add-Type -AssemblyName System.Drawing; '
            '[System.Drawing.Text.InstalledFontCollection]::new()'
            '.Families | ForEach-Object { \$_.Name }',
      ], stdoutEncoding: utf8);
      if (result.exitCode == 0) {
        final names =
            result.stdout
                .toString()
                .split('\n')
                .map((l) => l.trim())
                .where((l) => l.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        _cache = names;
        return names;
      }
    } on Exception catch (_) {
      // PowerShell unavailable — fall through to empty.
    }
    return const [];
  }
}
