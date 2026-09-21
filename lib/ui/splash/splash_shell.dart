import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/background_tasks.dart';
import '../../data/navdata/navdata_service.dart';
import '../../data/navdata/startup_scan.dart';
import '../../data/settings/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Startup splash — a compact centred card split by the golden ratio, in
/// the app's own colours: left (larger) part is the X-Plane background image
/// (aspect preserved, cropped to fill), right part is the app chrome colour
/// carrying the logo, app name and a gear-menu-style progress bar.
///
/// Every launch runs the FULL "check all navigation data" pass (the same
/// re-import the navdata settings trigger), with its live progress driving
/// the bar — regardless of whether data already exists. When no simulator is
/// configured (or the import yields nothing) the "no navigation data" hint is
/// held for 3 seconds, then the splash replaces itself with [next].
class SplashShell extends StatefulWidget {
  const SplashShell({super.key, required this.next, required this.settings});

  /// Builds the screen shown after the splash (the welcome screen).
  final WidgetBuilder next;
  final SettingsController settings;

  @override
  State<SplashShell> createState() => _SplashShellState();
}

class _SplashShellState extends State<SplashShell> {
  double _progress = 0;
  bool _noData = false;
  bool _importing = false;

  /// Whether the automatic scan should run for this launch (settings-driven).
  /// When `false` the splash shows ONLY logo + name (no progress content) and
  /// holds for 3 seconds.
  bool _scanDue = true;
  ScanTask? _task;
  Timer? _ticker;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _scanDue = isNavdataScanDue(
      widget.settings.value.splashScanMode,
      widget.settings.value.lastNavdataScanAt,
    );
    _startScan();
    BackgroundTaskManager.instance.addListener(_onTasksChanged);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    BackgroundTaskManager.instance.removeListener(_onTasksChanged);
    super.dispose();
  }

  /// Real import progress (from the navdata provider's background task)
  /// replaces the cosmetic crawl entirely — the bar starts from the task's
  /// true 0 % instead of the crawled baseline. The task itself is kept so the
  /// hint line can show the exact label the gear menu shows.
  void _onTasksChanged() {
    if (!_importing) return;
    final tasks = BackgroundTaskManager.instance.tasks;
    if (tasks.isEmpty) return;
    _task = tasks.last;
    if (mounted && _task!.progress != _progress) {
      setState(() => _progress = _task!.progress);
    }
  }

  Future<void> _startScan() async {
    // Scan disabled (or not yet due): splash shows logo + name only —
    // nothing else — for 3 seconds, then moves on.
    if (!_scanDue) {
      await Future<void>.delayed(const Duration(seconds: 3));
      _navigate();
      return;
    }

    // Crawl the bar towards 90% while the pre-import setup runs (database
    // open/clear), so those steps never look frozen.
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted && _progress < 0.9) {
        setState(() => _progress = math.min(0.9, _progress + 0.02));
      }
    });

    // Full "check all navigation data" pass honouring the active source
    // selection (radio in the navdata section) — real import, real progress
    // via [BackgroundTaskManager]. The bar switches to the task's TRUE
    // progress (from 0 %) — the crawl is only for the pre-import phase.
    final hasTarget = resolveImportTarget(widget.settings.value) != null;
    if (hasTarget && !Platform.environment.containsKey('FLUTTER_TEST')) {
      _ticker?.cancel();
      if (!mounted) return;
      setState(() {
        _importing = true;
        _progress = 0;
      });
      await importSelectedNavdata(widget.settings.value);
      if (!mounted) return;
      setState(() => _importing = false);
    }

    _ticker?.cancel();
    if (!mounted) return;

    final hasData = await NavdataService.instance.scanExistingData();

    if (hasData) {
      setState(() => _progress = 1.0);
      // Let the bar visibly complete before switching screens.
      await Future<void>.delayed(const Duration(milliseconds: 700));
    } else {
      setState(() => _noData = true);
      // Hold the "no navigation data" hint for 3 seconds as requested.
      await Future<void>.delayed(const Duration(seconds: 3));
    }
    _navigate();
  }

  void _navigate() {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: widget.next));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    // Compact centred card on a pure-black surround.
    final width = math.min(560.0, size.width * 0.78);
    final height = math.min(320.0, size.height * 0.62);

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: width,
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left — golden-ratio larger part: background image, aspect
                // preserved (BoxFit.cover crops the overflow).
                Expanded(
                  flex: 618,
                  child: Image.asset(
                    'assets/images/splash_bg.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerLeft,
                  ),
                ),
                // Right — app chrome colour: logo + name, gear-menu-style
                // progress.
                Expanded(
                  flex: 382,
                  child: Container(
                    color: colors.chrome,
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/logo.svg',
                          width: 44,
                          height: 44,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.appName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: colors.textPrimary,
                          ),
                        ),
                        // Same presentation as the gear dropdown's progress
                        // entries: icon + live task label + percent over a
                        // 4 px accent bar. Hidden entirely when no scan is
                        // due for this launch.
                        if (_scanDue) ...[
                          const SizedBox(height: 36),
                          _SplashProgressEntry(
                            task: _task,
                            fallbackLabel: _noData
                                ? l10n.splashNoNavdata
                                : l10n.splashScanning,
                            progress: _progress,
                            colors: colors,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mirrors the gear dropdown's `_ProgressEntry` from settings_window.dart:
/// radar/check icon, 11 px task label, right-aligned percentage and a 4 px
/// accent progress bar. Shows the plain hint text when no task is running.
class _SplashProgressEntry extends StatelessWidget {
  const _SplashProgressEntry({
    required this.task,
    required this.fallbackLabel,
    required this.progress,
    required this.colors,
  });

  final ScanTask? task;
  final String fallbackLabel;
  final double progress;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final label = task?.label ?? fallbackLabel;
    final complete = progress >= 1.0;
    final pct = (progress * 100).round();
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                complete ? Icons.check_circle_rounded : Icons.radar_rounded,
                size: 13,
                color: complete ? colors.success : colors.accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: colors.surfaceLowered,
              valueColor: AlwaysStoppedAnimation(colors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
