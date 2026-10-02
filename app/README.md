# Bible Pic

Shows Bible verses you enter yourself on photos you upload. Runs on Android and in a browser.

| Feature | Android | Web |
| --- | --- | --- |
| Swipe through random verses, favourite with a tap | yes | yes |
| Topics, favourites, themes (font, sizes, colours, panel) | yes | yes |
| Photos with crop-to-screen; text box you move and resize | yes | yes |
| Photo pairing: pinned, then topic-matched, then any | yes | yes |
| Bulk import (pasted text or JSON) | yes | yes |
| Backup and restore (zip: share sheet on Android, download on web) | yes | yes |
| Home-screen widget (fixed verse or verse of the day) | yes | no |

Data stays on the device. On web it lives in the browser's storage for that site address, so it is
separate from the Android app's data and is lost if the browser's site data is cleared: use
**Settings → Backup & new phone** to keep a copy.

## Set up

Needs the Flutter SDK. Run in PowerShell from the repository root; each step needs the one before it.

| Step | Command (inside `app/`) | Why |
| --- | --- | --- |
| 1 | `cd app` | `pubspec.yaml` is here. |
| 2 | `flutter pub get` | Downloads the packages. |
| 3 | `dart run build_runner build --delete-conflicting-outputs` | Generates `lib/db/database.g.dart`. Repeat after any change to `lib/db/database.dart`. |
| 4 | `dart run tool/fetch_web_assets.dart` | Web only. Downloads `sqlite3.wasm` and `drift_worker.js` into `web/` at the versions in `pubspec.lock`. |

Then run it:

| Target | Command |
| --- | --- |
| Web, in Chrome | `flutter run -d chrome` |
| Android phone | `.\tool\setup_android.ps1` once, then `flutter run` |
| Production web build | `flutter build web --release --no-web-resources-cdn --base-href /<repository>/` |

`tool/setup_android.ps1` generates the Android project with `flutter create`, copies the widget's Kotlin and XML
files into it, and registers the widget in the manifest. After it runs, `applicationId` in
`android/app/build.gradle*` must read `com.biblepic.bible_pic`. On macOS or Linux use `tool/setup_android.sh`.

## Icon

The icon is a sunrise over mountains with a cross above a translucent verse panel. Its single source is the SVG inside
`tool/make_icons.js`. After editing it, run `cd e2e; npm install; cd ..; node tool/make_icons.js` to rewrite the web icons
(`web/`), the Android launcher icons (`android_icons/`) and `assets/icon/icon-1024.png`. Android picks the new icons up
when `tool/setup_android.*` is run again.

## Check changes

| Check | Command (inside `app/`) | Covers |
| --- | --- | --- |
| Format | `dart format --set-exit-if-changed lib test tool` | Style. |
| Analyse | `flutter analyze` | Type errors, lints. |
| Unit and widget tests | `flutter test` | Photo pairing, theme order, clearing saved values, backup and restore (Replace, Merge, old and newer schemas), the 1 → 2 database upgrade, bulk-import parsing, adding and favouriting a verse. |
| Browser tests | `cd e2e; npm install; node run.js` after a web build with `--base-href /app/` | Drives the built site in headless Chromium: moving and resizing the text box by pixel measurement, that the viewer shows the box where it was set, crop fills the screen, bulk import, reload persistence, backup download, restore into a fresh profile, the portrait frame on a wide window. |

The browser tests need Chromium. They find one under `PLAYWRIGHT_BROWSERS_PATH`, or use `CHROME_PATH`, or the
copy installed by `npx playwright-core install chromium`. Pass a name to run one spec, for example `node run.js box`.

## Publish the web version

[`.github/workflows/web.yml`](../.github/workflows/web.yml) runs the checks above, builds the site and deploys it to
GitHub Pages on pushes to `main`. In the repository, set **Settings → Pages → Source** to **GitHub Actions** once.
The browser tests run in the workflow but do not block publishing.

## Layout

| Path | Holds |
| --- | --- |
| `lib/db/` | drift tables and `AppDatabase` (`database.g.dart` is generated) |
| `lib/data/` | `Repository` (queries, photo pairing, theme resolution), providers, bulk-import parsers, the `PhotoStorage` interface |
| `lib/services/` | backup and restore, widget rendering, and `platform*.dart` (photo storage and file export: files and share sheet on Android, database and download on web) |
| `lib/ui/` | screens, the shared `VerseCanvas`, the box editor and the cropper |
| `web/` | web shell; `sqlite3.wasm` and `drift_worker.js` are downloaded, not committed |
| `android_widget/` | Kotlin provider and XML copied into `android/` by `tool/setup_android.*` |
| `android_icons/` | Android launcher icons (legacy and adaptive), copied into `android/` by `tool/setup_android.*` |
| `assets/icon/` | `icon-1024.png`, the full-size icon |
| `tool/` | setup scripts, `fetch_web_assets.dart`, `make_icons.js` (draws every icon size from one SVG), `cloud_setup.sh` (installs Flutter in a Claude Code cloud container) |
| `test/` | unit and widget tests |
| `e2e/` | browser tests |

Decisions are in [`../docs/decisions/`](../docs/decisions/) (0006 to 0008). Working instructions for Claude Code
are in [`CLAUDE.md`](CLAUDE.md).
