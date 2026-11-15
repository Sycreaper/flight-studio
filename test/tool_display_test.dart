import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:flight_studio/l10n/app_localizations.dart';
import 'package:flight_studio/mcp/tool_display.dart';

/// Unit tests for the readable tool-display mapping used on permission
/// cards and phase rows: localized names, MCP-name de-qualification,
/// value-only key-parameter markers and the preview-redundancy rule.
void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('bareToolName', () {
    test('strips MCP server qualification', () {
      expect(
        bareToolName('mcp__flightstudio-core__get_airport_data'),
        'get_airport_data',
      );
    });

    test('passes plain and harness names through unchanged', () {
      expect(bareToolName('get_airport_data'), 'get_airport_data');
      expect(bareToolName('Read'), 'Read');
    });
  });

  group('toolDisplayName', () {
    test('maps registered MCP tools to localized labels', () {
      expect(
        toolDisplayName('mcp__flightstudio-core__get_airport_data', l10n),
        l10n.mcpToolAirportData,
      );
      expect(toolDisplayName('weather_read', l10n), l10n.mcpToolWeatherRead);
      expect(
        toolDisplayName('set_com_frequency', l10n),
        l10n.mcpToolSetComFrequency,
      );
    });

    test('falls back to the bare name for unknown tools', () {
      expect(
        toolDisplayName('mcp__other-server__custom_tool', l10n),
        'custom_tool',
      );
      expect(toolDisplayName('Read', l10n), 'Read');
    });
  });

  group('toolKeyParams', () {
    test('shows the registered key parameter value only', () {
      expect(
        toolKeyParams('get_airport_data', {'icao': 'ZSPD'}),
        ['ZSPD'],
      );
      expect(
        toolKeyParams(
          'mcp__flightstudio-core__charts_read',
          {'icao': 'zbaa'},
        ),
        ['zbaa'],
      );
    });

    test('skips missing, empty and non-scalar values', () {
      expect(toolKeyParams('weather_read', {'icao': '  '}), isEmpty);
      expect(
        toolKeyParams('weather_read', {'icao': 'ZSPD', 'extra': {'a': 1}}),
        ['ZSPD'],
      );
    });

    test('generic fallback: first few scalar values, clipped', () {
      expect(
        toolKeyParams('unknown_tool', {'q': 'ILS', 'n': 2}),
        ['ILS', '2'],
      );
      expect(
        toolKeyParams('unknown_tool', {
          'q': 'a-very-long-query-string-exceeding-limit',
        }),
        ['a-very-long-quer…'],
      );
    });
  });

  group('keyParamsCoverInput', () {
    test('true when every input key is a registered key param', () {
      expect(
        keyParamsCoverInput('get_airport_data', {'icao': 'ZSPD'}),
        isTrue,
      );
      expect(
        keyParamsCoverInput('get_airport_data', {'icao': 'ZSPD', 'x': 1}),
        isFalse,
      );
      expect(keyParamsCoverInput('unknown_tool', {'a': 1}), isFalse);
    });
  });
}
