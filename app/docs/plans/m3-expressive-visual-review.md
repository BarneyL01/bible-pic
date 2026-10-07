# Plan: Material 3 Expressive visual review and many-topics build

Status: **ready to build, work packages 1 to 4**. Work packages 5 to 8 wait on the open questions at
the end. Nothing in `lib/` has changed yet.

- Mocks: the "Bible Pic M3 Expressive mocks" design canvas
  (<https://claude.ai/artifact/AKXUiWegMXSVRoTyKzLU3H>, private until the owner shares it). Each
  artboard pairs a current screenshot with a proposed screen and is labelled with the item IDs used
  here. Boards 12 to 16 are the topic work.
- Reviewed build: `main` at `d5bb763`, built with `flutter build web --release` and screenshotted at
  390 × 844 in Chromium. The many-topics screens were reproduced by bulk importing 50 verses with three
  topics each (50 distinct topics).

## Builder brief

### Decisions already made by the owner

| Question | Decision |
| --- | --- |
| Build topic merge (T4)? | Yes. Build order is the builder's call; this plan sets it |
| "Used most" topic chips in the verse editor (T1)? | Yes, keep them |
| Title-case imported topic names? | No. Topic names keep the case they were typed in |

### Rules for every work package

- One commit per work package, in the order below. Each commit passes, inside `app/`:
  `dart format --set-exit-if-changed lib test tool`, `flutter analyze`, `flutter test`, and the
  browser tests (`flutter build web --release --no-web-resources-cdn --base-href /app/`, then
  `cd e2e; npm install; node run.js`). A check that could not run is reported as **unverified**.
- No new dependencies in work packages 1 to 4.
- Colours come from `Theme.of(context).colorScheme` roles (`secondaryContainer`, `surfaceContainer`,
  `inverseSurface` and so on), never hex values, so work package 5 can change the scheme in one place.
- The mocks show the target **layout and behaviour**. Their violet colours, Roboto Flex font and
  rounded sections are work package 5 to 7 styling; do not build those in work packages 1 to 4.
- Every icon-only button has a `tooltip`, so the e2e driver can find it by name.
- Shared code compiles for Android and web (app `CLAUDE.md`, "Two surfaces, every change").
- Stop and ask the owner rather than choosing when something here is ambiguous.

### Build order

| WP | Contents | Blocked by | Why this position |
| --- | --- | --- | --- |
| 1 | Defects D1, D2, D3 | — | Small fixes with no design dependency |
| 2 | T1 and T2: selected-topics section and topic picker | — | Fixes the owner's current problem (50 topics); T1 needs T2 |
| 3 | T3: Topics screen search, sort, counts, letter index | — | Reuses the letter index and counts from WP2 |
| 4 | T4: select several topics; Merge, Theme, Delete | — | Needs WP3's screen; the only data change, so it lands alone with its tests |
| 5 | V1, V2, V3: colour, shape, type foundations | Open questions 1–3 | Every later visual item depends on these tokens |
| 6 | V4, V6, V7, V9, V10: viewer toolbar, drawer, app bars, FABs, empty states | WP5 | |
| 7 | V8, V11, V12, V13, V14, V15, V16, V18: lists, editors, screens | WP5 | |
| 8 | V5 blurred fill, V17 motion | Open questions 4–5 | |

## WP1: Defects

| ID | Defect today | Change | Done when |
| --- | --- | --- | --- |
| D1 | Favourites app bar is `Colors.black45` with `extendBodyBehindAppBar` (`favourites_screen.dart:17`). With no favourites it is a grey band over the light background. The topic viewer has the same bar (`topics_screen.dart:49`) | When the pool is empty, use a default `AppBar` (no `backgroundColor`, no `extendBodyBehindAppBar`). With verses, keep today's bar | Widget test: with zero favourites, the `AppBar`'s background is not `Colors.black45`; same for a topic with no verses |
| D2 | Default theme row reads "Default / Default" (`themes_screen.dart:65`) | Subtitle on the default theme becomes `In use as default` | Themes screen accessibility text contains "In use as default" and not "Default Default" |
| D3 | Viewer heart is an `Icon`, not a button (`verse_slide.dart:103`) | Replace with an `IconButton` that calls `repo.setFavourite(verse.id, !verse.favourite)`; tooltip `Add to favourites` when off, `Remove from favourites` when on. Tap-anywhere toggling stays | e2e: the button is found by its tooltip and pressing it flips the tooltip text |

## WP2: Selected topics and topic picker (T1, T2)

Mocks 12, 13, 14.

### T2: topic picker sheet (new file `lib/ui/topic_picker.dart`)

- API: `Future<Set<String>?> showTopicPicker(BuildContext context, {required Set<String> selected, String? subject})`.
  Returns the new set of topic ids on **Done**; returns `null` when the sheet is dismissed (swipe down,
  scrim tap, back), and the caller then keeps its previous selection.
- Opened with `showModalBottomSheet(isScrollControlled: true, useSafeArea: true, showDragHandle: true)`,
  about 90 % of the screen height.
- Top to bottom:
  1. Title `Topics`, subtitle `N selected` (with ` for <subject>` when `subject` is given), and a
     `FilledButton` `Done`.
  2. Search field, hint `Search or create a topic`, with a clear button (tooltip `Clear search`)
     while it holds text.
  3. The selected topics as chips, sorted by name. Tapping one deselects it.
  4. The list:
     - **Empty search:** every topic sorted by name, ignoring case, under letter headings (first
       character upper-cased; anything not A–Z goes under `#`). Each row has a checkbox, the name
       and `N verses` (`1 verse` for one). Selected rows use the `secondaryContainer` background.
     - **Text in search:** topics whose name contains the text, ignoring case, with no headings.
       A line `N matches` above them and the matching part of each name in bold.
  5. When the trimmed search text is not empty and no topic name equals it (ignoring case): a
     tonal button `Create topic “<text>” and add it`. It calls `Repository.topicIdForName(text)`,
     adds the id to the selection and clears the search. The topic row is created at that moment,
     even if the sheet is later dismissed; this matches today's "New topic" dialog.
- Letter index (new file `lib/ui/letter_index.dart`, reused in WP3): a narrow column on the right
  edge listing only the letters that have topics, shown only when the search is empty. Tapping a
  letter scrolls so that letter's heading is at the top (a `GlobalKey` per heading plus
  `Scrollable.ensureVisible(alignment: 0)`). Each letter has semantics label `Jump to <letter>`.
