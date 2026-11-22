# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project rules

- **Everything in the repo is English** — code, comments, docs, commit messages, issues. Conversations with the user may be Chinese, but nothing written into the project is.
  Deliberate exceptions (do NOT "fix" these): `app_zh.arb` and the zh localization files (the product's Chinese UI), `DEFAULT_AGENT_NAME = "飞行助理"` in `agent_gateway/src/agent_manager.ts` (the agent's stored identifier — renaming orphans existing Letta agents), the bilingual Chinese keywords inside the MCP tool descriptions in `lib/mcp/core_tools.dart` (LLM-facing routing hints), the cited `规定了…` GLM artifact in `conversations.ts` comments, and CJK test data (those tests exist to exercise Chinese text handling).
- **At the end of every round of work**: run the relevant tests (gateway and/or Flutter), then draft a commit message following the existing style — but **do not commit**. Review ALL uncommitted changes (`git status`, `git diff`), not just the current round's edits: earlier rounds may still be pending.
- Commit style (see `git log`): conventional prefix (`feat:`/`fix:`/`refactor:`), lowercase one-line subject with an em-dash detail, multi-paragraph body in English explaining the why, the behavior change, and closing with test counts ("38 gateway and 98 Flutter tests pass").

## Commands

Flutter app (repo root):

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # regenerates *.g.dart (drift, gitignored)
flutter gen-l10n                # regenerates lib/l10n/app_localizations*.dart after ARB edits (checked in)
flutter analyze --no-pub
flutter test                    # full suite; real-data smoke tests self-skip without an X-Plane install
flutter test test/chat_flow_test.dart   # single file
```

Agent gateway (`cd agent_gateway`, Node ≥ 22.19):

```bash
npm ci
npm run build                   # tsc typecheck + emit — the type gate, run it after any TS edit
npm test                        # node --import tsx --test, no Letta backend or network needed
node --import tsx --test test/safety_policy_guard.test.ts   # single file
npm run start:dev               # tsx watch (dev gateway on 127.0.0.1:8787)
```

CI (`.github/workflows/ci.yml`) runs flutter analyze+test, gateway build+test, and Windows/Android debug builds.

## Architecture

Two codebases in one repo:

**Flutter workbench (`lib/`)** — desktop app: map canvas, navdata import (X-Plane `apt.dat`/`earth_*` parsers), airport inspector, chat with the copilot. Data layer uses drift (`lib/data/db/database.g.dart` is generated); settings persist via SharedPreferences through `SettingsController` (setters update the in-memory snapshot synchronously, then persist async).

**Agent gateway (`agent_gateway/`)** — local TypeScript Fastify bridge between the Flutter app and the Letta Agent SDK. The app never links the SDK; it talks HTTP/SSE to the gateway, which owns a Letta Code app-server subprocess and the single flight-assistant agent.

The AI stack, end to end:

```
Flutter (GatewayProcess spawns/evicts the node subprocess, passes MCP env)
  → REST + SSE (127.0.0.1:8787)  → gateway (letta_runtime.ts facade)
  → Letta Agent SDK resumeSession (strict permission mode)
  → LLM via BYOK connect_provider (+ llm_proxy for non-/v1 base URLs, e.g. bigmodel /api/paas/v4)
  → FlightStudio Core MCP server (Dart stdio, bin/mcp_flightstudio_core.dart) — mounted per-session
```

Gateway invariants worth knowing before editing:

- `letta_runtime.ts` is the **only module the rest of the gateway imports** — implementation lives in the focused modules it wires (turn_runner, approval_bridge, conversations, provider_push, …). Keep the facade contract stable.
- `GatewayEvent` (in `event_types.ts`) is the stable wire protocol; **Flutter never sees raw Letta events**. Changes to event shapes must update both sides plus `chat_session.dart`'s SSE dispatcher.
- Tool calls run in `permissionMode: "strict"`: everything flows through `canUseTool` → `ApprovalBridge` → the L0–L3 ladder in `safety_policy_guard.ts`. Approvals **fail closed** (no controller wired ⇒ deny); a permission card nobody answers denies after 300 s.
- The tool registry has **three synchronized copies**: `TOOL_KINDS` in `agent_gateway/src/safety_policy_guard.ts` (read/write classification), `CoreToolServer.tools` in `lib/mcp/core_tools.dart` (the Dart implementations — currently 4 of the 10 registered), and the display-name/key-param maps in `lib/mcp/tool_display.dart` + ARB keys `mcpTool*`. Adding a tool means updating all of them.
- Conversation history comes from the raw `conversation_messages_list` protocol **with an explicit `agent_id`** (the bare-spawned app-server otherwise 404s on the default conversation). `parseHistoryMessages` restores tool-call cards; approval outcomes are deliberately not restored (the local backend's history carries no approval records — verified).
- Chat state lives in `lib/ui/chat/chat_session.dart`: `ChatSessionManager` owns the SSE subscription and fans events out to per-conversation `ChatSession`s by `conversationId` tag; `loadHistory()` hydrates on first open (skipped under `FLUTTER_TEST`).

## Status caveat

Pre-alpha: X-Plane telemetry and simulator commands are NOT implemented (the connector is a skeleton); MCP write tools (`set_com_frequency`, `send_sim_command`) are registered but not implemented. Keep README/docs honest about this — the project treats "honest docs" as a feature (see commit 6710873).
