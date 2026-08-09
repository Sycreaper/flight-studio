import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geo/tile_providers.dart';
import '../../../data/settings/api_key_entry.dart';
import '../../../data/settings/app_settings.dart';
import '../../../data/settings/settings_enums.dart';
import '../../../l10n/app_localizations.dart';
import '../settings/settings_window.dart';
import '../theme/app_colors.dart';
import '../widgets/center_card.dart';

/// The central map canvas — a live `flutter_map` widget that renders raster
/// tiles from the user's configured provider (OSM / Mapbox / custom).
///
/// **Top-right floating controls:** a globe icon (projection + tile-provider
/// selector) and zoom in / zoom out.
///
/// **No-API state:** the original grid backdrop + CTA is shown. Clicking
/// anywhere navigates to the API Keys settings.
class MapCanvas extends StatefulWidget {
  const MapCanvas({super.key});

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  final MapController _mapController = MapController();
  int _errorCount = 0;
  bool _showError = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onTileError(Object error) {
    _errorCount++;
    if (_errorCount > 5 && !_showError) {
      setState(() => _showError = true);
    }
  }

  void _retry() {
    setState(() {
      _errorCount = 0;
      _showError = false;
    });
  }

  void _openApiKeys(BuildContext context) {
    openSettingsTab(context, SettingsLanding.apiKeys);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.settingsOf(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final s = settings.value;
        final ready = s.mapReady;
        return CenterCard(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(
                    Theme.of(context).extension<AppColors>()!,
                  ),
                ),
              ),
              if (ready) _buildMap(context, s),
              if (!ready) _buildPlaceholderOverlay(context),
              Positioned(
                top: 12,
                right: 12,
                child: _MapControls(
                  canZoom: ready,
                  controller: ready ? _mapController : null,
                  settings: s,
                  onSelectApiKey: (entryId, provider) =>
                      AppScope.settingsOf(context)
                          .selectMapApiKey(entryId, provider),
                  onMapThemeChanged: (t) =>
                      AppScope.settingsOf(context).setMapTheme(t),
                ),
              ),
              if (_showError)
                Positioned.fill(
                  child: _MapErrorOverlay(onRetry: _retry),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(BuildContext context, AppSettings s) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(35.0, 0.0),
        initialZoom: 3,
        minZoom: 2,
        maxZoom: 19,
      ),
      children: [
        buildTileLayer(s,
            onError: (tile, error, stack) => _onTileError(error),
            dark: isMapDark(s, Theme.brightnessOf(context))),
        SimpleAttributionWidget(
          source: Text(
            '© OpenStreetMap',
            style: TextStyle(fontSize: 10, color: colors.textSecondary),
          ),
          backgroundColor: colors.surfaceRaised.withValues(alpha: 0.8),
        ),
      ],
    );
  }

  Widget _buildPlaceholderOverlay(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _openApiKeys(context),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_rounded, size: 48, color: colors.textDisabled),
            const SizedBox(height: 12),
            Text(
              l10n.mapPlaceholder,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _openApiKeys(context),
                child: Text(
                  l10n.mapApiKeyCta,
                  style: TextStyle(color: colors.accent, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Floating map controls ───────────────────────────────────────────────────

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.canZoom,
    this.controller,
    required this.settings,
    required this.onSelectApiKey,
    required this.onMapThemeChanged,
  });

  final bool canZoom;
  final MapController? controller;
  final AppSettings settings;
  final void Function(String entryId, MapTileProvider provider) onSelectApiKey;
  final ValueChanged<MapTheme> onMapThemeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<dynamic>(
            tooltip: l10n.mapTheme,
            icon: Icon(Icons.public_rounded,
                size: 18, color: colors.textSecondary),
            color: colors.surfaceRaised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: colors.border),
            ),
            elevation: 8,
            constraints: const BoxConstraints(minWidth: 220),
            onSelected: (result) {
              if (result is MapTheme) {
                onMapThemeChanged(result);
              }
              // API key items use their own onTap callback, not onSelected.
            },
            itemBuilder: (ctx) => _buildMenuItems(ctx),
          ),
          Divider(height: 1, color: colors.border),
          IconButton(
            onPressed: canZoom && controller != null
                ? () =>
                controller!.move(
                  controller!.camera.center,
                  controller!.camera.zoom + 1,
                )
                : null,
            icon: const Icon(Icons.add_rounded, size: 18),
            tooltip: l10n.mapZoomIn,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Divider(height: 1, color: colors.border),
          IconButton(
            onPressed: canZoom && controller != null
                ? () =>
                controller!.move(
                  controller!.camera.center,
                  controller!.camera.zoom - 1,
                )
                : null,
            icon: const Icon(Icons.remove_rounded, size: 18),
            tooltip: l10n.mapZoomOut,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<dynamic>> _buildMenuItems(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx)!;
    final items = <PopupMenuEntry<dynamic>>[];

    // --- Map theme selector ---
    items.add(_sectionHeader(ctx, l10n.mapTheme));
    for (final t in MapTheme.values) {
      items.add(_radioItem(ctx, t, _themeLabel(t, l10n), _themeIcon(t),
          t == settings.mapTheme));
    }

    items.add(const PopupMenuDivider());

    // --- API key entries grouped by type ---
    final mapKeys = settings.apiKeys.where((e) =>
    e.type == ApiKeyType.osmToken ||
        e.type == ApiKeyType.mapboxToken ||
        e.type == ApiKeyType.customTileUrl).toList();

    if (mapKeys.isEmpty) {
      items.add(PopupMenuItem<dynamic>(
        enabled: false,
        height: 40,
        child: Text(l10n.apiKeyEmptyHint,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(ctx).extension<AppColors>()!.textDisabled)),
      ));
    } else {
      // Group by type.
      for (final type in [
        ApiKeyType.osmToken,
        ApiKeyType.mapboxToken,
        ApiKeyType.customTileUrl,
      ]) {
        final group = mapKeys.where((e) => e.type == type).toList();
        if (group.isEmpty) continue;

        items.add(_sectionHeader(ctx, _typeHeader(type, l10n)));
        for (final entry in group) {
          final isSelected = entry.id == settings.selectedMapApiKeyId ||
              (settings.selectedMapApiKeyId == null &&
                  _isFirstForCurrentProvider(entry, settings));
          items.add(_apiKeyItem(ctx, entry, isSelected, () {
            final provider = _providerForType(type, settings.mapTileProvider);
            onSelectApiKey(entry.id, provider);
          }));
        }
      }
    }

    return items;
  }

  bool _isFirstForCurrentProvider(ApiKeyEntry entry, AppSettings s) {
    final matching = s.apiKeys.where((e) =>
    (s.mapTileProvider == MapTileProvider.osm &&
        e.type == ApiKeyType.osmToken) ||
        ((s.mapTileProvider == MapTileProvider.mapboxStreets ||
            s.mapTileProvider == MapTileProvider.mapboxSatellite) &&
            e.type == ApiKeyType.mapboxToken) ||
        (s.mapTileProvider == MapTileProvider.custom &&
            e.type == ApiKeyType.customTileUrl));
    return matching.isNotEmpty && matching.first.id == entry.id;
  }

  static MapTileProvider _providerForType(ApiKeyType type,
      MapTileProvider current) {
    switch (type) {
      case ApiKeyType.osmToken:
        return MapTileProvider.osm;
      case ApiKeyType.mapboxToken:
      // Keep satellite if it was already selected; default to streets.
        return current == MapTileProvider.mapboxSatellite
            ? MapTileProvider.mapboxSatellite
            : MapTileProvider.mapboxStreets;
      case ApiKeyType.customTileUrl:
        return MapTileProvider.custom;
      default:
        return MapTileProvider.osm;
    }
  }

  static String _typeHeader(ApiKeyType type, AppLocalizations l10n) {
    switch (type) {
      case ApiKeyType.osmToken:
        return l10n.apiTileProviderOsm;
      case ApiKeyType.mapboxToken:
        return l10n.apiTileProviderMapboxStreets;
      case ApiKeyType.customTileUrl:
        return l10n.apiTileProviderCustom;
      default:
        return '';
    }
  }

  PopupMenuEntry<dynamic> _sectionHeader(BuildContext ctx, String text) {
    final colors = Theme.of(ctx).extension<AppColors>()!;
    return PopupMenuItem<dynamic>(
      enabled: false,
      height: 28,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: colors.textDisabled,
        ),
      ),
    );
  }

  PopupMenuEntry<dynamic> _apiKeyItem(BuildContext ctx,
      ApiKeyEntry entry,
      bool selected,
      VoidCallback onTap,) {
    final colors = Theme.of(ctx).extension<AppColors>()!;
    return PopupMenuItem<dynamic>(
      value: entry.id,
      height: 38,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          children: [
            Icon(Icons.lock_rounded,
                size: 12,
                color: selected ? colors.accent : colors.textDisabled),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entry.label != null && entry.label!.isNotEmpty)
                    Text(
                      entry.label!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? colors.accent : colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    entry.masked,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 14, color: colors.accent),
          ],
        ),
      ),
    );
  }

  PopupMenuEntry<dynamic> _radioItem(BuildContext ctx,
      dynamic value,
      String label,
      IconData icon,
      bool selected,) {
    final colors = Theme.of(ctx).extension<AppColors>()!;
    return PopupMenuItem<dynamic>(
      value: value,
      height: 36,
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: selected ? colors.accent : colors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? colors.accent : colors.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (selected)
            Icon(Icons.check_rounded, size: 14, color: colors.accent),
        ],
      ),
    );
  }

  static String _themeLabel(MapTheme t, AppLocalizations l10n) {
    switch (t) {
      case MapTheme.system:
        return l10n.settingsThemeSystem;
      case MapTheme.light:
        return l10n.settingsThemeLight;
      case MapTheme.dark:
        return l10n.settingsThemeDark;
    }
  }

  static IconData _themeIcon(MapTheme t) {
    switch (t) {
      case MapTheme.system:
        return Icons.brightness_auto_rounded;
      case MapTheme.light:
        return Icons.light_mode_rounded;
      case MapTheme.dark:
        return Icons.dark_mode_rounded;
    }
  }
}

// ─── Error overlay ───────────────────────────────────────────────────────────

class _MapErrorOverlay extends StatelessWidget {
  const _MapErrorOverlay({required this.onRetry});
  final VoidCallback onRetry;

  Future<void> _launchNetworkRepair() async {
    try {
      await Process.run(
        'cmd',
        ['/c', 'start', '', 'ms-settings:network-troubleshoot'],
      );
    } on Exception catch (_) {
      // Best-effort — silently ignore if the OS command fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: colors.surfaceLowered.withValues(alpha: 0.92),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 40, color: colors.danger),
                const SizedBox(height: 14),
                Text(
                  l10n.mapLoadError,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.mapErrorNoNetwork,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                // Retry + Network Repair buttons.
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(l10n.mapRetry),
                    ),
                    OutlinedButton.icon(
                      onPressed: _launchNetworkRepair,
                      icon: const Icon(Icons.build_rounded, size: 16),
                      label: Text(l10n.mapNetworkRepair),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Grid backdrop ───────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  _GridPainter(this.colors);
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.border.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    const step = 40.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
