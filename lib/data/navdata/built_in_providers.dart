import 'navdata_provider.dart';
import 'providers/xplane_provider.dart';

/// Registers every built-in navdata source. Called once at app startup —
/// the same channel a future plugin manager will use.
void registerBuiltInNavdataProviders() {
  NavdataProviderRegistry.instance.register(XPlaneNavdataProvider());
}