- Verse counts: count rows of `verseTopicsProvider` per `topicId`. Total topics: `topicsProvider`.

### T1: verse editor (`verse_editor_screen.dart:213` to `231`)

Replace the `Wrap` of every topic with:

1. A heading `Topics` and the text `N of M` (N selected, M topics in total).
2. The selected topics as `InputChip`s sorted by name, each with `onDeleted` (delete tooltip
   `Remove <name>`).
3. `Used most`: up to 4 topics that are **not** selected, ordered by verse count, highest first,
   ties by name. Each is an `ActionChip` with a `+` icon; tapping adds it to the selection. Hide
   the row when there are no candidates.
4. `FilledButton.tonal.icon` with a search icon, labelled `Choose from all M topics` (or
   `Add a topic` when M is 0). It opens `showTopicPicker(selected: _topicIds, subject: <reference>)`
   and, on a non-null result, replaces `_topicIds`.
5. Remove the `New topic` `ActionChip` and `_newTopic()`; creating a topic now happens in the
   picker.

Topics are still saved only when the verse is saved, as today.

### T1: photo screen (`photo_library_screen.dart:211` to `225`)

Same as the verse editor except: no `Used most` row, and the text after the heading is
`N of M · verses in these topics prefer this photo` (this matches `Repository.pairPhoto`, which
prefers photos that share a topic with the verse). The picker opens with no `subject`.

### WP2 done when

- `test/`: a widget test for the picker: typing filters the list; an exact-name match hides the
  create button; the create button adds a new topic and selects it; dismissing returns `null`.
