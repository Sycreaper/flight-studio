import 'package:flutter/material.dart';

import '../../map/map_canvas.dart';
import '../../workspace/defaults.dart';
import '../../workspace/workspace_controller.dart';
import '../../workspace/workspace_view.dart';

/// A "Map" tab. The map canvas is the core card at the centre; everything else
/// (flight plans, inspector, profile) is a dockable drawer managed by the
/// workspace. Drawers can be dragged between the left / right / bottom slots.
class MapTabView extends StatefulWidget {
  const MapTabView({super.key, this.onCreateFlightPlan});

  final VoidCallback? onCreateFlightPlan;

  @override
  State<MapTabView> createState() => _MapTabViewState();
}

class _MapTabViewState extends State<MapTabView> {
  late final WorkspaceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WorkspaceController();
    for (final p
        in buildDefaultPanels(onCreateFlightPlan: widget.onCreateFlightPlan)) {
      _controller.register(p);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WorkspaceView(
      controller: _controller,
      center: const MapCanvas(),
    );
  }
}
