import '../../data/settings/simulator_install.dart';
import '../simulator_connector.dart';

/// X-Plane 12 connector skeleton — UDP Data Output telemetry plus the
/// FlyWithLua command bridge.
///
/// Registration (not implementation) is the point today: type support across
/// the app is derived from [SimConnectorRegistry.isSupported], so the
/// built-in must be present in the registry even before Phase 4 wires the
/// actual UDP/Lua link.
class XPlaneConnector extends SimulatorConnector {
  @override
  SimulatorType get simulatorType => SimulatorType.xplane12;

  @override
  String get displayName => 'X-Plane 12';

  @override
  SimConnectionState get state => SimConnectionState.disconnected;

  @override
  Stream<SimTelemetry> get telemetry => const Stream.empty();

  @override
  Future<void> connect(SimulatorInstall install) async {
    throw UnimplementedError('X-Plane UDP telemetry lands in Phase 4.');
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> sendCommand(String command) async => false;
}
