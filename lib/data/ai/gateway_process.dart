import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'gateway_client.dart';

/// Owns the Agent Gateway subprocess lifecycle.
///
/// Dev layout: the gateway lives at `<repo>/agent_gateway/` (TypeScript,
/// built to `dist/`). The Flutter app starts it on demand before the first
/// chat turn and leaves it running for the session. Release builds bundle
/// the same folder next to the executable.
class GatewayProcess {
  GatewayProcess._();

  static final GatewayProcess instance = GatewayProcess._();

  Process? _process;
  Future<bool>? _starting;

  bool get isRunning => _process != null;

  /// Ensures the gateway answers on [GatewayClient.baseUrl]. Spawns it when
  /// missing. A healthy gateway that this process did NOT spawn is a stale
  /// instance from an earlier app run (possibly older code) — it is evicted
  /// so the current build always serves.
  Future<bool> ensureRunning() async {
    if (await _isHealthy()) {
      if (_process != null) return true;
      await _evictStaleGateway();
    }
    if (_starting != null) return _starting!;
    _starting = _spawn();
    try {
      return await _starting!;
    } finally {
      _starting = null;
    }
  }

  /// Kills whatever process listens on the gateway port (netstat lookup),
  /// so the next spawn binds cleanly. Only called when the listener is not
  /// our own child.
  Future<void> _evictStaleGateway() async {
    try {
      final port = GatewayClient.baseUrl.split(':').last;
      final result = await Process.run('netstat', ['-ano', '-p', 'tcp']);
      final text = result.stdout as String? ?? '';
      final ownPid = _process?.pid ?? -1;
      for (final line in text.split('\n')) {
        if (!line.contains('LISTENING')) continue;
        if (!line.contains(':$port')) continue;
        final parts = line.trim().split(RegExp(r'\s+'));
        final pid = int.tryParse(parts.last);
        if (pid == null || pid <= 0 || pid == ownPid) continue;
        await Process.run('taskkill', ['/PID', '$pid', '/T', '/F']);
      }
      // Give the OS a moment to release the port.
      await Future<void>.delayed(const Duration(milliseconds: 600));
    } on Exception {
      // Best-effort eviction.
    }
  }

  Future<bool> _isHealthy() async {
    try {
      final res = await GatewayClient.instance.status();
      return res != null;
    } on Exception {
      return false;
    }
  }

  Future<bool> _spawn() async {
    // Another gateway may have come up while we were starting.
    if (await _isHealthy()) return true;

    final gatewayDir = _locateGatewayDir();
    if (gatewayDir == null) return false;
    final entry = File(
      '${gatewayDir.path}${Platform.pathSeparator}dist${Platform.pathSeparator}index.js',
    );
    if (!await entry.exists()) return false;

    final node = await _findNode();
    if (node == null) return false;

    try {
      final process = await Process.start(node, [
        entry.path,
      ], workingDirectory: gatewayDir.path);
      _process = process;
      // Drain output to a log file (never block the pipe; keep crashes
      // diagnosable).
      final logSink = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'flightstudio-gateway.log',
      ).openWrite(mode: FileMode.append);
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(logSink.writeln, onError: (Object _) {});
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(logSink.writeln, onError: (Object _) {});
      unawaited(
        process.exitCode.then((_) {
          if (_process == process) _process = null;
          logSink.close();
        }),
      );

      // Wait for /health — the Letta runtime warms up in the background, so
      // this is just the HTTP listener.
      const poll = Duration(milliseconds: 300);
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(poll);
        if (await _isHealthy()) return true;
        if (_process == null) return false; // died
      }
      return false;
    } on Exception {
      _process = null;
      return false;
    }
  }

  /// Stops the subprocess tree (gateway + its app-server child) and waits
  /// for the port to be released. Tree-kill matters: killing only the
  /// gateway orphans the spawned Letta app-server.
  Future<void> stop() async {
    final p = _process;
    _process = null;
    if (p != null) {
      if (Platform.isWindows) {
        await Process.run('taskkill', ['/PID', '${p.pid}', '/T', '/F']);
      } else {
        p.kill();
      }
    }
    // Give the OS a moment to release the port.
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  /// One-click Letta wipe: stops the gateway tree (including the Letta
  /// app-server that holds `~/.letta` open) and deletes every Letta-owned
  /// file (`~/.letta` — agents, conversations, memory, provider
  /// credentials, logs). The next message re-initializes everything.
  /// Returns true when the directory is gone (or never existed).
  static Future<bool> deleteLettaData() async {
    await GatewayProcess.instance.stop();
    final home = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '';
    if (home.isEmpty) return false;
    final dir = Directory(
      '$home${Platform.pathSeparator}.letta',
    );
    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        if (!await dir.exists()) return true;
        await dir.delete(recursive: true);
        return true;
      } on FileSystemException {
        // Files still held by a dying process — retry briefly.
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    return !await dir.exists();
  }

  /// Finds the agent_gateway directory: from the current working directory
  /// (dev: repo root) walking up, then from the executable location
  /// (release build folders live inside the repo too).
  Directory? _locateGatewayDir() {
    final candidates = <Directory>[
      Directory.current,
      Directory(Platform.resolvedExecutable).parent,
    ];
    for (final start in candidates) {
      Directory? dir = start;
      for (var depth = 0; depth < 6 && dir != null; depth++) {
        final probe = Directory(
          '${dir.path}${Platform.pathSeparator}agent_gateway',
        );
        final marker = File(
          '${probe.path}${Platform.pathSeparator}package.json',
        );
        if (marker.existsSync()) return probe;
        dir = dir.parent;
      }
    }
    return null;
  }

  Future<String?> _findNode() async {
    const names = ['node.exe', 'node'];
    // PATH lookup first — the standard install case.
    final pathEnv = Platform.environment['PATH'] ?? '';
    for (final dir in pathEnv.split(';')) {
      if (dir.isEmpty) continue;
      for (final name in names) {
        final candidate = File(
          dir.endsWith('\\') ? '$dir$name' : '$dir\\$name',
        );
        if (candidate.existsSync()) return candidate.path;
      }
    }
    // Fallbacks for nvm4w-style layouts without PATH entries.
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null) {
      final version = Platform.environment['NVM_HOME'];
      if (version != null) {
        final node = File('$version\\node.exe');
        if (node.existsSync()) return node.path;
      }
    }
    return null;
  }
}
