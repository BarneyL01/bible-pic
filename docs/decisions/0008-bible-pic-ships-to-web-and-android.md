# 0008. Bible Pic ships to web and Android, and is tested in a browser

- **Status:** Accepted
- **Date:** 2026-10-02
- **Deciders:** repository owner

## Context

[ADR 0007](0007-bible-pic-stack.md) made Bible Pic Android-only. The owner now wants a web build
published to GitHub Pages, and wants changes tested by Claude rather than reported as unverified.
The first Android-only round shipped bugs that a run would have caught (a save that could not
clear stored values, a text box editor that did not respond to touch, canvas shapes that differed
between editor and viewer).

Three Android assumptions did not hold on web: photos as files, `path_provider`, and the
home-screen widget.

## Decision

- **Surfaces:** `android` and `web`. The widget is Android-only; its settings are hidden on web.
- **Photo bytes** go through a `PhotoStorage` interface (`lib/data/photo_storage.dart`). Android
  keeps files under the app documents folder. Web stores them as rows in a `photo_blobs` table
  created with raw SQL inside the same drift database, so the database schema, backups and the
  Android layout are unchanged. The implementation is chosen at compile time through
  `lib/services/platform.dart`.
- **Backup** is built as bytes. Android hands it to the share sheet; web starts a browser download.
  Restore reads the picked file's bytes, so one code path serves both surfaces.
- **drift on web** needs `sqlite3.wasm` and `drift_worker.js` in `web/`. They are downloaded at the
  versions in `pubspec.lock` by `tool/fetch_web_assets.dart` and not committed.
- **CanvasKit is bundled** (`--no-web-resources-cdn`), so the site does not depend on a CDN.
- **Canvas shape:** the canvas is the full window. On a window wider than 9:16 the app is shown in a
  centred portrait frame (`PhoneFrame`), so box positions set in a desktop browser match a phone.
- **New dependency:** `web` (browser download).
- **Tests:** `flutter test` for data and backup logic and screen flows; a Playwright suite in
  `app/e2e/` drives the built site in headless Chromium and measures pixels. Both run in
  `.github/workflows/web.yml`; the browser suite reports but does not block publishing.
- **Deploy:** GitHub Pages from GitHub Actions, base path taken from the repository name.

## Consequences

- Web data is per browser and per site address, and is lost when site data is cleared. Backup is the
  only way to move it, including to Android.
- Any code that touches files or `dart:io` goes behind `platform*.dart`; shared code must compile
  for both surfaces.
- A Claude Code cloud session can install Flutter with `app/tool/cloud_setup.sh` and run every
  check, provided the environment allows `storage.googleapis.com`, `pub.dev` and GitHub release
  downloads.
- Android behaviour that differs from web (drift's background isolate, the widget, share sheet)
  is still not exercised by the automated tests.

## Alternatives considered

| Option | Why not |
| --- | --- |
| Keep photos as files on web via a virtual file system | No file system in a browser; a package would add a dependency for no gain over a table. |
| Add a `Photos.bytes` column for both surfaces | Needs a schema bump and a migration of existing Android photo files. |
| Commit `sqlite3.wasm` and `drift_worker.js` | Binary files that must match the locked package versions; downloading keeps them in step. |
| Deploy without browser tests | The first round showed that unrun UI code ships broken. |
