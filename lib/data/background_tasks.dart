import 'package:flutter/foundation.dart';

/// Tracks one background operation (e.g. navdata import). Multiple tasks can
/// run concurrently; [BackgroundTaskManager] aggregates them so the gear
/// button knows when to spin.
class ScanTask {
  ScanTask({required this.id, required this.label});

  final String id;
  String label;
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

  /// Starts a task whose progress is driven externally by the caller via the
  /// returned [ScanTask]. Call [completeTask] when done (or [failTask]).
  ScanTask startTask(String label) {
    final task = ScanTask(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
    );
    _tasks.add(task);
    notifyListeners();
    return task;
  }

  /// Updates a running task's progress (0.0–1.0) and optional status label.
  void updateTask(ScanTask task, double progress, {String? label}) {
    task.progress = progress.clamp(0.0, 1.0);
    if (label != null) task.label = label;
    notifyListeners();
  }

  /// Marks a task complete. It is auto-removed 3 seconds later.
  void completeTask(ScanTask task) {
    task.progress = 1.0;
    notifyListeners();
    _scheduleRemoval(task);
  }

  /// Marks a task failed with an error message.
  void failTask(ScanTask task, String error) {
    task.error = error;
    notifyListeners();
    _scheduleRemoval(task);
  }

  void _scheduleRemoval(ScanTask task) {
    () async {
      await Future<void>.delayed(const Duration(seconds: 3));
      _tasks.removeWhere((t) => t.id == task.id);
      notifyListeners();
    }();
  }

  /// Starts a fake 20-second scan task (placeholder for demos).
  ScanTask startFakeScan(String label) {
    final task = startTask(label);

    // Simulate progress over 20 seconds.
    () async {
      for (var i = 0; i <= 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        task.progress = i / 100;
        notifyListeners();
        if (task.isComplete) break;
      }
      await Future<void>.delayed(const Duration(seconds: 3));
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
