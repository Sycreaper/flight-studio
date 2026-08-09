# Flight Studio

An open-source, cross-platform **flight simulator route planner** and **live flight
tracker** built with Flutter. Plan routes with SID/STAR/approach procedures, track
your flight in real time, and monitor or control the simulator remotely from your
phone or web browser.

[![License: MIT](https://img.shields.io/badge/License-MIT-ff7f27.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Android%20%7C%20iOS%20%7C%20Web-blue)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)]()
[![Status](https://img.shields.io/badge/Status-Pre--alpha-red)]()

> Inspired by the design philosophy of [Little Navmap](https://github.com/albar965/littlenavmap).
> No source code is derived from that project (which is GPL-3.0); Flight Studio is a
> clean-room reimplementation released under the permissive MIT license.

---

## Features

### Route Planning

- **Dual route sources** behind one model:
    - **Local A\* engine** — automatic route calculation over the airway network, with multi-factor cost adjustments and
      altitude-range pruning to select Jet/Victor airways.
    - **SimBrief import** — pull an OFP/FMS from the user's own SimBrief account (OAuth2) into the same flight plan;
      Flight Studio adds value on top instead of competing with SimBrief's network effect.
- **SID / STAR / Approach** procedure resolution following ARINC 424 leg types
  (`IF`, `TF`, `CF`, `DF`, `RF`, ...).
- **Interactive route editor** on a live map — drag, insert, delete waypoints.
- **Trust layer** — every plan shows its data source, AIRAC cycle, procedure availability and aircraft compatibility;
  import/export validate AIRAC consistency.
- **Altitude & fuel profile** charts (climb / cruise / descent).
- **Multi-format export** so one plan flies across simulators:
  | Format | Simulators |
  | --- | --- |
  | FMS 1100 | X-Plane 11 / 12 |
  | PLN | FSX, Prepar3D, MSFS 2020 / 2024 |
  | FLP | Aerosoft Airbus / CRJ |
  | GPX | Universal exchange |

### Live Flight Tracking
- Real-time aircraft position, attitude, speed and fuel overlaid on the map.
- Flight path recording with active-leg highlighting.
- Progress information: distance / ETA / remaining fuel to destination.

### Simulator Connectivity
- **X-Plane 12** — native UDP telemetry plus command control via a bundled
  [FlyWithLua](https://github.com/X-Friese/FlyWithLua) bridge script (pause,
  autopilot, and any third-party aircraft command).
- **MSFS 2020 / 2024 & Prepar3D** — through a C++ bridge daemon wrapping the
  SimConnect SDK (planned).
- **FlyByWire A32NX MCDU** — remote control of the MCDU via SimBridge port
  forwarding (MSFS, planned).

### Remote Monitoring & Control
- An embedded server (in-process) exposes the live flight state over WebSocket and
  a route CRUD API over REST.
- Companion **mobile** and **web** clients connect over LAN (or the internet) to
  watch the moving map, pause the sim, toggle autopilot modes, and operate the
  MCDU remotely.

### AI Copilot (Bring Your Own Key)

- A built-in assistant you power with **your own** LLM API key (OpenAI-compatible, Anthropic, local Ollama, ...).
- Uses an **MCP-style tool registry**: the model can only act through deterministic tools — it **never computes routes
  or writes files itself**. Route calculation, flight-plan export and simulator commands are exposed as tools that call
  the same trusted core the UI uses.
- Read tools surface navdata, flight records, live telemetry, AIRAC and weather; write tools (export, **sim/Lua
  commands** such as gear or altitude window)
  **require user confirmation** before executing.
- Lives in a workspace drawer; future use cases include Route Copilot, pre-flight onboarding and a post-flight coach.

### Cross-Platform
Desktops (Windows first, then macOS / Linux), all Flutter-supported mobile
platforms, the web, and a future HarmonyOS NEXT target via the OpenHarmony-SIG
Flutter fork.

---

## Supported Simulators

| Simulator | Status | Connection |
| --- | --- | --- |
| X-Plane 12 | Planned (MVP target) | UDP telemetry + FlyWithLua commands |
| MSFS 2020 / 2024 | Planned | C++ SimConnect bridge daemon |
| Prepar3D v4 / v5 / v6 | Planned | SimConnect bridge daemon (shared) |

---

## Navigation Data

Flight Studio ingests navigation data from multiple sources:

- **Default (bundled/downloadable, free & open):**
  - [OurAirports](https://ourairports.com/data/) (Public Domain) — airports, runways, frequencies, navaids.
  - [FAA CIFP / NASR](https://www.faa.gov/air_traffic/flight_info/aeronav/aero_data/) (Public Domain) — U.S. instrument procedures.
- **Simulator-native:** parses X-Plane 12's `apt.dat`, `earth_nav.dat`,
  `earth_fix.dat`, `awy.dat` and CIFP terminal procedures directly.
- **Navigraph (optional, user-provided):** end users sign in with their own
  Navigraph subscription via OAuth2; data is never bundled or redistributed.
- **SimBrief (optional, user-provided):** users link their own SimBrief account to import OFPs and route strings;
  nothing is redistributed.

---

## Screenshots

> _Coming soon._

---

## Getting Started

### Prerequisites
- Flutter 3.x (stable)
- An X-Plane 12 install (for the MVP target)

### Build & Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows
```

### Connect to X-Plane 12

1. Install the [FlyWithLua NG Plus](https://forums.x-plane.org) plugin into
   `<X-Plane>/Resources/plugins/`.
2. Copy the bundled bridge script `FlightStudioBridge.lua` into
   `<X-Plane>/Resources/plugins/FlyWithLua/Scripts/`.
3. Enable **Data Output** in X-Plane (Settings → Data Output) for the rows you
   wish to stream.
4. Launch Flight Studio and point it at your X-Plane installation.

---

## Architecture

Flight Studio follows a layered architecture that keeps all business logic free of
Flutter/UI dependencies, so the same core can later be packaged for mobile, web and
HarmonyOS clients.

```
lib/
├── core/        Pure logic (geo, navdata models, parsers, A* routing, exporters)
├── domain/      Cloud-ready domain model (Pilot/Aircraft/Intent/FlightRecord)
├── data/        Drift/SQLite persistence + repositories + navdata importer
├── sim/         Simulator adapters (X-Plane UDP + FlyWithLua, MSFS bridge, MCDU proxy)
├── ai/          BYOK LLM providers + MCP tool registry (deterministic tools)
├── server/      Embedded shelf HTTP/WebSocket server for remote clients
├── ui/          Flutter widgets — JetBrains IDEA-style shell, map, panels, profile
└── shared/      Common utilities and extensions
```

### Design notes
- **Routing engine:** A\* search with multi-factor cost adjustments (airway-change
  penalty, NDB avoidance, NAT preference, ...) and along-path altitude-range
  merging for pruning — following the approach documented publicly by Little
  Navmap, implemented from scratch.
- **Domain model:** four core objects — `PilotProfile`, `AircraftState`,
  `FlightIntent`, `FlightRecord` — designed up front with stable ids, timestamps and JSON so an optional cloud sync /
  profile / social layer can be added later without rework. Repositories are abstracted (local today, cloud-ready).
- **X-Plane control:** telemetry is read over the simulator's UDP Data Output;
  commands are sent as JSON over UDP to a tiny FlyWithLua bridge script
  (`command_once` / `dataref` access, including third-party aircraft commands).
- **Remote access:** the desktop app hosts a `shelf` server in-process with
  token-based authentication, relaying telemetry and (for MSFS) proxying the
  FlyByWire SimBridge MCDU WebSocket.
- **AI as conductor, not calculator:** the assistant is constrained to call MCP tools for anything with side effects.
  `compute_route`, `export_flight_plan`
  and `send_sim_command` are deterministic Dart — the model decides *what* to invoke, the trusted core does the actual
  work. A stdio MCP server may be exposed later so external clients (e.g. Claude Desktop) can reuse the same tools.

---

## Roadmap

**MVP boundary = Phases 1–4** (X-Plane 12 planner + tracker). Phases 5+ are growth.

- [x] **Phase 0** — Project foundation: layered `lib/`, JetBrains-style workspace (tabs, tool docks, drawers, resizable
  cards, custom window chrome), theme, i18n. Settings system with live theme/locale switch, gear popup menu,
  floating-window dialogs, API key vault, map tile provider integration (flutter_map + OSM/Mapbox/custom), workspace
  layout persistence (drawer sizes + visibility survive restart).
- [/] **Phase 1** — Domain core & data models: four cloud-ready objects (`PilotProfile`/`AircraftState`/`FlightIntent`/
  `FlightRecord`), abstract repositories, drift schema, coordinate/unit utils. Reserves the `lib/ai/`
  scaffold (`McpTool` registry, BYOK `LlmProvider` interface, credential hook). Domain models, geo/unit utils, drift
  schema, repository interfaces, and AI scaffold are **done**; remaining work wires the drift database to real data and
  populates the MCP tool registry.
- [ ] **Phase 2** — X-Plane navdata + map: stream-parse `apt.dat`/`earth_nav`/
  `fix`/`awy`/CIFP → SQLite, flutter_map rendering, airport search. Registers read-only MCP tools.
- [ ] **Phase 3** — Route planning (dual source): local A\* engine + SimBrief import behind one `RouteSource`,
  SID/STAR/approach, trust layer + AIRAC validation, multi-format export (FMS/PLN/FLP/GPX). Registers
  `compute_route` / `export_flight_plan` MCP tools.
- [ ] **Phase 4** — X-Plane live tracking: UDP telemetry + FlyWithLua bridge, live position + trail + active-leg
  highlight (no debrief yet). Registers telemetry/sim-command MCP tools.
- [ ] **Phase 5** — Remote monitor & control: embedded shelf server, web + mobile companion (view / pause / autopilot),
  mDNS discovery.
- [ ] **Phase 6** — MSFS support: C++ SimConnect bridge daemon, MSFS/P3D adapter, FlyByWire SimBridge MCDU proxy,
  Navigraph OAuth2.
- [ ] **Phase 7** — Optional cloud: activate sync-ready repositories for flight records, pilot profile, aircraft
  continuity and lightweight social.
- [ ] **Phase 8** — Debrief engine: structured plan-vs-actual scoring (route deviation, altitude/fuel, approach
  stability). Feeds the AI coach.
- [ ] **Phase 9** — AI assistant (BYOK + MCP): chat drawer, provider settings, wire the LLM to the tool registry
  populated in Phases 3/4/8 — Route Copilot, pre-flight onboarding, post-flight coach. Optional stdio MCP server for
  external clients.
- [ ] **Future** — Platform expansion: macOS/Linux desktop, HarmonyOS NEXT, NOAA weather (GRIB2 + METAR/TAF), aircraft
  performance collection, progressive-disclosure newbie mode, aircraft import-compatibility matrix.

> Cross-cutting throughout: English/Chinese i18n, light-theme readiness,
> cloud-sync-ready models, MIT compliance (clean-room reimplementation;
> Navigraph/SimBrief data user-brought, never redistributed).

---

## Contributing

Contributions are welcome. Please open an issue first to discuss what you would
like to change. This project follows the standard `fork → branch → pull request`
workflow.

---

## License

Released under the **MIT License** — see [LICENSE](LICENSE).

Third-party data and assets carry their own terms (see
`LICENSE-THIRD-PARTY`); notably:
- Navigation data from Navigraph is user-licensed and never redistributed.
- OpenStreetMap tiles are © OpenStreetMap contributors (ODbL).
- OurAirports data is Public Domain.
- FAA CIFP / NASR data is Public Domain (U.S. Government work).

---

## Acknowledgments

- **[Little Navmap](https://github.com/albar965/littlenavmap)** by Alexander Barthel
  — the gold standard that inspires this project's feature set and UX. We study its
  public documentation and algorithm descriptions only; no GPL source is reused.
- **[FlyWithLua](https://github.com/X-Friese/FlyWithLua)** (MIT) — the X-Plane
  scripting bridge.
- **[SimBrief](https://www.simbrief.com)** — the de-facto flight-planning service, integrated as a user-brought data
  source.
- **[flutter_map](https://github.com/fleaflet/flutter_map)** and the Fleaflet
  community.
- The **X-Plane**, **MSFS** and **Prepar3D** developer communities for their open
  SDK documentation.
