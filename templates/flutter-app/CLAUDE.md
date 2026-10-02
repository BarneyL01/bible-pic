# <APP_NAME>

A Flutter application. Adopted from [agent-base](https://github.com/BarneyL01/agent-base).

<!-- Provenance tags in this file are HTML comments: Claude Code strips them before injection,
     so they cost no context. Format and categories: agent-base rubric criterion M4. -->

> **Adoption checklist** — delete this block once every line is done.
> - [ ] Replace `<APP_NAME>` above and the identity table below.
> - [ ] Close every `TBD` with `/flutter-stack-decide`.
> - [ ] Run `/audit-agent-config` and clear blocking findings.

## App identity

| Field | Value |
| --- | --- |
| App name | `<APP_NAME>` |
| Android package id | `<com.example.app>` |
| Minimum Android SDK | `<TBD — set during adoption>` |
| Surfaces | web, android |
| Primary surface | `<TBD — which one wins when web and Android requirements conflict>` |

## Stack decisions

<!-- provenance: preference | ADR 0002 -->
Each row is either **decided** with a link to its ADR, or **TBD**. There is no third state.
Do not fill a TBD with a default — run `/flutter-stack-decide`, which asks and records the
reasoning.

| Concern | Decision |
| --- | --- |
| State management | **TBD** — decided by the repository owner via `/flutter-stack-decide` |
| Routing / navigation | **TBD** — must account for browser URL and deep links on the web surface |
| Project structure | **TBD** — feature-first or layer-first, and where shared code lives |
| Models / serialisation | **TBD** — code generation or hand-written |
| Networking | **TBD** — client library, error model, retry policy |
| Local persistence | **TBD** — must work on both web and Android |
| Dependency injection | **TBD** — may be subsumed by the state management choice |
| Testing | **TBD** — what is unit-tested, what is widget-tested, what coverage is expected |
| Lints | **TBD** — which analysis_options ruleset |
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

### Both surfaces, every change
<!-- provenance: environment | the app ships to two surfaces; re-check if a surface is dropped -->
This app ships to web and Android. A change that works on one and breaks the other is
incomplete, because:

- **Web:** `dart:io` does not exist there; check `kIsWeb` before platform-specific paths. URL
  state must survive a page reload and the browser back button, or deep links break.
- **Android:** every new permission in `AndroidManifest.xml` is called out in the change
  description with the reason, because reviewers cannot see it in the Dart diff. Assume the
  minimum SDK in the identity table, not the latest.
- A plugin without web support, or a feature neither surface supports, is a blocker to raise,
  not something to route around silently.

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
| *(none)* | |
