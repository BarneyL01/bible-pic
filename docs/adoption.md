# Adopting the base in a Flutter app repo

The base is copied into an app repo, not referenced from it. After adoption the app owns its
configuration; later runs of `/adopt-base` show what has diverged and let you choose what to
pull forward.

## What gets copied

| From the base | To the app repo | Purpose |
| --- | --- | --- |
| `templates/flutter-app/CLAUDE.md` | `./CLAUDE.md` | Instructions Claude loads every turn in that app |
| `templates/flutter-app/.claude/settings.json` | `./.claude/settings.json` | Permission defaults for Flutter commands |

Nothing else. The base's own root `CLAUDE.md` and its skills stay here — they govern work on
the base and would be wrong in an app.

## Steps

1. Open a Claude Code session with both repos available.
2. Run `/adopt-base` from the app repo.
3. Answer the app-identity questions — app name, package id, minimum Android SDK, primary
   surface. These are not inferred.
4. Run `/flutter-stack-decide` to close the stack placeholders. Each decision produces an ADR
   in the app repo and a checkable instruction in its `CLAUDE.md`.
5. Run `/audit-agent-config` against the app to confirm the result has no blocking findings.

## Keeping an app current

Re-run `/adopt-base` in the app repo. It diffs the app's `CLAUDE.md` against the current
template and classifies every difference as base-new, app-local, resolved-TBD, or conflict.
Only what you accept is applied; a resolved decision is never reopened by an update.

## Deliberate divergence

An app may legitimately depart from the base. Record the departure and its reason in the app's
own `CLAUDE.md` so the next update run treats it as intentional rather than as drift.
