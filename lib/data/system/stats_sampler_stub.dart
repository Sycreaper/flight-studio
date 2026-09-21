/// No-op sampler used on platforms without `dart:ffi` (the web). The stats
/// service simply never publishes CPU/memory values there.
class SystemStatsSample {
  const SystemStatsSample({
    required this.cpuPercent,
    required this.memoryPercent,
    required this.memoryUsedGb,
    required this.memoryTotalGb,
  });

  final double cpuPercent;
  final double memoryPercent;
  final double memoryUsedGb;
  final double memoryTotalGb;
}

class SystemStatsSampler {
  SystemStatsSample? sample() => null;

  void dispose() {}
}
