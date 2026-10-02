# Bible Pic

A personal Android app that shows Bible verses I enter myself on photos I upload, organised by
topic, with swiping and a home-screen widget. Spec: Bible Verse App v1 (2026-10-02).
Adopted from [agent-base](https://github.com/BarneyL01/agent-base); this directory lives inside
that repository (ADR 0006), so the repo-root `CLAUDE.md` also applies.

<!-- Provenance tags in this file are HTML comments: Claude Code strips them before injection,
     so they cost no context. Format and categories: agent-base rubric criterion M4. -->

> **Adoption checklist** — delete this block once every line is done.
> - [x] Replace the identity table below.
> - [ ] Close every remaining `TBD` with `/flutter-stack-decide`.
> - [ ] Run `/audit-agent-config` and clear blocking findings.

## App identity

| Field | Value |
| --- | --- |
| App name | Bible Pic |
| Android package id | `com.biblepic.bible_pic` |
| Minimum Android SDK | **TBD** — set in `android/app/build.gradle*` after `tool/setup_android.sh`; `home_widget` and the Flutter SDK constrain it |
| Surfaces | android |
| Primary surface | android (the only surface; ADR 0007) |

## First-time setup

Needs the Flutter SDK (not present in Claude Code cloud containers). From `app/`:

```powershell
.\tool\setup_android.ps1                               # Windows: flutter create + widget files + manifest patch
flutter pub get
dart run build_runner build --delete-conflicting-outputs # generates lib/db/database.g.dart
flutter analyze                                          # only meaningful after the three steps above
flutter run
```

On macOS or Linux run `tool/setup_android.sh` instead of the `.ps1`. Both scripts are idempotent. After it runs, `applicationId` in
`android/app/build.gradle*` must read `com.biblepic.bible_pic`.

## Layout

| Path | Holds |
| --- | --- |
| `lib/db/` | drift tables and `AppDatabase` (`database.g.dart` is generated) |
| `lib/data/` | `Repository` (all queries, photo pairing, theme resolution), providers, bulk-import parsers |
| `lib/services/` | backup/restore, widget rendering (`WidgetSync`) |
| `lib/ui/` | screens and the shared `VerseCanvas` |
| `android_widget/` | Kotlin provider and XML copied into `android/` by `tool/setup_android.*` |

## Stack decisions

<!-- provenance: preference | ADR 0002 -->
Each row is either **decided** with a link to its ADR, or **TBD**. There is no third state.
Do not fill a TBD with a default — run `/flutter-stack-decide`, which asks and records the
reasoning.

| Concern | Decision |
| --- | --- |
| State management | `flutter_riverpod`; read data through the providers in `lib/data/providers.dart`. See [ADR 0007](../docs/decisions/0007-bible-pic-stack.md). |
| Routing / navigation | **TBD** — the code currently uses `Navigator.push`; not yet decided as a choice |
| Project structure | **TBD** — the code is currently layered (`db`, `data`, `services`, `ui`); not yet decided as a choice |
| Models / serialisation | drift-generated data classes; backup JSON uses their `toJson`/`fromJson`. Further approach **TBD** |
| Networking | None in v1; no network access in the app. Revisit only if a feature needs it |
| Local persistence | `drift` over SQLite, ids are UUID strings, photos are files under the app documents folder referenced by relative path. See ADR 0007. |
| Dependency injection | Riverpod providers (`databaseProvider`, `repositoryProvider`) |
| Testing | **TBD** — what is unit-tested, what is widget-tested, what coverage is expected |
| Lints | **TBD** — `flutter_lints` is in `pubspec.yaml` but not yet decided as a choice |
| CI | **TBD** — what runs on a pull request |

## Working rules

### Verify before claiming
<!-- provenance: compensation@claude-fable-5-1 | retest: on a long run, ask for a status summary
     mid-task and check every claim against a tool result in the transcript; the migration notes
     say keep this instruction on Fable 5.1 -->
Before reporting progress, audit each claim against a tool result from this session. Report
only work you can point to evidence for; if something is not yet verified, say so. If the
Flutter SDK is unavailable in the current environment, a check is **unverified**, not passing,
and the summary names what needs to run elsewhere.

### Before every commit
<!-- provenance: preference | rubric M6: candidate for a PreToolUse hook if observed skipped -->
```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```
All three pass, or the commit does not happen. A failing test is not dismissed as flaky
without a second run on the same commit showing it pass.

### Packages and APIs
<!-- provenance: compensation@claude-fable-5-1 | retest: ask for code against a package whose
     latest major version postdates the model's training; check whether it reads pub.dev or
     pubspec.lock before writing -->
Recognising a package name is not the same as knowing its current API. Flutter and its
packages ship faster than any model's training data. Before writing code against a package,
read its version in `pubspec.lock` and its API on pub.dev for that version; do not write from
memory. The same applies to Flutter SDK APIs: `flutter --version` is the truth, not recall.

### Android only
<!-- provenance: environment | ADR 0007: Android-only, sideloaded; re-check if a web build is added -->
This app ships to Android only. Do not add `kIsWeb` branches, web plugins, or a `web/` folder.
Every new permission in `AndroidManifest.xml` is called out in the change description with the
reason, because reviewers cannot see it in the Dart diff. Assume the minimum SDK in the identity
table, not the latest. A plugin without Android support is a blocker to raise, not something to
route around silently.

### Data changes
<!-- provenance: contract | backup restore reads data.json written by an earlier schema version -->
Any change to a table in `lib/db/database.dart` bumps `AppDatabase.dataSchemaVersion`, adds a
migration in `AppDatabase.migration`, and keeps `BackupService.restore` able to read backups
from the previous version. Text box position and size stay fractions of the canvas (0 to 1);
photo paths stay relative to the photo folder.

### Secrets never enter the repo
<!-- provenance: preference | enforced in code by the deny-rules in .claude/settings.json -->
No API keys, keystores, `key.properties`, or `google-services.json` in version control. If a
change needs a secret, add it to the ignore list and document the environment variable.

### Generated files
<!-- provenance: contract | build_runner mechanics -->
Files produced by `build_runner` are regenerated, never hand-edited. If a generated file is
wrong, fix the source annotation and regenerate.

### Scope
<!-- provenance: compensation@claude-fable-5-1 | retest: give a one-line bug fix in a file with
     an obvious unrelated smell nearby; check the diff touches only the fix -->
Implement what was asked, completely. If while working you find a pre-existing bug, a
performance concern, or behaviour the task does not mention, do not fix or extend it in this
change unless the requested behaviour cannot work without it; report it as a follow-up in the
summary. Where the task is ambiguous, implement the reading its wording and the surrounding
code most directly support, state that assumption, and do not build the other readings too.
Verify however you like, but commit tests only where the task asks for them or the repo
already keeps tests for that kind of change, sized like the neighbouring test files. A new
dependency, a state-management change, or a project-wide refactor is a decision, not an
implementation detail — propose it and get agreement first.

### Finish the turn
<!-- provenance: compensation@claude-fable-5-1 | retest: deep in a long session, watch for a turn
     ending on "Next, I'll…" with no tool call; the migration notes document this on 5.1 -->
Before ending a turn, check the last paragraph. If it is a plan, a list of next steps, or a
promise about work not yet done, do that work now. End the turn only when the task is complete
or blocked on input only the user can provide. Exception: when the user is describing a
problem or thinking out loud rather than asking for a change, the deliverable is the
assessment — report and stop.

### Lessons
<!-- provenance: compensation@claude-fable-5-1 | retest: after a correction in one session, check
     whether the next session repeats the mistake without this file -->
Corrections and confirmed approaches that the repo and git history do not already record go
in `docs/lessons.md`, one entry per lesson with a one-line summary first and the reason it
mattered. Consult it at the start of a task in an unfamiliar area. Update an existing entry
rather than adding a duplicate; delete entries that turn out to be wrong. Claude Code's auto
memory is machine-local; this file is what travels with the repo.

## Deliberate divergence from the base

Record here anything this app does differently from `agent-base`, with the reason, so a future
`/adopt-base` update treats it as intentional rather than drift.

| Departure | Reason |
| --- | --- |
| Lives in `app/` of the agent-base repository | ADR 0006 |
| "Both surfaces, every change" replaced by "Android only" | Spec: Android only, no web build (ADR 0007) |
| Stack rows decided from the spec; routing, structure, testing, lints, CI left `TBD` | ADR 0007 records only what the spec states |
