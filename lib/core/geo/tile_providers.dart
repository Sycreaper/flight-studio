import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/settings/app_settings.dart';
import '../../data/settings/settings_enums.dart';

/// Resolves whether the map should use dark tiles based on the user's
/// [MapTheme] preference and the current platform brightness.
bool isMapDark(AppSettings s, Brightness platformBrightness) {
  switch (s.mapTheme) {
    case MapTheme.dark:
      return true;
    case MapTheme.light:
      return false;
    case MapTheme.system:
      return platformBrightness == Brightness.dark;
  }
}

/// Builds a flutter_map [TileLayer] from the user's tile-provider settings.
///
/// The token/URL is resolved via [AppSettings.activeMapToken], which honours
/// the user's specific API-key selection when multiple keys of the same type
/// exist.
TileLayer buildTileLayer(
  AppSettings s, {
  ErrorTileCallBack? onError,
  required bool dark,
}) {
  final token = s.activeMapToken ?? '';
  switch (s.mapTileProvider) {
    case MapTileProvider.osm:
      return TileLayer(
        urlTemplate: dark
            ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        additionalOptions: {'accessToken': token},
        userAgentPackageName: 'flight_studio',
        maxNativeZoom: 19,
        errorTileCallback: onError,
      );
    case MapTileProvider.mapboxStreets:
      return TileLayer(
        urlTemplate: dark
            ? 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}?access_token={accessToken}'
            : 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token={accessToken}',
        additionalOptions: {'accessToken': token},
        userAgentPackageName: 'flight_studio',
        maxNativeZoom: 22,
        errorTileCallback: onError,
      );
    case MapTileProvider.mapboxSatellite:
      return TileLayer(
        urlTemplate:
            'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/{z}/{x}/{y}?access_token={accessToken}',
        additionalOptions: {'accessToken': token},
        userAgentPackageName: 'flight_studio',
        maxNativeZoom: 22,
        errorTileCallback: onError,
      );
    case MapTileProvider.custom:
      return TileLayer(
        urlTemplate: token,
        userAgentPackageName: 'flight_studio',
        maxNativeZoom: 19,
        errorTileCallback: onError,
      );
  }
}
