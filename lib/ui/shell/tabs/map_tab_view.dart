import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/navdata/navdata_types.dart';
import '../../../sim/sim_connection_service.dart';
import '../../map/map_canvas.dart';

/// The Map tab: the map canvas wired to the nav-visibility set, zoom and
/// fly-to notifiers, plus the live aircraft telemetry from the simulator
/// link (marker toggled by the legend's Aircraft chip).
class MapTabView extends StatelessWidget {
  const MapTabView({
    super.key,
    required this.navVisible,
    required this.zoomNotifier,
    required this.flyToTarget,
    this.planeVisible = true,
  });

  final Set<NavPointCategory> navVisible;
  final ValueNotifier<double> zoomNotifier;
  final ValueNotifier<LatLng?> flyToTarget;

  /// Whether the plane marker is shown (legend toggle, owned by the shell).
  final bool planeVisible;

  @override
  Widget build(BuildContext context) => MapCanvas(
    navVisible: navVisible,
    zoomNotifier: zoomNotifier,
    flyToTarget: flyToTarget,
    planeTelemetry: SimConnectionService.instance.telemetry,
    planeVisible: planeVisible,
  );
}
