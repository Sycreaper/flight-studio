import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../data/settings/settings_controller.dart';
import '../data/settings/simulator_install.dart';
import 'simulator_connector.dart';
import 'xplane/xplane_connector.dart';

/// App-wide simulator-link service. Owns the ONE active connector, exposes
/// connection state plus a throttled telemetry [notifier] (≈5 Hz, enough
/// for the map marker and the aircraft panel without rebuilding at the
/// sim's 10 Hz push rate), and auto-connects at startup to the first
/// X-Plane install when the setting allows.
class SimConnectionService extends ChangeNotifier {
  SimConnectionService._();

  static final SimConnectionService instance = SimConnectionService._();

  SimulatorConnector? _connector;
  StreamSubscription<SimTelemetry>? _sub;
  Timer? _throttleTimer;

  /// Throttled latest telemetry (null while disconnected / before the
  /// first position fix). Map marker and panels listen to this.
  final ValueNotifier<SimTelemetry?> telemetry = ValueNotifier(null);

  SimConnectionState _state = SimConnectionState.disconnected;
  String? _error;
  String? _xplaneVersion;

  SimConnectionState get state => _state;
  String? get error => _error;

  /// X-Plane version reported by the probe (after a successful connect).
  String? get xplaneVersion => _xplaneVersion;

  /// Whether the active connector is an X-Plane Web API link.
  bool get isXPlane => _connector is XPlaneConnector;

  /// Auto-connects to the first X-Plane install when the auto-connect
  /// setting is on. Called once at app start (skipped in tests — the
  /// probes would hang without a simulator).
  Future<void> autoConnect(SettingsController settings) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (!settings.value.simAutoConnect) return;
    for (final sim in settings.value.simulators) {
      if (sim.type != SimulatorType.xplane12) continue;
      await connect(sim, settings);
      return;
    }
  }

  /// Connects the X-Plane Web API link for [install], using the
  /// configured port. Sets [error] with a human-readable reason on
  /// failure — never throws.
  Future<void> connect(
    SimulatorInstall install,
    SettingsController settings,
  ) async {
    await disconnect();
    final connector = SimConnectorRegistry.instance
        .create(SimulatorType.xplane12);
    if (connector is XPlaneConnector) {
      connector.webApiPort = settings.value.xplaneWebApiPort;
    }
    _connector = connector;
    _error = null;
    _state = SimConnectionState.connecting;
    notifyListeners();
    try {
      await connector!.connect(install);
      _xplaneVersion =
          connector is XPlaneConnector ? connector.xplaneVersion : null;
      _state = SimConnectionState.connected;
      _sub = connector.telemetry.listen(_onTelemetry);
    } on Exception catch (e) {
      _error = e.message;
      _state = SimConnectionState.error;
      await connector?.disconnect();
      _connector = null;
    }
    notifyListeners();
  }

  void _onTelemetry(SimTelemetry value) {
    // Throttle to ~5 Hz: coalesce pushes into the latest value, flushed
    // on a 200 ms cadence while updates keep arriving.
    telemetry.value = value;
    _throttleTimer ??= Timer(const Duration(milliseconds: 200), () {
      _throttleTimer = null;
    });
    notifyListeners();
  }

  /// Disconnects and clears state.
  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    _throttleTimer?.cancel();
    _throttleTimer = null;
    await _connector?.disconnect();
    _connector = null;
    telemetry.value = null;
    _state = SimConnectionState.disconnected;
    _error = null;
    _xplaneVersion = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(disconnect());
    telemetry.dispose();
    super.dispose();
  }

  /// Test-only: resets all state.
  @visibleForTesting
  void resetForTest() {
    unawaited(disconnect());
  }
}

extension on Exception {
  /// Message without the "Exception: " wrapper.
  String get message => toString().replaceFirst(RegExp('^Exception: '), '');
}
