import 'package:flutter/foundation.dart';

/// Tracks one background scan operation (navdata import). Multiple scans can
/// run concurrently; [BackgroundTaskManager] aggregates them so the gear
/// button knows when to spin.
class ScanTask {
  ScanTask({required this.id, required this.label});

  final String id;
  final String label;
  double progress = 0; // 0.0 .. 1.0
  String? error;

  bool get isComplete => progress >= 1.0;
}

/// Singleton [ChangeNotifier] that tracks all active background tasks. The
/// gear button listens to this to decide whether to spin; the gear menu reads
/// it to show progress bars.
class BackgroundTaskManager extends ChangeNotifier {
  BackgroundTaskManager._();

  static final BackgroundTaskManager instance = BackgroundTaskManager._();

  final List<ScanTask> _tasks = [];

  List<ScanTask> get tasks => List.unmodifiable(_tasks);

  bool get hasActiveTasks =>
      _tasks.any((t) => !t.isComplete && t.error == null);

  /// Starts a fake 20-second scan task (placeholder for real navdata import).
  ScanTask startFakeScan(String label) {
    final task = ScanTask(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
    );
    _tasks.add(task);
    notifyListeners();

    // Simulate progress over 20 seconds.
    () async {
      for (var i = 0; i <= 100; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        task.progress = i / 100;
        notifyListeners();
        if (task.isComplete) break;
      }
      // Auto-remove 3 seconds after completion.
      await Future.delayed(const Duration(seconds: 3));
      _tasks.removeWhere((t) => t.id == task.id);
      notifyListeners();
    }();

    return task;
  }

  void removeTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void clearCompleted() {
    _tasks.removeWhere((t) => t.isComplete || t.error != null);
    notifyListeners();
  }
}
