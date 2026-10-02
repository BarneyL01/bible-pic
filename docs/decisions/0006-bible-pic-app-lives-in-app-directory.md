# 0006. The Bible Pic app lives in `app/` of this repository

- **Status:** Accepted
- **Date:** 2026-10-02
- **Deciders:** repository owner

## Context

[ADR 0001](0001-agent-base-is-a-reusable-config-repo.md) kept application code out of this
repository so the configuration could be adopted by many apps. The repository owner now has
one app (Bible Pic, spec v1 of 2026-10-02) and wants to build it here, starting from the base
rather than from nothing. The tension: ADR 0001's reasons (a second app cannot inherit, config
lifecycle tied to one app) still apply to the *portable* files, but not to this one app, which
is the base's only consumer today.

## Decision

The Flutter app is built in `app/`. The portable configuration stays where it was:
`templates/`, `.claude/skills/`, `docs/`, `evals/`. The base's root `CLAUDE.md` governs the
repository as a whole; `app/CLAUDE.md` governs the app and is derived from
`templates/flutter-app/CLAUDE.md`.

Application code does not leave `app/`, and nothing under `templates/` or `.claude/skills/`
refers to Bible Pic.

## Consequences

- `pubspec.yaml`, `lib/`, `android/` now exist in this repository, under `app/` only.
- `/adopt-base` cannot copy the base into itself; the app's `CLAUDE.md` is maintained by hand
  and its departures from the template are listed in its "Deliberate divergence" table.
- A second app would need either its own repo (adopting the base as before) or a move of the
  portable files out of this one.
- The Flutter SDK is needed to work on `app/`, not to work on the rest of the repository.

## Alternatives considered

| Option | Why not |
| --- | --- |
| Separate app repo adopting the base | The owner chose to keep both together while there is one app. |
| Move the base's files under the app | Would hide portable files that other apps should copy from. |
