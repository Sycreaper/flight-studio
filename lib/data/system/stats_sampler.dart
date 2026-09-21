/// Conditional export: picks the FFI-backed sampler on platforms with
/// `dart:ffi` (desktop), or a no-op stub on the web.
library;

export 'stats_sampler_stub.dart' if (dart.library.ffi) 'stats_sampler_io.dart';
