import 'package:flutter/material.dart';

import '../panels/flight_plan_tree.dart';
import '../panels/inspector_panel.dart';
import '../profile/profile_panel.dart';
import 'workspace_controller.dart';

/// Builds the standard set of dockable drawers shared by every tab:
/// Flight Plans (left), Inspector (right), Profile (bottom).
///
/// Panel **titles are resolved at render time** by `workspace_drawer.dart`
/// (mapping panel `id` → `AppLocalizations` key), so they automatically track
/// the active locale. The `title` field here is just a fallback for custom
/// panels whose id is not one of the three defaults.
List<DrawerPanelData> buildDefaultPanels({
  VoidCallback? onCreateFlightPlan,
}) {
  return [
    DrawerPanelData(
      id: 'flight_plans',
      title: 'Flight Plans',
      icon: Icons.flight_rounded,
      slot: DrawerSlot.left,
      width: 280,
      content: (_) => FlightPlanTree(onCreate: onCreateFlightPlan ?? () {}),
    ),
    DrawerPanelData(
      id: 'inspector',
      title: 'Inspector',
      icon: Icons.tune_rounded,
      slot: DrawerSlot.right,
      width: 280,
      content: (_) => const InspectorPanel(),
    ),
    DrawerPanelData(
      id: 'profile',
      title: 'Profile',
      icon: Icons.show_chart_rounded,
      slot: DrawerSlot.bottom,
      height: 220,
      content: (_) => const ProfilePanel(),
    ),
  ];
}