- `e2e/specs/5-topics.js` (new): bulk import the verses in "Test data" below. Open `Psalm 1:1` in
  the verse editor and check:
  - the editor's topic section names exactly its four topics;
  - the vertical distance between the `Topics` heading and the `Pinned photo` label is at most
    320 px;
  - in the picker, searching `pea` shows `peace`, and creating `lament` adds it to the selection;
  - after Save and reopening, five topics are shown.
- Open `Psalm 11:1`: the first `Used most` chip is `hope`.
- `e2e/specs/2-backup.js` still passes.

## WP3: Topics screen (T3)

Mock 15. Changes `lib/ui/topics_screen.dart`.

- Search field at the top, hint `Search topics`: filters by name containing the text, ignoring
  case. With no results: `No topics match “<text>”`.
- Sort: `SegmentedButton` with `A–Z` (default) and `Most verses` (verse count highest first, ties by
  name). The choice is not saved between visits.
- Filter: `FilterChip` `No photo · N`, where N is the number of topics with no photo. When on, only
  those topics are listed.
- Rows: grouped under letter headings when sorted A–Z with an empty search; otherwise one group
  with no headings. Each row shows the name, then `N verses · N photos` (`no photo` when 0), then
  the theme's name as a small label **only** when `themeId` is set. The trailing menu (Rename, Set
  theme, Delete) and tapping a row to open its verses work as today.
- Grouped row shape: a new `GroupedTile` widget (`lib/ui/grouped_list.dart`) on
  `surfaceContainer`, 2 dp gaps, 20 dp outer corners on the first and last row of a group, 4 dp
  inner corners. V8 in WP7 reuses it.
- Letter index from WP2 on the right, shown only for A–Z with an empty search.
- The FAB becomes `FloatingActionButton.extended` labelled `New topic`.
- Counts: verses from `verseTopicsProvider`, photos from `photoTopicsProvider`.

### WP3 done when

- `5-topics.js` extended: searching `grie` lists only `grief`; `Most verses` lists `hope`
  first; turning on `No photo` hides a topic that has a photo.
- `2-backup.js` still passes (it reads topic names from this screen).

## WP4: Select several topics; Merge, Theme, Delete (T4)

Mock 16.

### Interaction (`lib/ui/topics_screen.dart`)

- Long-press a row to start selecting, with that row selected. While selecting, a tap toggles a row
  instead of opening it; the FAB is hidden; the app bar shows a close button (tooltip
  `Cancel selection`) and the title `N selected` on `secondaryContainer`. Back or close ends
  selection. Search, sort and filter still work.
- A floating toolbar at the bottom (`inverseSurface` container, fully rounded) holds:
  - `Merge`: enabled when two or more topics are selected.
  - `Theme`: the existing "Topic theme" dialog; the choice is applied to every selected topic.
  - `Delete` (tooltip `Delete selected topics`): asks
    `Delete N topics? Verses and photos stay; only these topic tags are removed.` and then calls
    `Repository.deleteTopics`.
- Merge dialog: title `Merge N topics`, text
  `Verses and photos tagged with any of these end up in one topic. Which name stays?`, a radio for
  each selected name plus `New name…` (shows a text field when chosen), buttons `Cancel` and
  `Merge`. After merging, selection ends.

### Data (`lib/data/repository.dart`)

No table changes, so `AppDatabase.dataSchemaVersion` stays 2 and no migration is added.

- `Future<void> deleteTopics(List<String> topicIds)`: one transaction doing what `deleteTopic` does
  for each id.
- `Future<String> mergeTopics({required List<String> topicIds, required String keepName})`, in one
  transaction:
  1. Target: the topic in `topicIds` whose name equals `keepName` ignoring case; otherwise
     `topicIdForName(keepName)`, which may return an existing topic outside the selection or create
     a new one.
  2. Sources: `topicIds` without the target.
  3. For each `verse_topics` row of a source, insert `(verseId, target)` with
     `InsertMode.insertOrIgnore`, then delete the source rows. The same for `photo_topics`.
  4. Theme: keep the target's `themeId`; if it has none, use the first source (in `topicIds` order)
     that has one.
  5. Delete the source topic rows. Return the target id.

