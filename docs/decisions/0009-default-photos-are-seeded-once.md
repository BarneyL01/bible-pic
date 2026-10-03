# 0009. Default photos are bundled and added once, tracked in AppMeta

- **Status:** Accepted
- **Date:** 2026-10-03
- **Deciders:** repository owner

## Context

The owner wants five photos to come with the app. They must work on Android and web, must
reach people who already have data (not only fresh installs), must not return after being
deleted, and must not duplicate when a backup that already contains them is merged.

## Decision

- The photos live in `app/assets/photos/` as 900 x 2000 JPEGs (9:20, a tall phone shape),
  declared as Flutter assets.
- On launch the app adds them to the photo library once, before the first verse is shown
  (`Repository.seedDefaultPhotos`). They are stored through `PhotoStorage` like any uploaded
  photo, under fixed ids `default-photo-1` to `default-photo-5`.
- A new column `AppMeta.defaultPhotosSeeded` (database schema 3) records that seeding has
  happened. Existing installs get the column on upgrade and receive the photos once.
- The backup format is unchanged (`AppDatabase.backupFormatVersion` stays 2), so schema 3 does
  not make older backups unreadable or newer backups unreadable to the previous app.

## Consequences

- A photo deleted by the user stays deleted; a Replace restore does not re-add them (the flag
  is not part of a backup), and a Merge restore skips them by id.
- Existing users see five extra photos after updating.
- The photos add about 1.9 MB to the app and to the web download.
- Default photos carry no topics, so they are chosen by the "any photo" fallback of pairing.

## Alternatives considered

| Option | Why not |
| --- | --- |
| Seed only in `onCreate` | Existing installs would never receive them. |
| Seed on every launch when a default is missing | Deleted photos would keep coming back. |
| Keep the flag in shared preferences | New dependency, and not available to the web and Android code paths alike without more setup. |
