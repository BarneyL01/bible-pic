# 0007. Bible Pic stack: Android-only, Riverpod, drift

- **Status:** Accepted
- **Date:** 2026-10-02
- **Deciders:** repository owner (Bible Verse App v1 spec)

## Context

The template's stack table is `TBD` throughout. The owner's v1 spec names several choices
explicitly; the rest it does not mention. Only choices the owner stated are recorded here.

## Decision

| Concern | Decision | Source |
| --- | --- | --- |
| Surfaces | Android only, sideloaded; no web build | Spec, Overview |
| State management | `flutter_riverpod` | Spec, Overview |
| Local persistence | `drift` (SQLite) with `drift_flutter` | Spec, Packages |
| Ids | UUID strings, so backups from two phones can merge | Spec, Data model |
| Photo storage | Files under the app documents folder, referenced by relative path | Spec, Data model |
| Widget | `home_widget` with a native Android provider showing pre-rendered images | Spec, Home-screen widget |
| Backup | Zip of `manifest.json`, `data.json`, `photos/` built with `archive` | Spec, Backup |

Follows from the above rather than being a separate choice: dependency injection is Riverpod
providers; networking is absent because the spec has no network feature.

Not decided by the spec and therefore still `TBD` in `app/CLAUDE.md`: routing, project
structure, serialisation beyond drift's generated classes, testing, lints, CI, minimum
Android SDK.

## Consequences

- No `kIsWeb` branches and no web support code; the template's "both surfaces" rule is
  replaced by an Android-only rule in `app/CLAUDE.md`.
- drift generates `lib/db/database.g.dart` with `build_runner`; it is git-ignored and must be
  regenerated after any change to `lib/db/database.dart`.
- Widget images are rendered by Flutter for the next 30 days and read by the Kotlin provider,
  so the widget only changes day when the app has rendered ahead and Android runs the
  provider's update (about every 30 minutes at most).
- The spec's open question "main screen on open" was not answered. The build shows a fresh
  random verse each time; changing that is a one-line change in `MainScreen`.

## Alternatives considered

| Option | Why not |
| --- | --- |
| Choose other state or storage libraries | The owner named these. |
| Fill the remaining `TBD` rows with defaults | Forbidden by ADR 0002; they stay open. |