### WP4 done when

- `test/repository_test.dart`:
  - a verse tagged with topics A and B has exactly one link after merging A and B;
  - photo links move to the target;
  - the source topic rows are gone;
  - the theme rule in step 4 holds, in both cases;
  - merging into a new name creates that topic and moves every link to it;
  - `deleteTopics` removes the topics and their links and leaves verses and photos.
- `test/backup_test.dart`: a backup taken after a merge restores with the merged topic and links.
- `5-topics.js` extended: long-press two topics, Merge keeping the first name; only that name is
  listed and its verse count is the size of the union of both topics' verses.

## WP5 to WP8: Material 3 Expressive

Blocked until the open questions are answered. Build in this order once unblocked; the WP column in
the table below says which package each item belongs to.

| ID | WP | Pri | Suggestion | Screens | Route | Mock |
| --- | --- | --- | --- | --- | --- | --- |
| V1 | 5 | P1 | Brand colour scheme from the app icon: seed violet `#5B4BA8` (icon sky), tertiary amber from the icon sunrise for favourite and highlight states. Use `DynamicSchemeVariant.expressive` or `vibrant` for more chroma than the default tonal spot. Keep light and dark | All | Core | Tokens |
| V2 | 5 | P1 | Shape scale: large containers 28 dp, cards and list groups 20 dp with 4 dp inner corners between grouped items, buttons fully rounded, FABs 16–20 dp; set once in `ThemeData` component themes instead of per widget | All | Core | Tokens |
| V3 | 5 | P1 | Emphasised type: headline styles at weight 600–700 for screen titles, references and empty-state headings; body stays regular. Bundle Roboto Flex (variable weight and width) as an asset, since the app makes no network calls | All | Core plus a bundled font | Tokens |
| V4 | 6 | P1 | Viewer controls as one floating toolbar at the bottom: menu, favourite (the WP1 button, which changes shape and fills amber when on), lock photo. Replaces the dark disc and the bare icons. Keep tap-anywhere as a shortcut | Home, Favourites, widget launch | Core (row of `IconButton`s in a rounded container) | 01 |
| V5 | 8 | P3 | Fill the letterbox area around a photo with a blurred, darkened copy of the same photo instead of flat `#111111`. Must keep the canvas geometry identical so box positions and the widget render do not move | Home, Favourites | Core (`ImageFiltered`) | 01 |
| V6 | 6 | P2 | `NavigationDrawer` with a header (icon and "Bible Pic"), section labels "Read" and "Library", a home entry for the verse viewer so the drawer has a selected destination, a pill-shaped selected indicator, and Settings at the bottom | Drawer | Core (`NavigationDrawer`, `NavigationDrawerDestination`) | 03 |
| V7 | 6 | P2 | Large top app bar that collapses on scroll (`SliverAppBar.large`) on the top-level list screens; title in the emphasised headline style | Verses, Photos, Topics, Themes, Settings, Favourites | Core | 04, 07, 09, 15 |
| V8 | 7 | P2 | Grouped list items using WP3's `GroupedTile`. Verses show reference in title-medium bold, translation as a small label, a heart on favourites, and the paired photo as a 48 dp rounded thumbnail | Verses, Settings, Themes | Core | 04, 09 |
| V9 | 6 | P2 | Extended FAB with a label ("Add verse", "Add photos", "New theme"; "New topic" is done in WP3) in `primaryContainer`; on the home empty state, "Add a verse" as a large filled button with Bulk import and Restore as a connected button group under it | Lists, Home empty | Core | 02, 04, 07, 08, 11 |
| V10 | 6 | P2 | Empty states: a 120 dp shaped container (M3E shape library, for example "cookie" or "clover") in `primaryContainer` holding an icon, a headline, and one or two lines saying what the screen is for; the action stays the screen's extended FAB, or a filled button where there is no FAB | Home, Verses, Photos, Topics, Favourites | Core (custom `ShapeBorder` or a clipped SVG) | 02, 11 |
| V11 | 7 | P2 | Verse editor in three grouped sections: "Verse" (reference, text, translation in filled text fields), "Organise" (favourite as a toggle chip, the WP2 topic section, theme menu), "Placement" (pinned photo, preview with 20 dp corners, "Move or resize" as a tonal button). Save becomes a filled button in the app bar | Verse editor | Core | 05, 12 |
| V12 | 7 | P2 | Full-screen editors: hint as a rounded pill at the top; actions in a floating toolbar at the bottom using a connected button group (Cancel, No crop) plus a filled primary (Crop, Done). Corner dots take the primary colour | Box editor, Crop | Core | 06a, 06b |
| V13 | 7 | P3 | Bulk import: a segmented button "Paste text / JSON file" so only one method shows; the format rules as a short numbered list in a card; the example as the field's hint | Bulk import | Core (`SegmentedButton`) | 10 |
| V14 | 7 | P3 | Themes as a two-column grid of preview cards, each showing the theme's panel on a sample photo, name under it, "In use" badge on the default | Themes | Core | 08 |
| V15 | 7 | P3 | Settings as grouped list items with icons in tonal 40 dp containers; default theme chosen with `DropdownMenu` | Settings | Core | 09 |
| V16 | 7 | P3 | Photo library: the grid as one group with 4 dp gaps, 4 dp inner corners and 20 dp corners on the grid's outer four tiles; count under the large app bar; extended FAB | Photo library | Core | 07 |
| V17 | 8 | P3 | Motion: replace `CircularProgressIndicator` while a verse loads with the M3E loading indicator; spring curves for the toolbar and FAB; fade-through between list and editor | Viewer, lists | Package for the indicator and springs; Core for fade-through | not mocked |
| V18 | 7 | P3 | Desktop web: the area around the phone frame uses `surfaceContainerLowest` instead of black, and the frame gets 28 dp corners | Web, wide window | Core | not mocked |

