import 'package:flutter/foundation.dart';

import '../data/settings/simulator_install.dart';
import '../plugins/extension_registry.dart';

/// Connection lifecycle of a simulator link.
enum SimConnectionState { disconnected, connecting, connected, error }

/// One live telemetry snapshot streamed by a connected simulator.
///
/// Minimal by design — Phase 4's UDP reader decides the real field set; the
/// seam stays stable for plugins that bridge other simulators.
@immutable
/// One live telemetry snapshot from the connected simulator.
///
/// Field semantics follow X-Plane's Web API datarefs where applicable;
/// connectors for other sims map onto the same shape. Everything beyond
/// the five required fields is optional — panels render missing values
/// as "—" (aircraft vary in what they expose).
@immutable
class SimTelemetry {
  const SimTelemetry({
    required this.latitude,
    required this.longitude,
    required this.altitudeFt,
    this.groundSpeedKt,
    this.headingDeg,
    this.timestamp,
    this.altitudeAglFt,
    this.indicatedAirspeedKt,
    this.trueAirspeedKt,
    this.verticalSpeedFpm,
    this.headingMagDeg,
    this.pitchDeg,
    this.rollDeg,
    this.autopilotOn,
    this.apAltitudeFt,
    this.apHeadingDeg,
    this.apSpeedKt,
    this.apVerticalSpeedFpm,
    this.aircraftName,
  });

  final double latitude;
  final double longitude;

  /// Barometric altitude above MSL, feet.
  final double altitudeFt;
  final double? groundSpeedKt;

  /// True heading, degrees.
  final double? headingDeg;
  final DateTime? timestamp;

  /// Radio altitude above ground, feet.
  final double? altitudeAglFt;
  final double? indicatedAirspeedKt;
  final double? trueAirspeedKt;

  /// Indicated vertical speed, feet per minute.
  final double? verticalSpeedFpm;

  /// Magnetic heading, degrees.
  final double? headingMagDeg;
  final double? pitchDeg;
  final double? rollDeg;

  // ── Autopilot ────────────────────────────────────────────────────────────

  /// Autopilot servos engaged.
  final bool? autopilotOn;

  /// Autopilot altitude window, feet.
  final double? apAltitudeFt;

  /// Autopilot heading window, degrees.
  final double? apHeadingDeg;

  /// Autopilot speed window, knots.
  final double? apSpeedKt;

  /// Autopilot vertical-speed setting, feet per minute.
  final double? apVerticalSpeedFpm;

  /// Aircraft display name (e.g. "Boeing 737-800").
  final String? aircraftName;
}

/// Seam for a live simulator link — one implementation per simulator (built-in
/// X-Plane 12 today; MSFS/P3D bridge daemons and third-party bridges later).
///
/// A connector instance is bound to one [SimulatorInstall]; create fresh
/// instances through the [SimConnectorRegistry] factory for each connection.
abstract class SimulatorConnector {
  SimulatorType get simulatorType;

  /// Human-readable connector name (may differ from the sim's, e.g. the
  /// MSFS SimConnect bridge).
  String get displayName;

  SimConnectionState get state;

  /// Live telemetry stream; empty until [connect] succeeds.
  Stream<SimTelemetry> get telemetry;

  /// Connects to the simulator at [install].
  Future<void> connect(SimulatorInstall install);

  /// Disconnects from the simulator.
  Future<void> disconnect();

  /// Sends a simulator-side command (e.g. a FlyWithLua `command_once`).
  /// Returns whether the command was accepted by the link.
  Future<bool> sendCommand(String command);
}

/// Creates a fresh connector instance bound to one install.
typedef SimulatorConnectorFactory = SimulatorConnector Function();

/// Registry of simulator integrations. This — not an enum flag — decides
/// which [SimulatorType]s are connectable today; settings UI derives its
/// "coming soon" badges from [isSupported]. Built-ins are registered at
/// startup via `registerBuiltInSimConnectors()`.
class SimConnectorRegistry
    extends ExtensionRegistry<SimulatorConnectorFactory> {
  SimConnectorRegistry._() : super(idOf: (_) => '');

  static final SimConnectorRegistry instance = SimConnectorRegistry._();

  /// Registers a connector factory under the sim type's persisted name.
  void registerFactory(SimulatorType type, SimulatorConnectorFactory factory) {
    register(factory, id: type.persistedName);
  }

  /// Whether a connector is registered for [type] (i.e. connectable today).
  bool isSupported(SimulatorType type) => byId(type.persistedName) != null;

  /// Creates a new connector instance for [type], or `null` when unsupported.
  SimulatorConnector? create(SimulatorType type) =>
      byId(type.persistedName)?.call();
}
