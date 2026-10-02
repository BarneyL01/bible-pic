---
name: adopt-base
description: Install or update the agent-base configuration in a Flutter application repository by copying templates/flutter-app into it and reconciling any existing CLAUDE.md, settings, or skills.
when_to_use: Use when setting up Claude Code for a new Flutter app, when the user asks to apply, install, pull in, or refresh the base in an app repo, or when an app's configuration has fallen behind the base. Also use when the user invokes /adopt-base.
argument-hint: "[path-to-app-repo]"
disable-model-invocation: true
---

# Adopt the base into an app repo

The base is copied, not linked. An app repo owns its configuration after adoption; this skill
gets it there and, on later runs, shows what has diverged.

## Before starting

Confirm which repository is the target. If the working directory is `agent-base` itself, stop
and ask — this skill writes into an app repo, never into the base.

Determine whether this is a **first adoption** (no `CLAUDE.md` in the target) or an **update**
(one exists). The two paths differ.

## First adoption

1. Copy `templates/flutter-app/CLAUDE.md` to the target repo root.
2. Copy `templates/flutter-app/.claude/settings.json` to the target's `.claude/`. If the target
   already has one, merge: union the `allow` lists, union the `deny` lists, keep the target's
   value on any other conflicting key, and show the user the merged result before writing.
3. Fill in the app-identity placeholders at the top of the copied `CLAUDE.md` — app name,
   package/bundle id, minimum Android SDK, whether web or Android is the primary surface. Ask;
   do not infer from directory names.
4. Leave every stack `TBD` in place. Tell the user which ones are open and that
   `/flutter-stack-decide` closes them.
5. Create `docs/vocabulary.md` in the target only if the app will have its own terms; otherwise
   point its `CLAUDE.md` at the base's copy.

Report what was written, what was merged, and what is still open.

## Update

1. Diff the target's `CLAUDE.md` against `templates/flutter-app/CLAUDE.md`. Classify every
   difference as one of:

   | Class | Meaning | Action |
   | --- | --- | --- |
   | **base-new** | Present in the base, absent in the app | Propose adding |
   | **app-local** | The app deliberately customised it | Keep, do not touch |
   | **resolved-TBD** | The app closed a placeholder the base still has open | Keep the app's |
   | **conflict** | Both changed the same rule differently | Ask the user |

2. Never overwrite the target wholesale. Present the classified list and apply only what the
   user accepts.
3. Apply the same treatment to `.claude/settings.json` and any skills that exist in both.

## Rules

- **Never copy the base's root `CLAUDE.md`** into an app. That file governs work on the base
  and is wrong for an app repo. Only `templates/flutter-app/` is portable.
- **Never overwrite a resolved decision with a `TBD`.** An update that reopens a settled
  question is a bug in this skill's diff, not an instruction to the app.
- **Record divergence.** If the app deliberately departs from the base on something the base
  cares about, note it in the app's `CLAUDE.md` with the reason, so the next update run knows
  it is intentional rather than drift.
