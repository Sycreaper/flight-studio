import '../../data/settings/simulator_install.dart';
import 'simulator_connector.dart';
import 'xplane/xplane_connector.dart';

/// Registers every built-in simulator connector. Called once at app startup —
/// the same channel a future plugin manager will use, just invoked earlier.
void registerBuiltInSimConnectors() {
  SimConnectorRegistry.instance.registerFactory(
    SimulatorType.xplane12,
    XPlaneConnector.new,
  );
}
