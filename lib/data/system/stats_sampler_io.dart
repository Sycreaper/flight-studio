import 'dart:ffi';
import 'dart:math' as math;

import 'package:ffi/ffi.dart';

/// One CPU + memory sample (GPU is polled separately by the service).
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

/// MEMORYSTATUSEX layout (winbase.h). Only the fields we read are annotated.
final class _MemoryStatusEx extends Struct {
  @Uint32()
  external int dwLength;

  @Uint32()
  external int dwMemoryLoad;

  @Uint64()
  external int ullTotalPhys;

  @Uint64()
  external int ullAvailPhys;

  @Uint64()
  external int ullTotalPageFile;

  @Uint64()
  external int ullAvailPageFile;

  @Uint64()
  external int ullTotalVirtual;

  @Uint64()
  external int ullAvailVirtual;

  @Uint64()
  external int ullAvailExtendedVirtual;
}

typedef _GetSystemTimesNative =
    Int32 Function(Pointer<Uint32>, Pointer<Uint32>, Pointer<Uint32>);
typedef _GetSystemTimesDart =
    int Function(Pointer<Uint32>, Pointer<Uint32>, Pointer<Uint32>);

typedef _GlobalMemoryStatusExNative = Int32 Function(Pointer<_MemoryStatusEx>);
typedef _GlobalMemoryStatusExDart = int Function(Pointer<_MemoryStatusEx>);

/// Samples CPU utilisation (GetSystemTimes delta) and physical memory
/// (GlobalMemoryStatusEx) via kernel32 FFI.
///
/// Windows-only by construction — this library is only selected on platforms
/// where `dart:ffi` compiles (see `stats_sampler.dart`).
class SystemStatsSampler {
  static final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');

  static final _GetSystemTimesDart _getSystemTimes = _kernel32
      .lookupFunction<_GetSystemTimesNative, _GetSystemTimesDart>(
        'GetSystemTimes',
      );

  static final _GlobalMemoryStatusExDart _globalMemoryStatusEx = _kernel32
      .lookupFunction<_GlobalMemoryStatusExNative, _GlobalMemoryStatusExDart>(
        'GlobalMemoryStatusEx',
      );

  Pointer<Uint32>? _prevIdle;
  Pointer<Uint32>? _prevKernel;
  Pointer<Uint32>? _prevUser;

  /// Samples CPU (delta from the previous call) and memory. Returns `null`
  /// on the very first call (no baseline yet) or on API failure.
  SystemStatsSample? sample() {
    final idle = calloc<Uint32>(2);
    final kernel = calloc<Uint32>(2);
    final user = calloc<Uint32>(2);
    if (_getSystemTimes(idle, kernel, user) == 0) {
      _free(idle);
      _free(kernel);
      _free(user);
      return null;
    }

    double? cpu;
    if (_prevIdle != null && _prevKernel != null && _prevUser != null) {
      final idleDelta = _combine(idle) - _combine(_prevIdle!);
      final kernelDelta = _combine(kernel) - _combine(_prevKernel!);
      final userDelta = _combine(user) - _combine(_prevUser!);
      final total = kernelDelta + userDelta;
      cpu = total > 0 ? (1 - idleDelta / total) * 100 : 0.0;
    }

    _free(_prevIdle);
    _free(_prevKernel);
    _free(_prevUser);
    _prevIdle = idle;
    _prevKernel = kernel;
    _prevUser = user;

    if (cpu == null) return null; // First call — baseline only.

    final mem = calloc<_MemoryStatusEx>();
    mem.ref.dwLength = sizeOf<_MemoryStatusEx>();
    if (_globalMemoryStatusEx(mem) == 0) {
      _free(mem);
      return null;
    }
    final total = mem.ref.ullTotalPhys / (1024 * 1024 * 1024);
    final avail = mem.ref.ullAvailPhys / (1024 * 1024 * 1024);
    final used = math.max(0.0, total - avail);
    final result = SystemStatsSample(
      cpuPercent: cpu.clamp(0, 100),
      memoryPercent: mem.ref.dwMemoryLoad.toDouble(),
      memoryUsedGb: used,
      memoryTotalGb: total,
    );
    _free(mem);
    return result;
  }

  void dispose() {
    _free(_prevIdle);
    _free(_prevKernel);
    _free(_prevUser);
    _prevIdle = null;
    _prevKernel = null;
    _prevUser = null;
  }

  static int _combine(Pointer<Uint32> p) => (p[1] << 32) | p[0];

  static void _free<T extends NativeType>(Pointer<T>? p) {
    if (p != null) calloc.free(p);
  }
}
