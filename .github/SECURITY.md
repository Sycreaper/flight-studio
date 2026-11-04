name: Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 0.1.x (pre-alpha / developer preview) | security fixes land on `master` |

There are no tagged releases yet; fixes are published to the default
branch only. Binary builds are not distributed at this stage.

## What this means today

Flight Studio is early-alpha software. The security boundaries below
are implemented, but the project has not undergone an external audit.

- **Local-only by default.** The Agent Gateway binds to `127.0.0.1`
  and is single-instance, single-session. It is not designed to be
  exposed to a network until session binding and per-client tokens
  land (roadmap Phase 5).
- **Fail-closed tool approvals.** Every AI tool call runs behind the
  L0–L3 safety ladder with an in-chat approval card. If the approval
  controller is not wired, the call is denied outright. When the
  audit trail (mcp-audit.sqlite) cannot be opened, tools at L2 or
  above refuse to run.
- **Credentials are stored locally, in plain text.** API keys
  (OpenAI-compatible providers, ChartFox PAT) and the gateway
  remote-token are kept in the app's local configuration store
  (SharedPreferences JSON) — **not** an OS credential vault or
  encrypted storage. This is a known pre-alpha limitation, disclosed
  in the README and on the roadmap (secure-storage migration). Treat
  the machine profile accordingly.
- **Data boundaries.** Conversations, memories and agent state stay
  in the local Letta store (`~/.letta`) unless a cloud backend is
  configured. Model traffic goes from your machine directly to the
  provider you configured (BYOK); no telemetry is sent to the project.
- **AI tool sandbox.** Tools exposed to the copilot are read-only
  (L1) today; writes (L3) require explicit per-call user approval.

## Reporting a Vulnerability

Please report privately via [GitHub security advisories](https://github.com/Sycreaper/flight-studio/security/advisories/new)
("Report a vulnerability"), or email the maintainer via the contact
address on the GitHub profile. Please include:

- a minimal reproduction (steps, config or snippet);
- the affected component (Flutter app / Agent Gateway / FlightStudio
  Core MCP server);
- versions (Flutter, Node, Letta SDK) if a build from source is
  involved.

You should receive an acknowledgment within a week. Please avoid
opening public issues for vulnerabilities until a fix is released.
