import 'dart:async';

import '../../data/settings/simulator_install.dart';
import '../simulator_connector.dart';
import 'xplane_web_client.dart';

/// X-Plane 12 connector over the local Web API (v12.1.1+): REST probes
/// the built-in server and resolves dataref names to session ids, the
/// WebSocket streams value updates (~10 Hz) which are merged into
/// [SimTelemetry] snapshots.
///
/// Dataref names follow X-Plane's public flightmodel/cockpit2 paths; any
/// name an aircraft does not expose simply stays unresolved and renders
/// as "—" downstream — resolution failures never fail the connection.
class XPlaneConnector extends SimulatorConnector {
  XPlaneConnector({XPlaneTransport? initialTransport, this.webApiPort = 8086})
      : _transport = initialTransport;

  /// Web API port (X-Plane default 8086; settable from the settings).
  int webApiPort;

  XPlaneTransport? _transport;
  StreamSubscription<Map<int, dynamic>>? _sub;
  final _values = <int, num>{};

  String? _aircraftName;
  String? _xplaneVersion;

  final _telemetry =
      StreamController<SimTelemetry>.broadcast(sync: false);

  @override
  SimulatorType get simulatorType => SimulatorType.xplane12;

  @override
  String get displayName => 'X-Plane 12';

  SimConnectionState _state = SimConnectionState.disconnected;
  @override
  SimConnectionState get state => _state;

  @override
  Stream<SimTelemetry> get telemetry => _telemetry.stream;

  /// The X-Plane version reported by the probe (after connect).
  String? get xplaneVersion => _xplaneVersion;

  // ── Dataref manifest ─────────────────────────────────────────────────────
  // Session ids are looked up by name after connect; names missing from
  // this aircraft's dataref set map to null telemetry fields.

  static const _dLat = 'sim/flightmodel/position/latitude';
  static const _dLon = 'sim/flightmodel/position/longitude';
  static const _dElevM = 'sim/flightmodel/position/elevation';
  static const _dAglFt =
      'sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot';
  static const _dGsMs = 'sim/flightmodel/position/groundspeed';
  static const _dIasKt = 'sim/flightmodel/position/indicated_airspeed';
  static const _dTasKt = 'sim/flightmodel/position/true_airspeed';
  static const _dVsFpm = 'sim/flightmodel/position/vh_ind';
  static const _dHeadingTrue = 'sim/flightmodel/position/psi';
  static const _dHeadingMag =
      'sim/cockpit2/gauges/indicators/heading_AHARS_deg_mag_pilot';
  static const _dRoll = 'sim/flightmodel/position/phi';
  static const _dPitch = 'sim/flightmodel/position/theta';
  static const _dApServos = 'sim/cockpit2/autopilot/servos_on';
  static const _dApAltFt = 'sim/cockpit2/autopilot/altitude_dial_ft';
  static const _dApHeading = 'sim/cockpit2/autopilot/heading_dial_deg';
  static const _dApSpeedKt = 'sim/cockpit2/autopilot/airspeed_dial_kias';
  static const _dApVsFpm = 'sim/cockpit2/autopilot/vvi_dial_fpm';
  static const _dAircraft = 'sim/aircraft/viewer/acfname';

  static const _manifest = <String>{
    _dLat, _dLon, _dElevM, _dAglFt, _dGsMs, _dIasKt, _dTasKt, _dVsFpm,
    _dHeadingTrue, _dHeadingMag, _dRoll, _dPitch,
    _dApServos, _dApAltFt, _dApHeading, _dApSpeedKt, _dApVsFpm, _dAircraft,
  };

  Map<String, int> _ids = const {};

  @override
  Future<void> connect(SimulatorInstall install) async {
    if (_state == SimConnectionState.connected ||
        _state == SimConnectionState.connecting) {
      return;
    }
    _state = SimConnectionState.connecting;
    // Use an injected transport (tests) or create the real Web API client.
    final transport = _transport ?? XPlaneWebClient(port: webApiPort);
    _transport = transport;
    try {
      _xplaneVersion = await transport.probe();
      _ids = await transport.resolve(_manifest);
      await transport.subscribe(_ids.values);
      _sub = transport.updates.listen(_apply, onError: (_) => _fail());
      _state = SimConnectionState.connected;
    } on Exception {
      await transport.dispose();
      _transport = null;
      _state = SimConnectionState.error;
      rethrow;
    }
  }

  void _fail() {
    _state = SimConnectionState.error;
  }

  void _apply(Map<int, dynamic> batch) {
    // Merge this batch into the ACCUMULATED latest values first — the sim
    // only pushes datarefs that CHANGED, so any one batch misses most of
    // the manifest; reading from the accumulation (not the batch) keeps
    // every field stable across updates.
    for (final entry in _ids.entries) {
      final value = batch[entry.value];
      if (value == null) continue;
      if (value is num) {
        _values[entry.value] = value;
      } else if (value is List && value.isNotEmpty && value.first is num) {
        // Array dataref: use the first element (single-value use here).
        _values[entry.value] = value.first as num;
      }
    }

    final lat = _values[_ids[_dLat]];
    final lon = _values[_ids[_dLon]];
    if (lat == null || lon == null) return; // No position fix yet.

    double? opt(String key) => _values[_ids[key]]?.toDouble();

    _telemetry.add(
      SimTelemetry(
        latitude: lat.toDouble(),
        longitude: lon.toDouble(),
        // elevation is metres MSL → feet.
        altitudeFt: (opt(_dElevM) ?? 0) * 3.28084,
        altitudeAglFt: opt(_dAglFt),
        // groundspeed is m/s → knots.
        groundSpeedKt: opt(_dGsMs) == null ? null : opt(_dGsMs)! * 1.94384,
        indicatedAirspeedKt: opt(_dIasKt),
        trueAirspeedKt: opt(_dTasKt),
        verticalSpeedFpm: opt(_dVsFpm),
        headingDeg: opt(_dHeadingTrue),
        headingMagDeg: opt(_dHeadingMag),
        pitchDeg: opt(_dPitch),
        rollDeg: opt(_dRoll),
        autopilotOn: opt(_dApServos) == null ? null : opt(_dApServos)! != 0,
        apAltitudeFt: opt(_dApAltFt),
        apHeadingDeg: opt(_dApHeading),
        apSpeedKt: opt(_dApSpeedKt),
        apVerticalSpeedFpm: opt(_dApVsFpm),
        aircraftName: _aircraftName,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    await _transport?.dispose();
    _transport = null;
    _ids = const {};
    _values.clear();
    _state = SimConnectionState.disconnected;
  }

  @override
  Future<bool> sendCommand(String command) async {
    // Command activation lands with Phase 2 (REST /command/{id}/activate);
    // the audit-gated MCP write tools route through it.
    return false;
  }
}
