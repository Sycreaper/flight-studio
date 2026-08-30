import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/navdata/navdata_types.dart';
import '../../../data/navdata/navdata_service.dart';
import '../../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Dockable search drawer. A search input at the top, compact results below
/// (no dividers). Queries the navdata database across airports, navaids and
/// waypoints as the user types (250 ms debounce).
///
/// Tapping a result invokes [onFlyTo] — the shell switches to / creates a map
/// tab and flies the camera to the point.
class SearchPanel extends StatefulWidget {
  const SearchPanel({super.key, required this.onFlyTo});

  /// Called with the tapped point's coordinates.
  final ValueChanged<LatLng> onFlyTo;

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<NavPoint> _results = [];
  bool _searched = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    final q = _controller.text.trim();
    if (q.length < 2) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    setState(() => _busy = true);
    final results = await NavdataService.instance.searchAll(q, limit: 50);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searched = true;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search input.
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            style: TextStyle(fontSize: 13, color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              hintStyle: TextStyle(fontSize: 12, color: colors.textDisabled),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 16,
                color: colors.textSecondary,
              ),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _controller.clear();
                        _focus.requestFocus();
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: colors.textSecondary,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 26,
                      ),
                      padding: EdgeInsets.zero,
                    ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: colors.surfaceLowered,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.accent, width: 1.4),
              ),
            ),
          ),
        ),
        // Results.
        Expanded(
          child: _busy
              ? Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accent,
                    ),
                  ),
                )
              : _results.isEmpty
              ? _Hint(
                  text: _searched ? l10n.searchNoResults : l10n.searchStart,
                  colors: colors,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final point = _results[i];
                    return _ResultTile(
                      point: point,
                      colors: colors,
                      onTap: () => widget.onFlyTo(
                        LatLng(point.latitude, point.longitude),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text, required this.colors});

  final String text;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: colors.textDisabled),
        ),
      ),
    );
  }
}

/// Compact result row: category icon + ident + name (+ frequency) — no
/// divider lines between rows.
class _ResultTile extends StatefulWidget {
  const _ResultTile({
    required this.point,
    required this.colors,
    required this.onTap,
  });

  final NavPoint point;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  State<_ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends State<_ResultTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final p = widget.point;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: _hovering
                ? colors.accent.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: SvgPicture.asset(p.svgAsset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      p.ident,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _hovering ? colors.accent : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        p.frequency != null
                            ? '${p.name} · ${p.frequency}'
                            : p.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.flight_takeoff_rounded,
                size: 13,
                color: _hovering ? colors.accent : colors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
