import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'stats_sampler.dart';

/// One polled snapshot of system resource usage.
@immutable
class SystemStats {
  const SystemStats({
    required this.cpuPercent,
    required this.gpuPercent,
    required this.memoryPercent,
    required this.memoryUsedGb,
    required this.memoryTotalGb,
  });

  /// Total CPU utilisation 0–100 (delta between the last two samples).
  final double cpuPercent;

  /// GPU utilisation 0–100, or `null` when unavailable (no NVIDIA GPU /
  /// nvidia-smi not installed / unsupported platform).
  final double? gpuPercent;

  final double memoryPercent;
  final double memoryUsedGb;
  final double memoryTotalGb;
}

/// Polls system resource usage (CPU / GPU / memory) every 2 seconds and
/// publishes snapshots through [ChangeNotifier].
///
/// - **CPU / memory** — `SystemStatsSampler` (kernel32 FFI on Windows,
///   no-op on platforms without `dart:ffi` such as the web).
/// - **GPU** — best-effort `nvidia-smi` query; `null` when unavailable.
///
/// On the web the service stays idle (no FFI, no nvidia-smi) and the status
/// bar shows `--` placeholders.
class SystemStatsService extends ChangeNotifier {
  SystemStatsService._();

  static final SystemStatsService instance = SystemStatsService._();

  Timer? _timer;
  SystemStats _stats = const SystemStats(
    cpuPercent: 0,
    gpuPercent: null,
    memoryPercent: 0,
    memoryUsedGb: 0,
    memoryTotalGb: 0,
  );

  SystemStats get stats => _stats;

  final SystemStatsSampler _sampler = SystemStatsSampler();
  bool _gpuProbeFailed = false;

  /// Starts the 2-second polling loop. Safe to call multiple times.
  ///
  /// Skipped inside `flutter test` (FLUTTER_TEST env var): the periodic
  /// notify loop would keep `pumpAndSettle` from ever settling. Also skipped
  /// on the web / non-Windows platforms (no FFI, no nvidia-smi).
  void start() {
    if (_timer != null) return;
    if (kIsWeb || !Platform.isWindows) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _sample(); // First sample seeds the CPU delta baseline.
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _sample());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _sampler.dispose();
  }

  void _sample() {
    try {
      final sample = _sampler.sample();
      if (sample != null) {
        _stats = SystemStats(
          cpuPercent: sample.cpuPercent,
          gpuPercent: _stats.gpuPercent,
          memoryPercent: sample.memoryPercent,
          memoryUsedGb: sample.memoryUsedGb,
          memoryTotalGb: sample.memoryTotalGb,
        );
        notifyListeners();
      }
    } on Exception catch (_) {
      // FFI failure — leave last values.
    }
    _sampleGpu(); // Async — notifies again when the GPU answer arrives.
  }

  Future<void> _sampleGpu() async {
    if (_gpuProbeFailed) {
      // Retry occasionally in case the driver appears later.
      if (math.Random().nextInt(8) != 0) return;
    }
    try {
      final result = await Process.run('nvidia-smi', [
        '--query-gpu=utilization.gpu',
        '--format=csv,noheader,nounits',
      ], stdoutEncoding: utf8);
      if (result.exitCode == 0) {
        final line = result.stdout.toString().trim().split('\n').first.trim();
        final v = double.tryParse(line);
        if (v != null) {
          _stats = SystemStats(
            cpuPercent: _stats.cpuPercent,
            gpuPercent: v.clamp(0, 100),
            memoryPercent: _stats.memoryPercent,
            memoryUsedGb: _stats.memoryUsedGb,
            memoryTotalGb: _stats.memoryTotalGb,
          );
          _gpuProbeFailed = false;
          notifyListeners();
          return;
        }
      }
      _gpuProbeFailed = true;
    } on Exception catch (_) {
      _gpuProbeFailed = true; // nvidia-smi not in PATH.
    }
  }
}
