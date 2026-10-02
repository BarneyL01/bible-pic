import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/repository.dart';
import '../db/database.dart';

class BackupException implements Exception {
  BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

enum RestoreMode { replace, merge }

class RestoreSummary {
  RestoreSummary({
    required this.verses,
    required this.topics,
    required this.photos,
    required this.themes,
    required this.missingPhotoFiles,
  });
  final int verses;
  final int topics;
  final int photos;
  final int themes;
  final int missingPhotoFiles;
}

class BackupService {
  BackupService(this.repo);
  final Repository repo;
  AppDatabase get db => repo.db;

  /// Builds the backup zip and opens the share sheet.
  Future<void> backUpNow({required String appVersion}) async {
    final data = <String, dynamic>{
      'verses': [for (final r in await db.select(db.verses).get()) r.toJson()],
      'topics': [for (final r in await db.select(db.topics).get()) r.toJson()],
      'photos': [for (final r in await db.select(db.photos).get()) r.toJson()],
      'themes': [for (final r in await db.select(db.themes).get()) r.toJson()],
      'verseTopics': [
        for (final r in await db.select(db.verseTopics).get()) r.toJson()
      ],
      'photoTopics': [
        for (final r in await db.select(db.photoTopics).get()) r.toJson()
      ],
    };
    final manifest = {
      'appVersion': appVersion,
      'schemaVersion': AppDatabase.dataSchemaVersion,
      'date': DateTime.now().toIso8601String(),
      'counts': {
        for (final e in data.entries) e.key: (e.value as List).length,
      },
    };

    final archive = Archive();
    void addText(String name, Object json) {
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(json)));
      archive.addFile(ArchiveFile.bytes(name, bytes));
    }

    addText('manifest.json', manifest);
    addText('data.json', data);
    final dir = await repo.photoDir();
    for (final photo in await repo.allPhotos()) {
      final f = File(p.join(dir.path, photo.path));
      if (await f.exists()) {
        archive.addFile(
            ArchiveFile.bytes('photos/${photo.path}', await f.readAsBytes()));
      }
    }

    final out = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final file = File(p.join(out.path, 'bible-pic-backup-$stamp.zip'));
    await file.writeAsBytes(ZipEncoder().encodeBytes(archive));
    await repo.markBackedUp();
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: 'Bible Pic backup $stamp',
    ));
  }

  Future<RestoreSummary> restore(String zipPath, RestoreMode mode) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await File(zipPath).readAsBytes());
    } catch (_) {
      throw BackupException('That file is not a valid backup zip.');
    }
    ArchiveFile? find(String name) =>
        archive.files.where((f) => f.isFile && f.name == name).firstOrNull;
    final manifestFile = find('manifest.json');
    final dataFile = find('data.json');
    if (manifestFile == null || dataFile == null) {
      throw BackupException('The zip is missing manifest.json or data.json.');
    }
    final manifest = jsonDecode(utf8.decode(manifestFile.readBytes()!)) as Map;
    final schema = manifest['schemaVersion'] as int? ?? 0;
    if (schema > AppDatabase.dataSchemaVersion) {
      throw BackupException(
          'This backup comes from a newer version of the app (schema $schema). '
          'Install the newer app version, then restore.');
    }
    final data = jsonDecode(utf8.decode(dataFile.readBytes()!)) as Map;
    List<Map<String, dynamic>> rows(String key) => [
          for (final r in (data[key] as List? ?? const []))
            Map<String, dynamic>.from(r as Map)
        ];

    final verses = rows('verses').map(Verse.fromJson).toList();
    final topics = rows('topics').map(Topic.fromJson).toList();
    final photos = rows('photos').map(Photo.fromJson).toList();
    var themes = rows('themes').map(AppTheme.fromJson).toList();
    final verseTopics = rows('verseTopics').map(VerseTopic.fromJson).toList();
    final photoTopics = rows('photoTopics').map(PhotoTopic.fromJson).toList();

    final dir = await repo.photoDir();
    if (mode == RestoreMode.replace) {
      // Replace wipes the photo folder, then the tables, then loads the backup.
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    } else {
      // Merge never adds a second default theme.
      themes = [for (final t in themes) t.copyWith(isDefault: false)];
    }

    var missing = 0;
    final existingPhotoIds = mode == RestoreMode.merge
        ? {for (final ph in await repo.allPhotos()) ph.id}
        : <String>{};
    for (final photo in photos) {
      final f = find('photos/${photo.path}');
      if (f == null) {
        missing++;
        continue;
      }
      final target = File(p.join(dir.path, photo.path));
      if (mode == RestoreMode.merge && existingPhotoIds.contains(photo.id)) {
        continue;
      }
      await target.writeAsBytes(f.readBytes()!);
    }

    final insert = mode == RestoreMode.replace
        ? InsertMode.insertOrReplace
        : InsertMode.insertOrIgnore;
    final before = mode == RestoreMode.merge
        ? await _counts()
        : const <String, int>{};

    await db.transaction(() async {
      if (mode == RestoreMode.replace) {
        await db.delete(db.verseTopics).go();
        await db.delete(db.photoTopics).go();
        await db.delete(db.verses).go();
        await db.delete(db.topics).go();
        await db.delete(db.photos).go();
        await db.delete(db.themes).go();
      }
      await db.batch((b) {
        b.insertAll(db.themes, themes, mode: insert);
        b.insertAll(db.topics, topics, mode: insert);
        b.insertAll(db.photos, photos, mode: insert);
        b.insertAll(db.verses, verses, mode: insert);
        b.insertAll(db.verseTopics, verseTopics, mode: insert);
        b.insertAll(db.photoTopics, photoTopics, mode: insert);
      });
      if (mode == RestoreMode.replace &&
          themes.isNotEmpty &&
          !themes.any((t) => t.isDefault)) {
        await (db.update(db.themes)..where((t) => t.id.equals(themes.first.id)))
            .write(const ThemesCompanion(isDefault: Value(true)));
      }
    });

    final after = await _counts();
    int added(String k) =>
        mode == RestoreMode.replace ? after[k]! : after[k]! - before[k]!;
    return RestoreSummary(
      verses: added('verses'),
      topics: added('topics'),
      photos: added('photos'),
      themes: added('themes'),
      missingPhotoFiles: missing,
    );
  }

  Future<Map<String, int>> _counts() async {
    Future<int> n(String table) async {
      final row =
          await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
      return row.read<int>('c');
    }

    return {
      'verses': await n('verses'),
      'topics': await n('topics'),
      'photos': await n('photos'),
      'themes': await n('themes'),
    };
  }
}
