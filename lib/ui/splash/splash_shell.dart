import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';

import '../../data/background_tasks.dart';
import '../../data/navdata/navdata_service.dart';
import '../../data/navdata/startup_scan.dart';
import '../../data/settings/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Splash-window size while the splash shows (the window starts at this size
/// in main.dart and grows back to the working size when the splash ends).
const kSplashWindowSize = Size(600, 372);

/// Whether the splash is currently showing. The app shell listens so the
/// custom caption controls can hide the maximize button while the window is
/// size-locked (programmatic maximize bypasses `setResizable(false)`).
final ValueNotifier<bool> splashActive = ValueNotifier(false);

/// Startup splash — a small full-screen surface: "Flight Studio" top-left in
/// dark red-brown over a warm-yellow shadow block, the real app logo (the
/// same SVG as the welcome drawer, launcher icons and About page) centred,
/// and a status line under it — the four-colour progress indicator plus
/// "Starting Flight Studio" when no scan is due, or the live navdata-scan
/// task label while one runs.
///
/// Every launch runs the FULL "check all navigation data" pass (the same
/// re-import the navdata settings trigger). When no simulator is configured
/// (or the import yields nothing) the "no navigation data" hint is held for
/// 3 seconds. When the splash finishes, the window grows back to the working
/// size and the splash replaces itself with [next].
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
  /// When `false` the splash shows ONLY the starting hint (no scan content)
  /// and holds for 3 seconds.
  bool _scanDue = true;
  ScanTask? _task;
  Timer? _ticker;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    splashActive.value = true;
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
  /// drives the status line — kept so the label can show the exact task the
  /// gear menu shows.
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
    // Scan disabled (or not yet due): splash shows the starting hint only —
    // nothing else — for 3 seconds, then moves on.
    if (!_scanDue) {
      await Future<void>.delayed(const Duration(seconds: 3));
      _navigate();
      return;
    }

    // Crawl the progress towards 90% while the pre-import setup runs
    // (database open/clear), so those steps never look frozen.
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted && _progress < 0.9) {
        setState(() => _progress = math.min(0.9, _progress + 0.02));
      }
    });

    // Full "check all navigation data" pass honouring the active source
    // selection (radio in the navdata section) — real import, real progress
    // via [BackgroundTaskManager].
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
      // Let the status visibly complete before switching screens.
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
    // Release the splash lock: caption controls may show maximize again.
    splashActive.value = false;
    // Grow the locked splash window back to the working size (and re-enable
    // resizing) before the welcome screen appears.
    if (!kIsWeb) {
      () async {
        try {
          await windowManager.setResizable(true);
          await windowManager.setSize(const Size(1280, 720));
          await windowManager.center();
        } on Exception {
          // Best-effort (e.g. missing plugin channel in tests) — never block.
        }
      }();
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: widget.next));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.surfaceRaised,
      body: Stack(
        children: [
          // App name top-left: dark red-brown type over a rounded
          // warm-yellow shadow block (per the reference design).
          Positioned(
            top: 16,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF6DBD4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.appName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Color(0xFFB13B34),
                ),
              ),
            ),
          ),
          // Real logo centred, status line under it.
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/logo.svg',
                  width: 112,
                  height: 112,
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation(colors.accent),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _statusText(l10n),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Full-width progress bar hugging the window's bottom edge. Empty
          // and static when no scan is due (nothing to measure).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LinearProgressIndicator(
              value: _scanDue ? _progress : 0,
              minHeight: 3,
              backgroundColor: colors.surfaceLowered,
              valueColor: AlwaysStoppedAnimation(colors.accent),
            ),
          ),
        ],
      ),
    );
  }

  /// The status line under the logo: the live scan-task label (with the
  /// percentage while running) when a scan is due, the plain starting hint
  /// otherwise.
  String _statusText(AppLocalizations l10n) {
    if (!_scanDue) return l10n.splashStarting;
    final task = _task;
    if (task != null && task.progress < 1.0) {
      return '${task.label} ${(task.progress * 100).round()}%';
    }
    return _noData ? l10n.splashNoNavdata : l10n.splashScanning;
  }
}
