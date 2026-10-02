import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

/// Text box geometry as fractions of the canvas.
class BoxRect {
  const BoxRect(this.x, this.y, this.w);
  final double x;
  final double y;
  final double w;

  BoxRect copyWith({double? x, double? y, double? w}) =>
      BoxRect(x ?? this.x, y ?? this.y, w ?? this.w);
}

/// A verse with the topic ids it belongs to.
class VerseWithTopics {
  const VerseWithTopics(this.verse, this.topicIds);
  final Verse verse;
  final List<String> topicIds;
}

class Repository {
  Repository(this.db);
  final AppDatabase db;

  // ---------- Photo folder ----------

  Future<Directory> photoDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'photos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> photoFile(Photo photo) async =>
      File(p.join((await photoDir()).path, photo.path));

  // ---------- Streams ----------

  Stream<List<Verse>> watchVerses() =>
      (db.select(db.verses)..orderBy([(v) => OrderingTerm.asc(v.reference)]))
          .watch();
  Stream<List<Topic>> watchTopics() =>
      (db.select(db.topics)..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();
  Stream<List<Photo>> watchPhotos() => db.select(db.photos).watch();
  Stream<List<AppTheme>> watchThemes() =>
      (db.select(db.themes)..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();
  Stream<List<VerseTopic>> watchVerseTopics() =>
      db.select(db.verseTopics).watch();
  Stream<List<PhotoTopic>> watchPhotoTopics() =>
      db.select(db.photoTopics).watch();
  Stream<Verse?> watchVerse(String id) => (db.select(db.verses)
        ..where((v) => v.id.equals(id)))
      .watchSingleOrNull();
  Stream<AppMetaRow> watchMeta() => db.select(db.appMeta).watchSingle();

  // ---------- Reads ----------

  Future<List<Verse>> allVerses() => db.select(db.verses).get();
  Future<List<Photo>> allPhotos() => db.select(db.photos).get();
  Future<Verse?> verseById(String id) =>
      (db.select(db.verses)..where((v) => v.id.equals(id))).getSingleOrNull();
  Future<Photo?> photoById(String id) =>
      (db.select(db.photos)..where((v) => v.id.equals(id))).getSingleOrNull();

  Future<List<Verse>> favouriteVerses() =>
      (db.select(db.verses)..where((v) => v.favourite.equals(true))).get();

  Future<List<Verse>> versesForTopic(String topicId) {
    final q = db.select(db.verses).join([
      innerJoin(db.verseTopics, db.verseTopics.verseId.equalsExp(db.verses.id)),
    ])
      ..where(db.verseTopics.topicId.equals(topicId));
    return q.map((r) => r.readTable(db.verses)).get();
  }

  Future<List<String>> topicIdsForVerse(String verseId) async {
    final rows = await (db.select(db.verseTopics)
          ..where((t) => t.verseId.equals(verseId)))
        .get();
    return rows.map((r) => r.topicId).toList();
  }

  Future<List<String>> topicIdsForPhoto(String photoId) async {
    final rows = await (db.select(db.photoTopics)
          ..where((t) => t.photoId.equals(photoId)))
        .get();
    return rows.map((r) => r.topicId).toList();
  }

  Future<int> verseCount() async {
    final c = db.verses.id.count();
    final row = await (db.selectOnly(db.verses)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }

  // ---------- Themes ----------

  Future<AppTheme?> defaultTheme() => (db.select(db.themes)
        ..where((t) => t.isDefault.equals(true))
        ..limit(1))
      .getSingleOrNull();

  /// Pinned verse's theme, then topic theme, then the default theme.
  Future<AppTheme> resolveTheme(Verse verse) async =>
      resolveThemeFor(verse, topicIds: await topicIdsForVerse(verse.id));

  /// As [resolveTheme], for a verse whose topics are not yet saved.
  Future<AppTheme> resolveThemeFor(Verse verse,
      {required List<String> topicIds}) async {
    if (verse.themeId != null) {
      final t = await (db.select(db.themes)
            ..where((t) => t.id.equals(verse.themeId!)))
          .getSingleOrNull();
      if (t != null) return t;
    }
    if (topicIds.isNotEmpty) {
      final q = db.select(db.themes).join([
        innerJoin(db.topics, db.topics.themeId.equalsExp(db.themes.id)),
      ])
        ..where(db.topics.id.isIn(topicIds))
        ..orderBy([OrderingTerm.asc(db.topics.name)])
        ..limit(1);
      final row = await q.getSingleOrNull();
      if (row != null) return row.readTable(db.themes);
    }
    return (await defaultTheme()) ??
        const AppTheme(
          id: 'builtin',
          name: 'Built-in',
          font: 'sans-serif',
          fontSize: 26,
          referenceFontSize: 16,
          textColor: 0xFFFFFFFF,
          alignment: 'center',
          panelColor: 0xFF000000,
          panelOpacity: 0.5,
          cornerRadius: 12,
          isDefault: true,
        );
  }

  Future<String> saveTheme(AppTheme t) async {
    await db.into(db.themes).insertOnConflictUpdate(t);
    return t.id;
  }

  Future<void> setDefaultTheme(String id) => db.transaction(() async {
        await db.update(db.themes).write(
            const ThemesCompanion(isDefault: Value(false)));
        await (db.update(db.themes)..where((t) => t.id.equals(id)))
            .write(const ThemesCompanion(isDefault: Value(true)));
      });

  Future<void> deleteTheme(String id) => db.transaction(() async {
        final t = await (db.select(db.themes)..where((x) => x.id.equals(id)))
            .getSingleOrNull();
        if (t == null || t.isDefault) return;
        await (db.update(db.verses)..where((v) => v.themeId.equals(id)))
            .write(const VersesCompanion(themeId: Value(null)));
        await (db.update(db.topics)..where((v) => v.themeId.equals(id)))
            .write(const TopicsCompanion(themeId: Value(null)));
        await (db.delete(db.themes)..where((x) => x.id.equals(id))).go();
      });

  // ---------- Topics ----------

  Future<String> topicIdForName(String name) async {
    final clean = name.trim();
    final existing = await (db.select(db.topics)
          ..where((t) => t.name.lower().equals(clean.toLowerCase())))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    final id = newId();
    await db.into(db.topics).insert(TopicsCompanion.insert(id: id, name: clean));
    return id;
  }

  Future<void> setTopicTheme(String topicId, String? themeId) =>
      (db.update(db.topics)..where((t) => t.id.equals(topicId)))
          .write(TopicsCompanion(themeId: Value(themeId)));

  Future<void> renameTopic(String topicId, String name) =>
      (db.update(db.topics)..where((t) => t.id.equals(topicId)))
          .write(TopicsCompanion(name: Value(name.trim())));

  Future<void> deleteTopic(String topicId) => db.transaction(() async {
        await (db.delete(db.verseTopics)..where((t) => t.topicId.equals(topicId)))
            .go();
        await (db.delete(db.photoTopics)..where((t) => t.topicId.equals(topicId)))
            .go();
        await (db.delete(db.topics)..where((t) => t.id.equals(topicId))).go();
      });

  // ---------- Verses ----------

  Future<void> saveVerse(Verse verse, List<String> topicIds) =>
      db.transaction(() async {
        await db.into(db.verses).insertOnConflictUpdate(verse);
        await (db.delete(db.verseTopics)
              ..where((t) => t.verseId.equals(verse.id)))
            .go();
        for (final t in topicIds.toSet()) {
          await db.into(db.verseTopics).insert(
              VerseTopicsCompanion.insert(verseId: verse.id, topicId: t));
        }
      });

  Future<void> deleteVerse(String id) => db.transaction(() async {
        await (db.delete(db.verseTopics)..where((t) => t.verseId.equals(id)))
            .go();
        await (db.delete(db.verses)..where((t) => t.id.equals(id))).go();
      });

  Future<void> setFavourite(String id, bool value) =>
      (db.update(db.verses)..where((v) => v.id.equals(id)))
          .write(VersesCompanion(favourite: Value(value)));

  Future<void> pinPhoto(String verseId, String? photoId) =>
      (db.update(db.verses)..where((v) => v.id.equals(verseId)))
          .write(VersesCompanion(pinnedPhotoId: Value(photoId)));

  /// Imports verses; returns how many were added.
  Future<int> importVerses(List<ImportedVerse> items) async {
    var added = 0;
    await db.transaction(() async {
      for (final item in items) {
        final id = newId();
        await db.into(db.verses).insert(VersesCompanion.insert(
              id: id,
              reference: item.reference,
              body: item.text,
              translation: Value(item.translation),
              favourite: Value(item.favourite),
            ));
        for (final name in item.topics) {
          final tid = await topicIdForName(name);
          await db.into(db.verseTopics).insertOnConflictUpdate(
              VerseTopicsCompanion.insert(verseId: id, topicId: tid));
        }
        added++;
      }
    });
    return added;
  }

  // ---------- Photos ----------

  /// Resizes (max 2000 px long side) and stores the photo; returns its record.
  Future<Photo> addPhoto(Uint8List bytes) async {
    final jpg = await compute(_resizeToJpeg, bytes);
    final id = newId();
    final name = '$id.jpg';
    await File(p.join((await photoDir()).path, name)).writeAsBytes(jpg);
    final photo = Photo(id: id, path: name, boxX: 0.1, boxY: 0.55, boxW: 0.8);
    await db.into(db.photos).insert(photo);
    return photo;
  }

  /// Decodes and shrinks an image to at most 2000 px on the long side (JPEG).
  Future<Uint8List> shrinkImage(Uint8List bytes) =>
      compute(_resizeToJpeg, bytes);

  /// Overwrites the stored image of [photo] with [bytes] (shrunk first).
  Future<void> replacePhotoImage(Photo photo, Uint8List bytes) async {
    final jpg = await shrinkImage(bytes);
    await (await photoFile(photo)).writeAsBytes(jpg);
  }

  Future<void> savePhoto(Photo photo) =>
      db.into(db.photos).insertOnConflictUpdate(photo);

  Future<void> setPhotoTopics(String photoId, List<String> topicIds) =>
      db.transaction(() async {
        await (db.delete(db.photoTopics)
              ..where((t) => t.photoId.equals(photoId)))
            .go();
        for (final t in topicIds.toSet()) {
          await db.into(db.photoTopics).insert(
              PhotoTopicsCompanion.insert(photoId: photoId, topicId: t));
        }
      });

  Future<void> deletePhoto(Photo photo) async {
    await db.transaction(() async {
      await (db.update(db.verses)..where((v) => v.pinnedPhotoId.equals(photo.id)))
          .write(const VersesCompanion(pinnedPhotoId: Value(null)));
      await (db.delete(db.photoTopics)
            ..where((t) => t.photoId.equals(photo.id)))
          .go();
      await (db.delete(db.photos)..where((t) => t.id.equals(photo.id))).go();
    });
    final f = await photoFile(photo);
    if (await f.exists()) await f.delete();
  }

  // ---------- Photo pairing ----------

  /// Pinned photo, then topic-matched photo, then any photo. Photos in
  /// [recent] are skipped while other candidates exist.
  Future<Photo?> pairPhoto(
    Verse verse, {
    List<String> recent = const [],
    Random? random,
  }) async {
    final rng = random ?? Random();
    if (verse.pinnedPhotoId != null) {
      final pinned = await photoById(verse.pinnedPhotoId!);
      if (pinned != null) return pinned;
    }
    final topicIds = await topicIdsForVerse(verse.id);
    if (topicIds.isNotEmpty) {
      final q = db.select(db.photos).join([
        innerJoin(
            db.photoTopics, db.photoTopics.photoId.equalsExp(db.photos.id)),
      ])
        ..where(db.photoTopics.topicId.isIn(topicIds));
      final rows = await q.map((r) => r.readTable(db.photos)).get();
      final unique = {for (final ph in rows) ph.id: ph}.values.toList();
      final pick = _pick(unique, recent, rng);
      if (pick != null) return pick;
    }
    return _pick(await allPhotos(), recent, rng);
  }

  Photo? _pick(List<Photo> candidates, List<String> recent, Random rng) {
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.id.compareTo(b.id)); // stable for seeded picks
    final fresh = candidates.where((c) => !recent.contains(c.id)).toList();
    final pool = fresh.isNotEmpty ? fresh : candidates;
    return pool[rng.nextInt(pool.length)];
  }

  // ---------- Meta ----------

  Future<void> markBackedUp() => (db.update(db.appMeta)).write(
      AppMetaCompanion(lastBackup: Value(DateTime.now())));
}

class ImportedVerse {
  const ImportedVerse({
    required this.reference,
    required this.text,
    this.translation,
    this.topics = const [],
    this.favourite = false,
  });
  final String reference;
  final String text;
  final String? translation;
  final List<String> topics;
  final bool favourite;
}

Uint8List _resizeToJpeg(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Not a readable image');
  var image = img.bakeOrientation(decoded);
  const maxSide = 2000;
  final longSide = max(image.width, image.height);
  if (longSide > maxSide) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxSide)
        : img.copyResize(image, height: maxSide);
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 88));
}
