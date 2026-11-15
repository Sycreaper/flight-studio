import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/navdata/navdata_types.dart';
import '../../map/map_canvas.dart';

/// The Map tab: the map canvas wired to the nav-visibility set, zoom and
/// fly-to notifiers.
class MapTabView extends StatelessWidget {
  const MapTabView({
    super.key,
    required this.navVisible,
    required this.zoomNotifier,
    required this.flyToTarget,
  });

  final Set<NavPointCategory> navVisible;
  final ValueNotifier<double> zoomNotifier;
  final ValueNotifier<LatLng?> flyToTarget;

  @override
  Widget build(BuildContext context) => MapCanvas(
    navVisible: navVisible,
    zoomNotifier: zoomNotifier,
    flyToTarget: flyToTarget,
  );
}
