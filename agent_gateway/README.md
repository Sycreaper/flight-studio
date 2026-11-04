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
| `src/flutter_api.ts` | App-facing REST API (agent/provider/memory/conversations, chartfox-token) |
| `src/letta_runtime.ts` | The ONLY Letta SDK surface (agent CRUD, turn loop, approvals, MCP mount) |
| `src/safety_policy_guard.ts` | L0–L3 tool safety ladder (grant math, unknown tools) |
| `src/llm_proxy.ts` | OpenAI-compatible reverse proxy for non-`/v1` providers (BYOK) |
| `src/title_text.ts` | Conversation-title normalization (anti auto-summary) |
| `src/event_types.ts` | The `GatewayEvent` union streamed over SSE |
| `src/logger.ts` | Structured logging (goes to `%TEMP%/flightstudio-gateway.log`) |
| `src/gateway_process.ts` (Flutter side) | Spawn/evict logic used by the app |

## API sketch

```
GET  /health                       → { gateway, letta, backend, agentId, model }
GET  /events                       → SSE: message/delta/phase/approval_request/…
POST /agent/provider               → push BYOK credential (per turn)
POST /agent/chartfox-token         → lend ChartFox PAT to MCP env
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

- Tool approvals **fail closed** (unwired approval controller ⇒ deny).
- `FLIGHTSTUDIO_AI_LEVEL` env (0–3) caps the safety ladder; anything
  above 3 or non-numeric falls back to the default L1.
- Memory updates are allow-listed, length-capped and secret-rejecting.
- Provider credentials never touch disk here — they are lent to the
  Letta local backend via the official `connect_provider` protocol.
