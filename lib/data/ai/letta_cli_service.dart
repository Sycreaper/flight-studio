import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Result of one Letta CLI environment detection pass.
class LettaCliStatus {
  const LettaCliStatus({
    required this.nodeInstalled,
    this.nodeVersion,
    required this.nodeMeetsMinimum,
    required this.lettaInstalled,
    this.lettaVersion,
    this.error,
  });

  final bool nodeInstalled;

  /// e.g. `v24.9.0`.
  final String? nodeVersion;

  /// Whether the installed Node satisfies Letta's ≥ 22.19 requirement.
  final bool nodeMeetsMinimum;

  final bool lettaInstalled;

  /// e.g. `0.33.2`; `null` when the CLI is not installed.
  final String? lettaVersion;

  /// Detection error (rare — e.g. shell unavailable).
  final String? error;

  bool get readyToInstall => nodeInstalled && nodeMeetsMinimum;

  bool get ready => nodeInstalled && nodeMeetsMinimum && lettaInstalled;
}

/// Thrown when an install/uninstall npm command exits non-zero. Carries the
/// tail of the combined output for display.
class LettaCliException implements Exception {
  LettaCliException(this.message, this.outputTail);

  final String message;
  final List<String> outputTail;

  /// Last output lines, most useful for the error UI.
  String get tailText => outputTail.join('\n');

  @override
  String toString() => message;
}

/// Detects, installs and uninstalls the Letta CLI
/// (`@letta-ai/letta-code` via npm) — the local runtime behind Flight
/// Studio's AI copilot.
///
/// Requirements per the Letta docs: Node.js ≥ 22.19 (older npm installs a
/// silently incompatible older Letta Code). All commands run through the
/// system shell so `npm`/`letta` `.cmd` shims resolve on Windows.
class LettaCliService {
  LettaCliService._();

  static final LettaCliService instance = LettaCliService._();

  /// Minimum Node version required by Letta Code (docs: Node.js 22.19+).
  static const int minNodeMajor = 22;
  static const int minNodeMinor = 19;
  static const nodeDownloadUrl = 'https://nodejs.org/en/download';
  static const packageName = '@letta-ai/letta-code';

  /// UTF-8 decoding that never throws on stray bytes (npm progress bars).
  final _utf8Lossy = const Utf8Codec(allowMalformed: true);

  /// Runs one full detection pass. Never throws.
  Future<LettaCliStatus> checkStatus() async {
    final nodeVersion = await _probe('node', ['--version']);
    if (nodeVersion == null) {
      return const LettaCliStatus(
        nodeInstalled: false,
        nodeMeetsMinimum: false,
        lettaInstalled: false,
      );
    }
    final nodeMeetsMinimum = _meetsMinimum(nodeVersion);
    final lettaVersion = nodeMeetsMinimum
        ? await _probe('letta', ['--version'])
        : null;
    return LettaCliStatus(
      nodeInstalled: true,
      nodeVersion: nodeVersion,
      nodeMeetsMinimum: nodeMeetsMinimum,
      lettaInstalled: lettaVersion != null,
      lettaVersion: lettaVersion,
    );
  }

  /// Runs `npm install -g @letta-ai/letta-code`, streaming output lines.
  /// Throws [LettaCliException] on a non-zero exit.
  Future<void> install({void Function(String line)? onOutput}) async {
    await _runStreaming(
      'npm',
      ['install', '-g', packageName],
      failureMessage: 'Letta CLI install failed',
      onOutput: onOutput,
    );
  }

  /// Runs `npm uninstall -g @letta-ai/letta-code`. Throws
  /// [LettaCliException] on a non-zero exit.
  Future<void> uninstall({void Function(String line)? onOutput}) async {
    await _runStreaming(
      'npm',
      ['uninstall', '-g', packageName],
      failureMessage: 'Letta CLI uninstall failed',
      onOutput: onOutput,
    );
  }

  /// Opens the Node.js download page in the user's default browser.
  Future<void> openNodeDownloadPage() async {
    if (Platform.isWindows) {
      await Process.run('cmd', [
        '/c',
        'start',
        '',
        nodeDownloadUrl,
      ], runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.run('open', [nodeDownloadUrl]);
    } else {
      await Process.run('xdg-open', [nodeDownloadUrl]);
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Runs a version-probe command; returns trimmed stdout, or `null` when the
  /// command cannot be found / exits non-zero.
  Future<String?> _probe(String executable, List<String> args) async {
    try {
      final result = await Process.run(
        executable,
        args,
        runInShell: true,
        stdoutEncoding: _utf8Lossy,
        stderrEncoding: _utf8Lossy,
      );
      if (result.exitCode != 0) return null;
      final out = (result.stdout as String).trim();
      return out.isEmpty ? null : out;
    } on Exception catch (_) {
      return null;
    } on Error catch (_) {
      return null;
    }
  }

  Future<void> _runStreaming(
    String executable,
    List<String> args, {
    required String failureMessage,
    void Function(String line)? onOutput,
  }) async {
    final process = await Process.start(executable, args, runInShell: true);
    final sink = _OutputSink(onOutput);
    final stdoutDone = process.stdout
        .transform(_utf8Lossy.decoder)
        .transform(const LineSplitter())
        .forEach(sink.add);
    final stderrDone = process.stderr
        .transform(_utf8Lossy.decoder)
        .transform(const LineSplitter())
        .forEach(sink.addError);
    await Future.wait([stdoutDone, stderrDone]);
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw LettaCliException(
        '$failureMessage (exit code $exitCode)',
        sink.lastLines,
      );
    }
  }

  bool _meetsMinimum(String versionOutput) {
    final match = RegExp(
      r'v?(\d+)\.(\d+)(?:\.(\d+))?',
    ).firstMatch(versionOutput);
    if (match == null) return false;
    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2) ?? '0');
    if (major > minNodeMajor) return true;
    if (major < minNodeMajor) return false;
    return minor >= minNodeMinor;
  }
}

/// Collects streamed process output; keeps a bounded tail for error display.
class _OutputSink {
  _OutputSink(void Function(String line)? onOutput) : _onOutput = onOutput;

  static const int _maxTailLines = 30;

  final void Function(String line)? _onOutput;
  final List<String> _tail = [];
  final List<String> _errors = [];

  void add(String line) {
    if (line.trim().isEmpty) return;
    _tail.add(line);
    if (_tail.length > _maxTailLines) _tail.removeAt(0);
    _onOutput?.call(line);
  }

  void addError(String line) {
    if (line.trim().isEmpty) return;
    _errors.add(line);
    add(line);
  }

  List<String> get lastLines => _errors.isNotEmpty ? _errors : _tail;
}
