import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Placeholder for the central map canvas. Will host `flutter_map` with custom
/// layers (airports, navaids, airways, airspace, route, aircraft) in phase 1+.
///
/// Until the real map is wired, the canvas shows:
/// - A faux grid backdrop.
/// - A centred icon + label (theme-aware so they're visible in both light and
///   dark themes).
/// - A yellow CTA line below the label that guides the user to bind their map
///   API key. Clicking it is a no-op for now — the navigation target will be
///   wired in a follow-up.
/// - An error overlay when the map fails to load (e.g. 404, no network). The
///   overlay shows the HTTP status code (or a generic message) and a Retry
///   button.
class MapCanvas extends StatefulWidget {
  const MapCanvas({super.key});

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  // TODO(phase-2): replace with real flutter_map error state. For now this
  // is a placeholder that demonstrates the error UI; set to non-null to see
  // the error overlay in action.
  int? _errorCode;
  bool _showError = false;

  void _retry() {
    setState(() {
      _showError = false;
      _errorCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Faux ocean/grid backdrop until flutter_map is wired up.
          Positioned.fill(child: CustomPaint(painter: _GridPainter(colors))),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_rounded,
                    size: 48, color: colors.textDisabled),
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
                // CTA — guides user to bind their API key. Style matches the
                // flight-plan tree's "Click to create one" (accent colour, no
                // underline). No navigation yet; click handler is a placeholder.
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: navigate to Settings → Navigation Data section.
                    },
                    child: Text(
                      l10n.mapApiKeyCta,
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating zoom controls (top-right), like IDEA's editor gutter.
          Positioned(
            top: 12,
            right: 12,
            child: _ZoomControls(),
          ),
          // Error overlay — covers the canvas when the map fails to load.
          if (_showError)
            Positioned.fill(
              child: _MapErrorOverlay(
                errorCode: _errorCode,
                onRetry: _retry,
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-canvas error overlay. Shows the error reason + a suggested solution +
/// a Retry button. Styled to match the map canvas's rounded container.
class _MapErrorOverlay extends StatelessWidget {
  const _MapErrorOverlay({this.errorCode, required this.onRetry});

  final int? errorCode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final String reason;
    final String solution;
    switch (errorCode) {
      case 404:
        reason = '404';
        solution = l10n.mapError404;
        break;
      case null:
        reason = l10n.mapLoadError;
        solution = l10n.mapErrorNoNetwork;
        break;
      default:
        reason = l10n.mapErrorGeneric(errorCode.toString());
        solution = l10n.mapErrorNoNetwork;
    }
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
                Icon(Icons.cloud_off_rounded,
                    size: 40, color: colors.danger),
                const SizedBox(height: 14),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  solution,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(l10n.mapRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, size: 18),
            tooltip: l10n.mapZoomIn,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Divider(height: 1, color: colors.border),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.remove_rounded, size: 18),
            tooltip: l10n.mapZoomOut,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

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
