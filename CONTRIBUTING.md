# Contributing to Flight Studio

Thanks for your interest! Flight Studio is a pre-alpha, developer-preview
project — the codebase moves fast and the README's *What works today*
section is the honest map of what is real.

## Ground rules

- **Open an issue first** for anything beyond a trivial fix, so we can
  agree on the direction before you sink time into a PR.
- Keep PRs small and focused; one logical change per PR.
- English is the working language for issues, PRs, code comments and
  commit messages. (The product UI is bilingual English/Chinese.)

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Gateway (Node 22+):

```bash
cd agent_gateway
npm ci
npm run build
npm test
```

CI runs the same commands on every push and PR — a green CI is the
merge gate. Real-data smoke tests skip themselves when no local
X-Plane/navdata is present.

## Code expectations

- **Comments are English** (Dart `///` doc comments, TypeScript `///`),
  and explain *why* where the code alone can't.
- **Dart** follows the layered architecture in `README.md`
  (`core/domain/data/ai/mcp/ui`); business logic stays free of Flutter
  imports. Follow the existing style; `flutter analyze` must be clean.
- **TypeScript** lives under `agent_gateway/src` and is type-checked
  in CI (`npm run build`).
- **L10n**: user-facing strings come from
  `lib/l10n/app_en.arb` / `app_zh.arb` — never hardcode UI text. Run
  `flutter gen-l10n` after editing; don't commit changes to generated
  files by hand unless regenerating.
- **Safety ladder is L0–L3.** New AI tools declare a level; anything
  at L2+ must refuse to run when the audit trail is down, and all
  writes go through the in-chat approval card.
- **Tests**: new logic ships with tests (`test/`,
  `agent_gateway/test/`). Bug fixes include a regression test when
  practical.

## Commit messages

Conventional Commits style (`feat:`, `fix:`, `docs:`, `refactor:`,
`test:`, `chore:`, …), imperative mood, English only.

## Issue triage

Issues labeled `bug` / `enhancement` / `question` are triaged by the
maintainer. Security issues go through `SECURITY.md`, never a public
issue.
