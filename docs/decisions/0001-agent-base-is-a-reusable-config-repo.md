# 0001. agent-base is a reusable configuration repository, not a Flutter app

- **Status:** Superseded by [0006](0006-bible-pic-app-lives-in-app-directory.md)
- **Date:** 2026-09-15
- **Deciders:** repository owner

## Context

The repository was created empty with the stated purpose of maximising Claude Code
effectiveness for Flutter applications targeting web and Android. Two shapes were possible:
the repository holds one Flutter app with its Claude configuration alongside, or it holds only
configuration that other Flutter repositories adopt.

Holding an app would tie the configuration's lifecycle to that app's, and a second app would
have no clean way to inherit improvements. Holding only configuration means every improvement
is written once, but adoption becomes an explicit, repeated act rather than automatic.

## Decision

`agent-base` contains agent configuration only — `CLAUDE.md` files, skills, permission
defaults, vocabulary, and decision records. Flutter application code lives in separate app
repos, which adopt the base by copying `templates/flutter-app/`.

## Consequences

- No `pubspec.yaml`, `lib/`, `android/`, or `web/` in this repository, now or later.
- Improvements reach existing apps only when `/adopt-base` is re-run there. Apps can fall
  behind, so the update path must show divergence clearly rather than overwriting.
- Files under `templates/` are live instructions for downstream apps and are audited to the
  same standard as this repo's own.
- The Flutter SDK is not required to work on this repository.

## Alternatives considered

| Option | Why not |
| --- | --- |
| App lives in this repo | Couples config lifecycle to one app; a second app cannot inherit. |
| Monorepo of apps sharing root config | Forces every app into one release cadence and one CI; premature at one app. |
| Publish config as a pub package | Claude Code reads `CLAUDE.md` and `.claude/` from the working tree; a package dependency is not loaded as instruction. |
