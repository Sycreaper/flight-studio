# Flight Studio

An open-source, cross-platform **AI flight agent workbench** built with Flutter.
Chat with a Letta-powered copilot that plans, briefs and tracks simulator
flights — grounded in real navdata, with full manual planning tools and remote
monitoring.

[![License: MIT](https://img.shields.io/badge/License-MIT-ff7f27.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Android%20%7C%20iOS%20%7C%20Web-blue)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)]()
[![Status](https://img.shields.io/badge/Status-Pre--alpha-red)]()

> Inspired by the design philosophy of [Little Navmap](https://github.com/albar965/littlenavmap).
> No source code is derived from that project (which is GPL-3.0); Flight Studio is a
> clean-room reimplementation released under the permissive MIT license.

---

## Features

### AI Copilot (Letta + Agent Gateway)

- **A long-term co-pilot brain, not a chatbot** — Flight Studio runs a local **TypeScript Agent Gateway**
  (`agent_gateway/`) on top of the official
  [Letta Agent SDK](https://docs.letta.com/agent-sdk). Each local account owns
  a dedicated Letta agent with persistent memory blocks (user profile,
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
  weather / briefing) land before any simulator write action, and every write
  passes an explicit approval gate enforced by the gateway's safety-policy
  ladder (L0 Explain / read-only → L1 Observe → L2 Suggest → L3 Confirm with
  user approval → L4 Automate; VATSIM comms and critical flight controls are
  always BLOCKED).

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

  MCDU remotely.

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

> _Coming soon._

---

## Getting Started

### Prerequisites
- Flutter 3.x (stable)
- An X-Plane 12 install (for the MVP target)
- Optional, for the AI copilot: [Node.js](https://nodejs.org/en/download) 22.19+ (the app detects it and guides the
  install)

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
4. Connect a model provider inside the Letta CLI (`letta` → `/connect` —
   OpenAI-compatible, Anthropic, Ollama/LM Studio; the CLI shares agent state
   with the gateway), or configure environment variables for the cloud backend.
5. In Flight Studio, start chatting — the copilot agent is created on first
   launch, and every conversation is managed through the conversation drawer.

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
├── ai/          Letta gateway client (HTTP + SSE), local accounts & memory sync,
│                BYOK LLM providers, MCP tool registry (deterministic tools)
├── plugins/     Extension-point registries (tabs, exporters, sim connectors,
│                navdata providers) — the seams third-party plugins will use
├── mcp_servers/ FlightStudio MCP tool servers (SimBrief, manual RAG, navdata,
│                map commands, telemetry) consumed by the Letta agent
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
- **Extensibility:** first-party features and third-party plugins go through the same registries (tab factories,
  exporters, sim connectors, navdata providers, MCP tools). Script plugins run in a QuickJS JavaScript sandbox;
  free-form-canvas UI access is permission-gated and marketplace-reviewed. Heavyweight connectors (sim bridges) may
  run out-of-process over JSON-RPC for crash isolation.

---

## Troubleshooting Log: Wiring the BYOK Copilot (2026-10)

The AI copilot's model-provider path (Flight Studio vault → Letta local
backend → real LLM endpoint) took nine distinct bugs to get working. Each
one is documented here because every trap is easy to re-hit — for future
maintainers and anyone building on the Letta Agent SDK's local backend.

**Architecture of the path.** The Flutter app pushes one OpenAI-compatible
credential from its key vault to the Agent Gateway (`POST /agent/provider`)
before every turn. The gateway lends it to the Letta local backend via the
official app-server protocol (`connect_provider`), resolves a model handle
from the force-refreshed catalog, then runs the turn over SSE.

1. **Parameter shadowing sent pushes to the wrong server.** `setProvider`'s
   `baseUrl` parameter shadowed the class constant `GatewayClient.baseUrl`
   (`http://127.0.0.1:8787`), so the provider push was posted to the *LLM
   provider's* URL (`.../api/paas/v4/agent/provider`). The provider
   answered with its own auth error (`code 1001`), which masqueraded as a
   Letta failure for a long time. Lesson: qualify shared constants in
   request URLs; log the **actual request URL** on every failure.
2. **Windows excluded port ranges killed local test servers silently.**
   Hyper-V/WSL reserve TCP ranges (e.g. 9475–10093). Mock LLM servers on
   9999/9998/9997 died with `EACCES` at `listen()` — the test harness saw
   "no requests ever arrived", which misdirected the diagnosis for hours.
   Check `netsh interface ipv4 show excludedportrange protocol=tcp` before
   binding test ports.
3. **BYOK handle prefixes collide.** The Letta harness resolves model
   handles by prefix; the alias `lc-openai-compatible/…` can be captured by
   the shorter `lc-openai` alias and misroute to the *openai* provider (credentials then come from the wrong lookup and
   requests go out
   unauthenticated). Fix: use the base prefix `openai-compatible/<model>`
   and, when possible, resolve the exact handle from the catalog returned
   by a forced `list_models {force: true}` refresh.
4. **The harness enforces a `/v1` base-URL convention.** Any
   OpenAI-compatible base URL not ending in `/v1` gets `/v1` appended (`localEndpointOpenAIBaseURL`). bigmodel/GLM's
   real endpoint is
   `/api/paas/v4`, so requests hit `/v4/v1/chat/completions` → auth passes
   → router 404s. The API is not usable through a non-`/v1` path directly (its `/api/paas/v1` alias speaks a *native*,
   non-OpenAI error format).
   Fix: the gateway hosts a small **LLM reverse proxy**
   (`agent_gateway/src/llm_proxy.ts`); provider rows store
   `http://127.0.0.1:8787/llm-proxy/{token}/v1` (satisfies the convention)
   and the proxy strips the `/v1` segment, injects `Authorization` from
   the registry, and streams responses (SSE passthrough) to the real base
   URL. Any provider path convention works through it.
5. **A non-existent API silently created an agent per restart.**
   `ensureDefaultAgent` called `client.listAgents()` — which does not exist
   on the SDK client (`undefined?.()` → `catch` → "not found") — so every
   gateway start minted a new copilot agent (23 accumulated) and turns
   eventually hit half-written agent records ("Agent … not found"). Fix:
   the real `client.agents.list()`, plus a `withAgentRecovery` wrapper that
   re-resolves the agent once on "not found" before failing.
6. **SDK stream failures were swallowed.** The turn loop only forwarded
   `assistant` messages; `error`/`result` stream messages (how the SDK
   reports mid-turn failures) were dropped, producing empty replies or
   silent hangs. Fix: forward every message type, join all error fields (`message | errorDetail | errorCode`) so an
   error is never empty, and **never emit `turn_done` after an `error`** — the empty payload
   overwrote the error text in the UI.
7. **Headless turns deadlocked on tool approvals.** The agent's first tool
   call raised an approval request nobody answered (`approval_conflict`),
   leaving a run active; the next message collided with it ("Conversation
   default already has an active run"). Fix: resume sessions with
   `permissionMode: "unrestricted"`, recover pending approvals on session
   start, abort a stuck run before starting a new one, and wire stop to a
   real `session.abort()`.
8. **Stale gateway instances squatted the port.** Orphaned gateways from
   earlier app runs kept serving old code on 8787; the app's health check
   happily reused them, so fixes "didn't land". Fix: `GatewayProcess`
   evicts any non-child listener on the port (netstat + taskkill) before
   spawning, guaranteeing the running build matches the app.
9. **Model ids drift.** bigmodel's catalog no longer contains
   `glm-4.7-flash` (the 4.x line dropped `-flash` variants; 5.3 has them).
   The resolver now prefix-matches the requested id against discovered
   models (`glm-4.7-flash` → `glm-4.7`) and logs the substitution.

**Process lessons.** Never blanket-kill `node.exe` from an agent shell —
the agent tooling itself runs on node. When a background server must
outlive a shell command, start it via `cmd /c "… > log 2>&1"` so the
parent's pipes close cleanly. Diagnostics currently append to
`%TEMP%/flightstudio-chat.log` (Flutter side) and
`%TEMP%/flightstudio-gateway.log` (gateway stdout) — see the commit notes
for the logging debt this implies.

---

## Roadmap

**Strategy (2026-09 pivot):** AI-first agent workbench. The MVP loop is:
*express flight intent (or import an OFP) → agent structures a FlightIntent →
map + briefing → in-flight read-only telemetry → grounded explanations*.
Simulator write actions stay behind explicit confirmation gates.

- [x] **Phase 0** — Project foundation: layered `lib/`, JetBrains-style workspace (tabs, tool docks, drawers, resizable
  cards, custom window chrome), theme, i18n. Settings system with live theme/locale switch, gear popup menu,
  floating-window dialogs, API key vault, map tile provider integration (flutter_map + OSM/Mapbox/custom), workspace
  layout persistence, adaptive narrow-screen (phone) layout, startup splash.
- [x] **Phase 1** — Domain core: four cloud-ready objects (`PilotProfile`/`AircraftState`/`FlightIntent`/
  `FlightRecord`),
  abstract repositories, drift schema, coordinate/unit utils, AI scaffold (`McpTool` registry, BYOK `LlmProvider`).
- [x] **Phase 2** — X-Plane navdata + map: stream-parse `apt.dat`/`earth_nav`/`fix`/`awy` → drift/SQLite, flutter_map
  rendering with LNM taxonomy markers, search drawer, inspector with AIRAC / paired runways / ATC frequencies /
  METAR+TAF decoding (NOAA feed), sunrise/sunset. Plugin-ready extension-point registries (tabs, exporters, sim
  connectors, navdata providers). CI (analyze + tests + Windows/Android builds).
- [/] **Sprint A — Agent foundation (AI-first pivot)**: TypeScript Agent
  Gateway (`agent_gateway/`) on the Letta Agent SDK (local backend, auto-start),
  one-click install/start (Settings → AI, Node.js detection), local pilot
  accounts mapped 1:1 to Letta agents (isolated memory blocks; delete = delete
  agent), welcome-screen chat over the gateway's SSE stream (conversation-only
  toolset first).
- [ ] **Sprint B — MCP-first tools (P0)**: `tool_invocations` audit log, echo / render_map / search_navdata /
  import_simbrief_ofp / generate_preflight_briefing tools with `SafetyPolicy` levels (L0 read-only first).
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
