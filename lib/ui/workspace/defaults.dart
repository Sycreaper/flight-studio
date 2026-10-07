import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../panels/conversation_drawer.dart';
import '../panels/flight_plan_tree.dart';
import '../panels/inspector_panel.dart';
import '../panels/search_panel.dart';
import '../profile/profile_panel.dart';
import 'workspace_controller.dart';

/// Builds the standard set of dockable drawers shared by every tab:
/// Search (right), Flight Plans (left), Conversations (left), Inspector
/// (right), Profile (bottom).
///
/// Panel **titles are resolved at render time** by `workspace_drawer.dart`
/// (mapping panel `id` → `AppLocalizations` key), so they automatically track
/// the active locale. The `title` field here is just a fallback for custom
/// panels whose id is not one of the defaults.
List<DrawerPanelData> buildDefaultPanels({
  VoidCallback? onCreateFlightPlan,
  ValueChanged<LatLng>? onFlyTo,
  VoidCallback? onCreateChat,
  ValueChanged<String>? onOpenConversation,
}) {
  return [
    DrawerPanelData(
      id: 'search',
      title: 'Search',
      icon: Icons.search_rounded,
      slot: DrawerSlot.right,
      width: 280,
      content: (_) => SearchPanel(onFlyTo: onFlyTo ?? (_) {}),
    ),
    DrawerPanelData(
      id: 'flight_plans',
      title: 'Flight Plans',
      icon: Icons.flight_rounded,
      slot: DrawerSlot.left,
      width: 280,
      content: (_) => FlightPlanTree(onCreate: onCreateFlightPlan ?? () {}),
    ),
    DrawerPanelData(
      id: 'conversations',
      title: 'Conversations',
      icon: Icons.chat_bubble_outline_rounded,
      slot: DrawerSlot.left,
      width: 280,
      content: (_) => ConversationDrawer(
        onCreateChat: onCreateChat ?? () {},
        onOpenConversation: onOpenConversation ?? (_) {},
      ),
    ),
    DrawerPanelData(
      id: 'inspector',
      title: 'Inspector',
      icon: Icons.tune_rounded,
      slot: DrawerSlot.right,
      width: 280,
      content: (_) => InspectorPanel(onFlyTo: onFlyTo ?? (_) {}),
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
