# Maintainer Notes: Wiring the BYOK Copilot (2026-10)

> Maintainer-facing postmortem. For user-facing troubleshooting, see the
> FAQ in the top-level `README.md`.

The AI copilot's model-provider path (Flight Studio's local provider
configuration → Letta local backend → real LLM endpoint) took nine distinct
bugs to get working. Each one is documented here because every trap is easy
to re-hit — for future maintainers and anyone building on the Letta Agent
SDK's local backend.

**Architecture of the path.** The Flutter app pushes one OpenAI-compatible
credential from its local key storage to the Agent Gateway
(`POST /agent/provider`) before every turn. The gateway lends it to the
Letta local backend via the official app-server protocol
(`connect_provider`), resolves a model handle from the force-refreshed
catalog, then runs the turn over SSE.

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
   the shorter `lc-openai` alias and misroute to the *openai* provider
   (credentials then come from the wrong lookup and requests go out
   unauthenticated). Fix: use the base prefix `openai-compatible/<model>`
   and, when possible, resolve the exact handle from the catalog returned
   by a forced `list_models {force: true}` refresh.
4. **The harness enforces a `/v1` base-URL convention.** Any
   OpenAI-compatible base URL not ending in `/v1` gets `/v1` appended
   (`localEndpointOpenAIBaseURL`). bigmodel/GLM's real endpoint is
   `/api/paas/v4`, so requests hit `/v4/v1/chat/completions` → auth passes
   → router 404s. The API is not usable through a non-`/v1` path directly
   (its `/api/paas/v1` alias speaks a *native*, non-OpenAI error format).
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
   silent hangs. Fix: forward every message type, join all error fields
   (`message | errorDetail | errorCode`) so an error is never empty, and
   **never emit `turn_done` after an `error`** — the empty payload
   overwrote the error text in the UI.
7. **Headless turns deadlocked on tool approvals.** The agent's first tool
   call raised an approval request nobody answered (`approval_conflict`),
   leaving a run active; the next message collided with it ("Conversation
   default already has an active run"). Fix at the time: resume sessions
   with `permissionMode: "unrestricted"`, recover pending approvals on
   session start, abort a stuck run before starting a new one, and wire
   stop to a real `session.abort()`.
   **Update (post-2026-10):** sessions now run in `strict` mode — every
   tool call surfaces as an embedded approval card, and the approval
   bridge denies outright when the approval controller is not wired
   (fail-closed).
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

**Related reading.** Conversation-title self-healing (the local backend's
auto-summary overwrites the official `summary` field with the assistant's
first line at unpredictable times) is documented alongside the title logic
in `agent_gateway/src/letta_runtime.ts` and `agent_gateway/src/title_text.ts`.
