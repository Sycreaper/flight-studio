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
class SimTelemetry {
  const SimTelemetry({
    required this.latitude,
    required this.longitude,
    required this.altitudeFt,
    this.groundSpeedKt,
    this.headingDeg,
    this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double altitudeFt;
  final double? groundSpeedKt;
  final double? headingDeg;
  final DateTime? timestamp;
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

  Future<void> connect(SimulatorInstall install);

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
