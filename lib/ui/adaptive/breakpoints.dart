import 'package:flutter/material.dart';

/// Layout tiers, decided purely by window width:
///
/// - **Wide** (>= [kNarrowBreakpoint]): desktops and tablets in landscape —
///   the full JetBrains-style workspace (side drawers, resize handles,
///   drag-and-drop, card-style welcome nav).
/// - **Narrow** (< [kNarrowBreakpoint]): phones — every drawer and drawer-like
///   surface collapses into a single icon-only rail; tapping an icon opens
///   the drawer as a full-screen overlay.
///
/// The watch tier (pause / live data) is a separate future build target, not
/// a responsive tier of this app.
const double kNarrowBreakpoint = 640;

/// Whether the current window uses the narrow (phone) layout.
bool isNarrowScreen(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
