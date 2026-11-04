# Pull Request

## What & why

<!-- One paragraph: what this changes and the problem it solves. Link the
     issue ("Closes #123") if one exists. -->

## Type of change

- [ ] Bug fix (non-breaking)
- [ ] New feature
- [ ] Refactor (no behavior change)
- [ ] Documentation
- [ ] Tooling / CI

## Safety & security considerations

<!-- Required if this touches AI tools, permissions, credentials, or the
     gateway. Confirm:
     - New/changed tools declare an L0–L3 level (no new rungs)
     - L2+ tools still refuse to run without the audit trail
     - Approvals stay fail-closed (never auto-allow)
     - No credential-shaped value can reach memory blocks
     Otherwise write "N/A". -->

## Checklist

- [ ] An issue exists and this PR was agreed there (or the change is trivial)
- [ ] `flutter analyze` is clean
- [ ] `flutter test` passes locally
- [ ] `npm test --prefix agent_gateway` passes (gateway touched)
- [ ] New/changed user-facing strings added to `app_en.arb` + `app_zh.arb`
      and `flutter gen-l10n` re-run
- [ ] New logic has tests; bug fixes include a regression test
- [ ] `CHANGELOG.md` updated (Unreleased section) for user-visible changes
- [ ] Comments are English and explain the non-obvious *why*
