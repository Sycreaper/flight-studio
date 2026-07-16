import 'package:flutter/material.dart';

import '../../map/map_canvas.dart';

/// The center card for a Map tab: just the chart canvas. The surrounding
/// workspace (drawers, docks, sizes) is owned by the app shell and shared
/// across all tabs, so switching tabs only swaps this center.
class MapTabView extends StatelessWidget {
  const MapTabView({super.key});

  @override
  Widget build(BuildContext context) => const MapCanvas();
}
