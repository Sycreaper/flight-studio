# FlightStudio Agent Gateway

A local TypeScript HTTP/SSE bridge between the Flutter app and the
[Letta Agent SDK](https://docs.letta.com/agent-sdk). The Flutter app
talks to this gateway; the gateway owns the Letta runtime (agent CRUD,
conversations, tool approvals, model/provider wiring) so the app never
links the SDK directly.

**Status: pre-alpha.** Single instance, single session, bound to
`127.0.0.1:8787` — not designed for network exposure (session binding
and per-client tokens land with the remote-monitoring milestone).

## Layout

| File | Role |
| --- | --- |
| `src/index.ts` | Entrypoint: Fastify server, `/health`, SSE `/events` |
| `src/flutter_api.ts` | App-facing REST API (agent/provider/memory/conversations) |
| `src/letta_runtime.ts` | Facade — the ONLY file the rest of the gateway imports; wires the modules below |
| `src/letta_app_server.ts` | Local Letta Code app-server subprocess + protocol socket + SDK client |
| `src/agent_manager.ts` | The single flight-assistant agent (ensure + "not found" recovery) |
| `src/turn_runner.ts` | Live turn: resumeSession (strict mode), abort |
| `src/turn_stream.ts` | Pure stream-message → event mapping |
| `src/approval_bridge.ts` | canUseTool semantics over the L0–L3 ladder |
| `src/provider_push.ts` | BYOK connect_provider + model-handle resolution |
| `src/conversations.ts` | Official conversation CRUD + title self-healing |
| `src/memory_updater.ts` / `src/memory_guard.ts` | Guarded memory-block updates (allow-list, caps, secret rejection) |
| `src/mcp_mount.ts` | FlightStudio Core MCP server env mapping |
| `src/safety_policy_guard.ts` | L0–L3 tool safety ladder (grant math, unknown tools) |
| `src/llm_proxy.ts` | OpenAI-compatible reverse proxy for non-`/v1` providers (BYOK) |
| `src/title_text.ts` | Conversation-title normalization (anti auto-summary) |
| `src/event_types.ts` | The `GatewayEvent` union streamed over SSE |
| `src/session_controller.ts` | Sessions + the approval controller (SSE card ↔ POST) |
| `src/logger.ts` | Structured logging (goes to `%TEMP%/flightstudio-gateway.log`) |

## API sketch

```
GET  /health                       → { gateway, letta, backend, agentId, model }
GET  /events                       → SSE: message/delta/phase/approval_request/…
POST /agent/provider               → push BYOK credential (per turn)
POST /agent/memory/update          → guarded: allow-listed blocks, ≤4k chars, no secrets
POST /conversations/…              → conversation CRUD via official Letta API
POST /turn                         → run a chat turn (strict approvals, L0–L3)
```

All endpoints are local-only and expect the app as the only client.

## Development

```bash
npm install        # Node 22.19+ required (see package.json engines)
npm run start:dev  # tsx watch
npm run build      # tsc typecheck + emit
npm test           # node --test over test/*.test.ts
```

Tests cover the safety ladder, title normalization, LLM proxy routing,
tool registry and phase mapping — no Letta backend or network needed.
CI runs `npm run build` + `npm test` on Node 22.

## Security notes

- **Bearer auth**: when `FLIGHTSTUDIO_GATEWAY_TOKEN` is set (the Flutter
  app generates a fresh 256-bit token per spawn), every route requires
  `Authorization: Bearer <token>` — other local processes cannot drive the
  copilot even though the port is loopback-only. Without the variable
  (`npm run start:dev`) the gateway serves unauthenticated with a loud
  warning — developer mode only. The `/llm-proxy/*` routes are exempt
  (the Letta app-server subprocess calls them without the gateway token);
  they are gated by unguessable per-target path tokens instead.
- Approval ids are random UUIDs and deny after 300 s unanswered; tool
  approvals **fail closed** (unwired approval controller ⇒ deny).
- The LLM proxy only accepts http(s) upstreams, refuses upstream redirects
  (so the Authorization header never leaks to an unregistered host) and
  caps streamed responses at 64 MB.
- `FLIGHTSTUDIO_AI_LEVEL` env (0–3) caps the safety ladder; anything
  above 3 or non-numeric falls back to the default L1.
- Memory updates are allow-listed, length-capped and secret-rejecting.
- Provider credentials never touch disk here — they are lent to the
  Letta local backend via the official `connect_provider` protocol.

## Troubleshooting

**`listen EACCES: permission denied 127.0.0.1:8787` on Windows** — the
port is not in use; it landed in a dynamic exclusion range that
Hyper-V/winnat reserves after a reboot (`netsh interface ipv4 show
excludedportrange protocol=tcp` lists them). Reserve 8787 permanently
from an elevated shell:

```powershell
net stop winnat
netsh int ipv4 add excludedportrange protocol=tcp startport=8787 numberofports=1
net start winnat
```

Alternatively pick a free port via the `GATEWAY_PORT` env — but note the
Flutter client currently hard-codes 8787 (`GatewayClient.baseUrl`).
