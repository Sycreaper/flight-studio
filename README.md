# Flight Studio

An open-source, cross-platform **AI flight agent workbench** built with Flutter.
Chat with a Letta-powered copilot that plans, briefs and tracks simulator
flights — grounded in real navdata, with full manual planning tools and remote
monitoring.

[![License: MIT](https://img.shields.io/badge/License-MIT-ff7f27.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Android%20%7C%20iOS%20%7C%20Web-blue)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B)]()
[![Status](https://img.shields.io/badge/Status-Pre--alpha-red)]()

> **Current status: early alpha / developer preview.**
> The current build provides the Flutter workbench (map, navdata import,
> airport inspector), the local Agent Gateway, the BYOK copilot with
> multi-conversation management, and a first set of read-only
> FlightStudio Core MCP tools (airport dossier / charts / weather).
> **X-Plane telemetry and simulator commands are NOT implemented yet**
> (the connector is a skeleton), and remote monitoring, MSFS/P3D, the
> plugin runtime and official binary releases are not yet available.
> CI validates static analysis, unit/widget tests, gateway tests and
> Windows/Android debug builds — not a real simulator connection.

> Inspired by the design philosophy of [Little Navmap](https://github.com/albar965/littlenavmap).
> No source code is derived from that project (which is GPL-3.0); Flight Studio is a
> clean-room reimplementation released under the permissive MIT license.

---

## What works today

The feature list below separates what you can actually run now from what is
still in progress or planned — so you don't have to reverse-engineer maturity
from the roadmap.

| Capability | Status | Evidence |
| --- | --- | --- |
| Flutter desktop workbench (tabs, drawers, map, inspector) | ✅ Available | CI builds Windows debug |
| X-Plane navdata import (`apt.dat`/`earth_*`/`awy.dat`) | ✅ Available | Parser smoke tests on real data |
| Airport inspector (runways, ATC frequencies, METAR/TAF, sunrise/sunset) | ✅ Available | Widget tests |
| Local Agent Gateway (`agent_gateway/`) + one-click setup | ✅ Available | Gateway test job in CI |
| BYOK copilot, streaming replies, multi-conversation drawer, titles, Markdown export | ✅ Available (developer-grade) | End-to-end against a local Letta backend |
| FlightStudio Core MCP tools (airport dossier / charts / weather), L0–L3 approval cards | ✅ First batch (read-only) | Unit + stdio smoke tests |
| ChartFox chart browser (browser login + inspector Charts tab) | 🧪 Experimental | Needs a ChartFox account; live API |
| L2+ tools (app-state reads, writes, simulator commands) | 🚧 Planned | Ladder exists, no tools yet |
| X-Plane UDP telemetry / FlyWithLua commands | 🚧 Planned | `XPlaneConnector` is a skeleton (`connect()` throws) |
| Local A\* routing, SID/STAR/approach, export formats | 🚧 Planned | Roadmap Phase 3 |
| Remote monitoring & mobile/web companions | 🚧 Planned | Roadmap Phase 5 |
| MSFS / Prepar3D connectors | 🚧 Planned | Roadmap Phase 6 |
| Plugin runtime (QuickJS sandbox), Plugin Center | 🚧 Planned | Roadmap Phase 9; registries only |
| Official binary releases (Windows installer / Android APK) | 🚧 Planned | CI publishes debug artifacts only |

---

## Features

> Status markers: **[Available now]** runs in the current build, **[Planned]**
> is design/target only. See *What works today* above for details.

### AI Copilot (Letta + Agent Gateway) — [Available now]

- **A long-term co-pilot brain, not a chatbot** — Flight Studio runs a local **TypeScript Agent Gateway**
  (`agent_gateway/`) on top of the official
  [Letta Agent SDK](https://docs.letta.com/agent-sdk). One local agent — the
  flight assistant (飞行助理) — with persistent memory blocks (user profile,
  aircraft preferences, learning history, safety preferences), so the copilot
  gets to know the pilot over time. Letta itself stores the conversation
  history — the app never re-implements it.
- **Gateway architecture** — the Flutter app only speaks a small HTTP + SSE
  API (`/agent/message`, `/agent/conversations`, `/agent/events/{sessionId}`,
  `/agent/approval/{id}`, `/agent/status`, `/agent/memory/update`); Letta
  protocol details (streaming, permissions, skills, tools) live entirely in
  the gateway. The local backend auto-starts a Letta App Server subprocess;
  switching to a remote backend later requires zero Flutter changes.
- **One copilot, many conversations** — a single Letta agent (the flight
  assistant) backs every conversation. The conversation drawer lists all
  conversations with auto-generated titles (LLM-summarized after the first
  exchange); deleting a conversation removes its Letta-side data through the
  official API.
- **Welcome-screen chat** — talk to your agent right from the home screen;
  replies stream over the gateway's SSE channel, with a stop button while
  generating.
- **One-click setup** — Settings → AI detects Node.js 22.19+, installs the
  gateway dependencies and starts the service; model providers (OpenAI-compatible, Anthropic, Ollama/LM Studio) connect
  through Letta.
  Bring your own key.
- **Safety-first roadmap** — explain-first: read-only tools (navdata / charts /
  weather / briefing) land before any simulator write action. The copilot runs
  in strict permission mode: **every** tool call — including the harness's own
  command tools — surfaces as an embedded approval card in the transcript;
  nothing runs silently. On top of that, a user-picked access ladder
  (L0 None → L1 public aeronautical data → L2 app-state reads → L3 full
  access, persistent per pilot) bounds what can even be requested.
  (Future: time-critical actions like a go-around may auto-run after a
  countdown — deliberately not implemented yet.)

### Route Planning — [Planned]

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

### Live Flight Tracking — [Planned]

Depends on the X-Plane telemetry connector (roadmap Phase 4 / Sprint D).

- Real-time aircraft position, attitude, speed and fuel overlaid on the map.
- Flight path recording with active-leg highlighting.
- Progress information: distance / ETA / remaining fuel to destination.

### Simulator Connectivity — [Planned]

> None of the connectors work in the current build — `XPlaneConnector`
> throws `UnimplementedError` on `connect()`. The X-Plane steps further
> below describe the *intended* setup.

- **X-Plane 12** — native UDP telemetry plus command control via a bundled
  [FlyWithLua](https://github.com/X-Friese/FlyWithLua) bridge script (pause,
  autopilot, and any third-party aircraft command).
- **MSFS 2020 / 2024 & Prepar3D** — through a C++ bridge daemon wrapping the
  SimConnect SDK.
- **FlyByWire A32NX MCDU** — remote control of the MCDU via SimBridge port
  forwarding (MSFS).

### Remote Monitoring & Control — [Planned]

The gateway is currently **single-instance and single-session** (bound to
`127.0.0.1`); remote multi-client use is not yet supported. The embedded
server below lands with roadmap Phase 5, together with session binding,
per-client tokens and scoped stop/approval semantics.

- An embedded server (in-process) exposes the live flight state over WebSocket and
  a route CRUD API over REST.
- Companion **mobile** and **web** clients connect over LAN (or the internet) to
  watch the moving map, pause the sim, toggle autopilot modes, and operate the
  MCDU remotely.

### Cross-Platform — [Partially verified]

Windows and Android build in CI (debug builds only). macOS, Linux, web and
HarmonyOS NEXT are unverified targets, not advertised capabilities.

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

## Plugin System (Extensibility)

Flight Studio is designed around a three-layer extensibility architecture so
third-party developers can add functionality safely without forking the app:

1. **Internal extension points** — everything a plugin could do, first-party
   features already do through the same registries: workspace tab/panel factories,
   flight-plan exporters & importers, simulator connectors, navdata providers and
   AI (MCP) tools. No hard-coded switches; new capability = new registration.
2. **Script plugins (v1)** — plugins are written in **JavaScript** and run inside
   an embedded **QuickJS** sandbox (`plugins/<id>/plugin.json` manifest + entry
   script). The sandbox exposes only a curated host API — map layers & markers,
   UI slots, navdata (read-only), network access proxied through the app with
   per-scope permissions, and namespaced key-value settings. The Plugin Center
   handles installing, enabling/disabling and permission prompts.
3. **Out-of-process connectors (later)** — heavyweight integrations (simulator
   bridges, external data services) run as separate processes talking JSON-RPC
   over stdio/named pipes: language-agnostic and crash-isolated.

### UI capability tiers

- **Predefined slots** (default permission) — workspace tabs, panels, map layers,
  status-bar widgets, legend categories, settings sections.
- **Free-form canvas** (special permission) — full drawing-surface access,
  granted only after dedicated review; such plugins are marked distinctly in the
  marketplace.

> Planned far out: a built-in **Lua editor** (syntax highlighting, autocompletion,
> LSP integration, AI coding agent) so users can comfortably write and maintain
> FlyWithLua scripts for X-Plane.

---

## Screenshots

> _Coming soon — the UI is stable enough for daily development use but is
> still changing fast. Until captures exist, treat the feature matrix above
> as the source of truth._

---

## Getting Started

### Prerequisites & compatibility matrix

| Component | Tested version | Notes |
| --- | --- | --- |
| Flutter | 3.44.5 (CI-pinned) | Debug builds only; no release packaging yet |
| Dart | 3.12.2+ | Follows the Flutter version |
| Node.js | 22.19+ | Agent Gateway; detected by Settings → AI |
| Letta Agent SDK | 0.8.x (`^0.8.26`) | May drift — the gateway adapter isolates it |
| Letta Code | 0.34.0 (pinned) | Local app-server backend |
| Windows | CI debug build | The only verified desktop target |
| Android | CI debug APK | Not published as a release |
| macOS / Linux / Web | Not in CI | Not verified — do not assume they work |

- Required: Flutter 3.44 stable (or matching Dart 3.12 SDK) to build from
  source — no prebuilt binaries are published yet.
- Optional: [Node.js](https://nodejs.org/en/download) 22.19+ for the AI
  copilot (the app detects it and guides the install).
- Optional later: an X-Plane 12 install — only needed once the telemetry
  connector ships (planned, see *What works today*).

### Start the AI service (copilot)

The AI copilot runs on a local **Agent Gateway** (`agent_gateway/`) built on
the official [Letta Agent SDK](https://docs.letta.com/agent-sdk).

1. Install [Node.js](https://nodejs.org/en/download) 22.19+ (the app detects
   it and guides the install).
2. Install gateway dependencies:

   ```bash
   cd agent_gateway
   npm install
   ```

   Or use **Settings → AI** inside Flight Studio for one-click install + start.
3. Start the gateway (the app also starts it automatically in the background):

   ```bash
   npm run start:dev
   ```

   The first launch creates a local copilot agent — no account/login needed;
   agent state stays on your machine.
4. Connect a model provider **inside Flight Studio**: add an
   OpenAI-compatible API key under Settings → API keys (BYOK — your key is
   never uploaded anywhere except the local Letta backend's provider store).
   The app pushes the credential to the gateway before every turn; the
   legacy Letta-CLI `/connect` flow still works too (the CLI shares agent
   state with the gateway).
5. In Flight Studio, start chatting — the copilot agent is created on first
   launch, and every conversation is managed through the conversation drawer.

### Build & Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows
```

### Connect to X-Plane 12 — [Planned, does not work in this build]

> The telemetry connector is not implemented yet (`connect()` throws
> `UnimplementedError`); the UI shows the integration as planned. The steps
> below describe the intended setup for when it lands (roadmap Phase 4).

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
├── ai/          Letta gateway client (HTTP + SSE), BYOK LLM providers
├── mcp/         FlightStudio Core — the app's stdio MCP server (tools the
│                Letta agent calls: airport dossier, charts, weather), plus
│                the L0–L3 safety ladder levels and the audited tool-invocation
│                log (mcp-audit.sqlite); entry point bin/mcp_flightstudio_core.dart
├── plugins/     Extension-point registries (tabs, exporters, sim connectors,
│                navdata providers) — the seams third-party plugins will use
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
- **X-Plane control [Planned]:** telemetry would be read over the
  simulator's UDP Data Output;
  commands would be sent as JSON over UDP to a tiny FlyWithLua bridge script
  (`command_once` / `dataref` access, including third-party aircraft
  commands). None of this exists in the current build.
- **Remote access [Planned]:** the desktop app would host a `shelf` server
  in-process with token-based authentication, relaying telemetry and (for
  MSFS) proxying the FlyByWire SimBridge MCDU WebSocket. Not implemented —
  the gateway today is single-instance and single-session, bound to
  127.0.0.1.
- **AI as conductor, not calculator:** the assistant is constrained to call MCP tools for anything with side effects.
  `compute_route`, `export_flight_plan`
  and `send_sim_command` are deterministic Dart — the model decides *what* to invoke, the trusted core does the actual
  work. The tools live in **FlightStudio Core**, a Dart stdio MCP server (`bin/mcp_flightstudio_core.dart`) the
  gateway mounts per Letta session — external MCP clients (e.g. Claude Desktop) can reuse the same server.
- **Extensibility:** first-party features and third-party plugins go through the same registries (tab factories,
  exporters, sim connectors, navdata providers, MCP tools). Script plugins run in a QuickJS JavaScript sandbox;
  free-form-canvas UI access is permission-gated and marketplace-reviewed. Heavyweight connectors (sim bridges) may
  run out-of-process over JSON-RPC for crash isolation.

---

## Troubleshooting (user FAQ)

Symptom-oriented fixes for the features that exist in this build. (The
maintainer postmortem behind the BYOK wiring lives in
[`docs/maintainers/byok-debugging.md`](docs/maintainers/byok-debugging.md).)

**The copilot replies with a gateway/provider error.**
The error text is shown verbatim in the chat bubble — it names the failing
stage. "gateway not ready" means the local gateway did not start: open
Settings → AI and use one-click install/start, and check that Node.js
22.19+ is installed. Provider errors (401/404/model not found) mean the
API key or base URL is wrong for the selected model — retest the key under
Settings → API keys (Test button, capped at 20 s).

**I sent a message and nothing streams back.**
Check that a model is selected in the model chip below the prompt box, and
that the provider test passes (see above). If a turn got stuck (possible
after a crash), sending the next message aborts it automatically.

**A tool-permission card appeared — is this normal?**
Yes. The copilot runs in strict permission mode: every tool call (including
the harness's own command tools) waits for your explicit allow/deny inside
the transcript. Answered cards collapse to a summary row you can re-expand.
The L0–L3 chip next to the reasoning selector bounds what can even be
asked; L0 disables tools entirely.

**The airport inspector shows "not available" for frequencies or charts.**
Frequencies come from the imported navdata — if you never ran an import
(Settings → Navigation data), the tables are empty. Charts require a
ChartFox account: sign in under Settings → API keys → ChartFox (the button
opens your browser; copy the API token and the dialog completes itself).

**The "Connect to X-Plane" steps do nothing.**
Expected: the X-Plane telemetry connector is not implemented in this build.
See *What works today* at the top of this README.

**Where are my API keys and conversations stored?**
Everything stays local: keys in the app's local configuration store (not an
OS credential vault), conversations and memories in the local Letta store
(`~/.letta`), gateway logs under your temp directory. Deleting a
conversation removes it through the official Letta API; deleting Letta data
(Settings → AI) wipes agents, memories and stored provider credentials.

**Something feels stuck after a crash.**
Restart the app — it evicts orphaned gateway processes automatically before
starting a fresh one.

---

---

## Roadmap

**Strategy (2026-09 pivot):** AI-first agent workbench. The MVP loop is:
*express flight intent (or import an OFP) → agent structures a FlightIntent →
map + briefing → in-flight read-only telemetry → grounded explanations*.
Simulator write actions stay behind explicit confirmation gates.

- [x] **Phase 0** — Project foundation: layered `lib/`, JetBrains-style workspace (tabs, tool docks, drawers, resizable
  cards, custom window chrome), theme, i18n. Settings system with live theme/locale switch, gear popup menu,
  floating-window dialogs, API key settings (local storage), map tile provider integration (flutter_map + OSM/Mapbox/custom), workspace
  layout persistence, adaptive narrow-screen (phone) layout, startup splash.
- [x] **Phase 1** — Domain core: four cloud-ready objects (`PilotProfile`/`AircraftState`/`FlightIntent`/
  `FlightRecord`),
  abstract repositories, drift schema, coordinate/unit utils, AI scaffold (`McpTool` registry, BYOK `LlmProvider`).
- [x] **Phase 2** — X-Plane navdata + map: stream-parse `apt.dat`/`earth_nav`/`fix`/`awy` → drift/SQLite, flutter_map
  rendering with LNM taxonomy markers, search drawer, inspector with AIRAC / paired runways / ATC frequencies /
  METAR+TAF decoding (NOAA feed), sunrise/sunset. Plugin-ready extension-point registries (tabs, exporters, sim
  connectors, navdata providers). CI (analyze + tests + Windows/Android builds).
- [x] **Sprint A — Agent foundation (AI-first pivot)**: TypeScript Agent
  Gateway (`agent_gateway/`) on the Letta Agent SDK (local backend, auto-start),
  one-click install/start (Settings → AI, Node.js detection), a single
  飞行助理 agent owning every conversation — official-API conversation CRUD in
  the conversations drawer (new/open/delete-with-confirm, Markdown export,
  LLM-summarized titles with self-healing against the backend's auto-summary),
  per-conversation chat tabs, welcome/chat SSE streaming, BYOK provider push,
  tool-approval cards, and a gateway unit suite wired into CI.
- [/] **Sprint B — MCP-first tools (P0)**: **FlightStudio Core** — the app's Dart stdio
  MCP server (`bin/mcp_flightstudio_core.dart`) mounted per-session by the gateway —
  ships `get_airport_data` (full inspector dossier), `charts_read`, `weather_read`
  behind the L0–L3 safety ladder (default grant L1; over-level calls are denied before
  any prompt), with every invocation audited to `mcp-audit.sqlite` (tool, level, args,
  result summary, duration). Remaining: echo / render_map / search_navdata /
  import_simbrief_ofp / generate_preflight_briefing + the in-app audit viewer.
- [ ] **Sprint C — Preflight briefing**: SimBrief/OFP import → structured `FlightIntent` behind one `RouteSource`
  (local A\* engine deferred until after this loop), briefing cards in the workspace.
- [ ] **Sprint D — Read-only telemetry**: X-Plane UDP state → `AircraftState` context for the agent (explain and
  remind only; no commands).
- [ ] **Phase 3 (deferred)** — Local A\* route engine over the airway network, SID/STAR/approach resolution,
  trust layer + AIRAC validation, multi-format export (FMS/PLN/FLP/GPX). Registers `compute_route` /
  `export_flight_plan` MCP tools.
- [ ] **Phase 4 (deferred)** — FlyWithLua command bridge behind `ActionPlan` + user confirmation; flight-record
  capture and track layer.
- [ ] **Phase 5** — Remote monitor & control: embedded shelf server, web + mobile companion (view / pause / autopilot),
  mDNS discovery.
- [ ] **Phase 6** — MSFS support: C++ SimConnect bridge daemon, MSFS/P3D adapter, FlyByWire SimBridge MCDU proxy,
  Navigraph OAuth2.
- [ ] **Phase 7** — Optional cloud: activate sync-ready repositories for flight records, pilot profile, aircraft
  continuity and lightweight social.
- [ ] **Phase 8** — Debrief engine: structured plan-vs-actual scoring (route deviation, altitude/fuel, approach
  stability). Feeds the AI coach.
- [ ] **Phase 9** — Plugin system: QuickJS JavaScript plugin runtime with manifest + permissions, Plugin Center
  UI. Out-of-process JSON-RPC connectors and the built-in Lua editor (LSP, autocomplete, AI coding agent for
  FlyWithLua) follow later.
- [ ] **Future** — Platform expansion: macOS/Linux desktop, HarmonyOS NEXT, NOAA weather (GRIB2), aircraft
  performance collection, progressive-disclosure newbie mode, aircraft import-compatibility matrix, instrument-panel
  vision (PFD/ND/ECAM screenshots as assistive context), Letta Skills packs (descent energy management, manual-
  grounded answers, guarded action plans).

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
