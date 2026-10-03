# 0010. A photo can have its own theme

- **Status:** Accepted
- **Date:** 2026-10-03
- **Deciders:** repository owner

## Context

The owner wants to select several photos in the Photo library and give them a particular theme,
as well as delete them and assign topics in bulk. Themes applied only to verses (directly or
through a topic), so a photo had nowhere to carry one.

## Decision

- `Photos.themeId` (nullable) is added in database schema 4.
- The theme used for a verse is, in order: the verse's own theme, the theme of the photo it is
  shown on, a topic theme, the default theme. A photo's theme therefore overrides a topic's but
  not a verse's own choice.
- The Photo library has a selection mode (long press or the checklist button). With photos
  selected the owner can set topics (a topic is ticked when every selected photo has it, and
  tapping sets it on all or none), set or clear a theme, and delete. The photo detail screen has
  the same theme choice for one photo.
- Deleting a theme clears it from photos, as it already did from verses and topics.
- The backup format moves to version 3, because each photo now carries its theme. The previous
  app refuses version 3 with its "newer version" message instead of dropping the themes
  silently; version 2 and 1 backups still restore (their photos have no theme).

## Consequences

- Theme resolution needs the photo, so the viewer, the widget renderer and the editor previews
  pass the photo they show. Anything that renders a verse must do the same.
- A verse shown on a different photo (random pairing) can look different each time if photos
  have different themes. That is the intended use.
- Existing installs gain the column on upgrade; no data is rewritten.

## Alternatives considered

| Option | Why not |
| --- | --- |
| A theme per topic only (already existed) | Cannot style a hand-picked set of photos. |
| Stamp the photo's theme onto verses | Verses are shown on random photos, so the theme would not follow the photo. |
| Keep backup format 2 | Older apps would silently lose photo themes on restore. |
