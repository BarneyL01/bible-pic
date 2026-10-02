# Lessons

One entry per lesson, summary first, then why it mattered.

## drift's `insertOnConflictUpdate` skips null fields
Saving a data class with `insertOnConflictUpdate` never writes `null` over an existing value, so
clearing a verse's pinned photo, theme or text box override silently did nothing. Use
`insert(row, mode: InsertMode.insertOrReplace)` for whole-row saves. Found by a unit test
(`test/repository_test.dart`), not by reading the code.

## Pan gestures drop the first 18 to 36 px of a drag
A `GestureDetector` pan waits for movement before it starts and does not count that distance, so a
text box and its corner dots felt slow and unresponsive. `Listener.onPointerMove` responds from the
first pixel. Use it for direct-manipulation handles. Also keep such editors out of scroll views.

## Edit positions on the canvas they are shown on
A 3:4 preview inside an app bar and a full-screen viewer put the same fractions in different places
on the photo. One canvas shape (the full window, or the phone frame) everywhere fixes it.

## Run the app before reporting it works
Analyzer-clean code is not working code. In a cloud container, `app/tool/cloud_setup.sh` installs
Flutter, and a headless Chromium can drive the web build (see `app/e2e/`). Flutter exposes widgets to
the browser only after its accessibility placeholder is clicked; labels come from `Semantics`
(tooltips on icon buttons give them labels).

## Pin package versions against the SDK, not against pub.dev
`build_runner` 2.15.2+ needs `meta ^1.18.3`, which the Flutter SDK's pinned `meta` 1.18.0 forbids.
The latest version on pub.dev is not always installable. `flutter pub get` is the check.

## The user runs PowerShell on Windows
Give the user PowerShell commands, from the right directory, in order; do not give bash scripts.
Say which branch the files are on.