### Checks for WP5 to WP8

| WP | Checks before reporting done |
| --- | --- |
| 5 | Screenshots of every screen in light and dark; text contrast on `primaryContainer` and on the toolbar at least 4.5:1 |
| 6 | e2e: toolbar buttons found by tooltip; favourite toggles from the button and from a tap; `1-box.js` still passes (box position on the viewer unchanged) |
| 7 | `1-box.js` and `4-crop-pan.js` still pass with the new toolbar |
| 8 | Android widget render checked by hand (not covered by automated tests) |

### Implementation route

Flutter 3.47 ships Material 3 but not the M3E-only components. Community packages implement them,
for example [`material_3_expressive`](https://pub.dev/packages/material_3_expressive) (1.1.5, MIT,
Android and web, needs Flutter ≥ 3.47 and Dart ≥ 3.13, unverified publisher) and
[`m3_expressive`](https://pub.dev/packages/m3_expressive).

| Route | Covers | Cost | Risk |
| --- | --- | --- | --- |
| A. Core only | Everything except V17's loading indicator and springs | No new dependency | Toolbar, button group and shapes approximate the spec's springs and morphs |
| B. Core plus an M3E package | Everything | One new dependency; raises `pubspec.yaml`'s `flutter: ">=3.38.1"` floor to 3.47 | Unverified publisher; read the package's API on pub.dev for the locked version before use (app `CLAUDE.md`, "Packages and APIs") |

Recommendation: route A. Route B only for V17, as a separate change with an ADR, if the owner
chooses it (open question 4).

## Constraints the changes must keep

- The verse canvas shape and the box fractions do not change (app `CLAUDE.md`, "Canvas and direct
  manipulation"); V4 and V12 float above the canvas and must not shrink it.
- Theme colours the user picks for a verse panel (`AppTheme`) stay as they are; V1 changes app
  chrome only.
- Topic names are shown exactly as stored; no case changes.
- Check the Android widget render (`WidgetSync`) after WP5.

## Test data

`5-topics.js` imports 50 blocks through Bulk import of the form

```
Psalm <i>:1 (KJV)
Verse text number <i> for testing a long list of topics.
# <T[i-1]>, <T[((i-1)*7+3) % 50]>, <T[((i-1)*13+5) % 50]>
```

for `i` from 1 to 50, where `T` is: love, hope, peace, faith, joy, strength, comfort, fear,
anxiety, grace, forgiveness, prayer, wisdom, patience, courage, salvation, healing, trust, guidance,
thankfulness, rest, provision, protection, worship, obedience, humility, kindness, family, marriage,
friendship, work, money, grief, suffering, temptation, creation, eternal life, holy spirit, jesus,
gods word, mercy, justice, encouragement, perseverance, contentment, generosity, purpose, identity,
light, morning. For `i` from 1 to 10, add `hope` to the topic line, so that counts differ.

Resulting data: 50 topics; `hope` has 12 verses, `grace` and `temptation` 2 each, every other topic 3. `Psalm 1:1` has love,
faith, strength and hope. `Psalm 11:1` has forgiveness, worship and creation (not hope).

## Background: review findings

### What the app does today

| Area | Current state | Source |
| --- | --- | --- |
| Colour | `ColorScheme.fromSeed(Colors.indigo)`, light and dark, no relation to the app icon | `lib/main.dart:93` |
| Type | Flutter default (Roboto), no emphasised styles; empty states use body text, one uses `fontSize: 18` | `lib/ui/main_screen.dart:115` |
| Shape | Default component shapes; overlays hard-code `Radius.circular(8)` | `box_position_screen.dart:60`, `crop_screen.dart:124` |
| Navigation | `Drawer` of `ListTile`s, no header, two `Divider`s, no selected state | `main_screen.dart:63` |
| Viewer controls | Menu in a `black54` disc top-left; lock and heart as bare white icons top-right; favourite toggles by tapping anywhere | `main_screen.dart:52`, `verse_slide.dart:83` |
| Lists | Plain `ListTile`s on the surface, no grouping | `verse_list_screen.dart:38`, `settings_screen.dart:28` |
| FABs | Standard 56 dp FAB with an icon only, on four screens | `verse_list_screen.dart:16` and others |
| Empty states | One line of body text centred on the screen | Topics, Photo library, Verses, Favourites |
| Full-screen editors | Hint in a `black54` box, white `OutlinedButton`s and a `FilledButton` in a row | `box_position_screen.dart`, `crop_screen.dart` |
| Loading | `CircularProgressIndicator` | `main_screen.dart:83`, `viewer_page.dart:107` |

### Topics at about 50

| Screen | How topics are chosen | Problem at 50 topics | Source |
| --- | --- | --- | --- |
| Verse editor | Every topic as a `FilterChip` in one `Wrap`, plus "New topic" | About 15 rows of chips. The 3 selected chips sit among 47 unselected ones, so you cannot see what is chosen; pinned photo, theme and text box are pushed below the screen | `verse_editor_screen.dart:213` |
| Photo screen | Same `Wrap` of every topic, above the preview | Same wall of chips; the photo preview starts below the screen | `photo_library_screen.dart:211` |
| Topics screen | `ListView` of every topic; tap opens a viewer of its verses; a menu for rename, theme, delete | 50 rows, each saying "Default theme"; no search, no counts, no way to act on several topics at once | `topics_screen.dart:30` |

## Open questions for the owner (block WP5 to WP8)

1. Seed colour: icon violet `#5B4BA8` as proposed, or another colour?
2. Android dynamic colour (wallpaper colours on Android 12+): use it, or keep the brand scheme
   everywhere so Android and web match? Using it needs the `dynamic_color` package.
3. Font: bundle Roboto Flex, or keep the default Roboto and only change weights?
4. Route A only, or also route B (a new M3E package) for the loading indicator and spring motion?
5. V5 (blurred photo instead of black bars): wanted, given it also changes how the Android widget
   image could look?
