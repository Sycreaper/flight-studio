# Changelog

All notable changes to Flight Studio are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [SemVer](https://semver.org/) starting from the first
tagged release (until then, `master` is the rolling development
snapshot).

## [Unreleased]

### Added
- ChartFox chart browsing end-to-end: browser sign-in (clipboard-captured
  Sanctum PAT) under Settings → API keys, a 航图/Charts tab in the
  airport inspector, and an authenticated `charts_read` FlightStudio
  Core MCP tool (token lent to the gateway per turn).
- In-chat approval cards for every AI tool call (strict permission mode)
  with an L0–L3 safety-level selector next to the reasoning-effort chip;
  answered cards collapse into re-expandable summary rows.
- `LICENSE-THIRD-PARTY`, `SECURITY.md`, `CONTRIBUTING.md`,
  `CODE_OF_CONDUCT.md`, issue/PR templates, and this changelog.
- User-facing FAQ in the README; maintainer BYOK postmortem moved to
  `docs/maintainers/byok-debugging.md`.

### Changed
- **Tool approvals fail closed.** When the approval controller is not
  wired, tool calls are denied instead of auto-allowed.
- **Safety ladder is L0–L3 everywhere.** The Dart `SafetyLevel` class
  dropped its unused L4/L5 constants; docs and comments now describe
  four rungs (all writes require explicit approval).
- **Memory updates are guarded.** `POST /agent/memory/update` accepts
  only the four flight-assistant block labels, caps values at 4,000
  characters, and rejects credential-shaped values.
- **High-level tools require the audit trail.** FlightStudio Core tools
  at L2+ refuse to run when `mcp-audit.sqlite` cannot be opened.
- README: honest "What works today" status matrix, compatibility matrix,
  single-instance/single-session disclosure, X-Plane steps marked as
  planned, dead documentation link removed.

### Fixed
- ChartFox v2 API parsing: responses are JSON (Map) or an HTML shell —
  both clients now detect the shell and report "not available" instead
  of crashing (anonymous access returns the website's HTML, so a Bearer
  PAT is required).
- Inspector tests follow the tab-count change (5 → 6 tabs with Charts).
- Orphaned MCP server processes could lock `.dart_tool` sqlite3.dll
  after a hard gateway kill.
