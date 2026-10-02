import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:bible_pic/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Uint8List bytes(List<int> b) => Uint8List.fromList(b);

void main() {
  setUpAll(quietDriftWarnings);

  Future<(MemoryPhotoStorage, BackupService)> seeded() async {
    final storage = MemoryPhotoStorage();
    final repo = makeRepo(storage: storage);
    storage.files['p1.jpg'] = bytes([1, 2, 3]);
    await repo.savePhoto(photo('p1'));
    final topic = await repo.topicIdForName('hope');
    await repo.saveVerse(verse('v1', pinned: 'p1', fav: true), [topic]);
    await repo.saveVerse(verse('v2'), const []);
    return (storage, BackupService(repo));
  }

  test(
    'Replace restore reproduces verses, topics, links and photo bytes',
    () async {
      final (_, source) = await seeded();
      final zip = await source.buildBackup(appVersion: 'test');

      final targetStorage = MemoryPhotoStorage()
        ..files['stale.jpg'] = bytes([9]);
      final targetRepo = makeRepo(storage: targetStorage);
      await targetRepo.saveVerse(verse('old'), const []);
      final summary = await BackupService(
        targetRepo,
      ).restore(zip, RestoreMode.replace);

      expect([summary.verses, summary.topics, summary.photos], [2, 1, 1]);
      expect(summary.missingPhotoFiles, 0);
      expect((await targetRepo.allVerses()).map((v) => v.id).toSet(), {
        'v1',
        'v2',
      });
      expect((await targetRepo.verseById('v1'))!.favourite, isTrue);
      expect(await targetRepo.topicIdsForVerse('v1'), hasLength(1));
      expect(targetStorage.files.keys, ['p1.jpg']); // stale file removed
      expect(targetStorage.files['p1.jpg'], [1, 2, 3]);
      expect((await targetRepo.defaultTheme()), isNotNull);
    },
  );

  test('Merge restore adds only what is missing', () async {
    final (_, source) = await seeded();
    final zip = await source.buildBackup(appVersion: 'test');

    final repo = makeRepo();
    await repo.saveVerse(verse('v1'), const []); // already present
    await repo.saveVerse(verse('mine'), const []);
    final summary = await BackupService(repo).restore(zip, RestoreMode.merge);

    expect(summary.verses, 1); // only v2 is new
    expect((await repo.allVerses()).map((v) => v.id).toSet(), {
      'v1',
      'v2',
      'mine',
    });
    expect(
      (await repo.verseById('v1'))!.favourite,
      isFalse,
    ); // kept the local one
  });

  test('a schema 1 backup without referenceFontSize still restores', () async {
    final archive = Archive()
      ..addFile(
        ArchiveFile.bytes(
          'manifest.json',
          bytes(
            utf8.encode(jsonEncode({'schemaVersion': 1, 'appVersion': '0'})),
          ),
        ),
      )
      ..addFile(
        ArchiveFile.bytes(
          'data.json',
          bytes(
            utf8.encode(
              jsonEncode({
                'themes': [
                  {
                    'id': 't',
                    'name': 'Old',
                    'font': 'serif',
                    'fontSize': 30.0,
                    'textColor': 0xFFFFFFFF,
                    'alignment': 'left',
                    'panelColor': 0xFF000000,
                    'panelOpacity': 0.5,
                    'cornerRadius': 12.0,
                    'isDefault': true,
                  },
                ],
              }),
            ),
          ),
        ),
      );
    final repo = makeRepo();
    await BackupService(
      repo,
    ).restore(bytes(ZipEncoder().encodeBytes(archive)), RestoreMode.replace);
    final theme = await repo.defaultTheme();
    expect(theme!.id, 't');
    expect(theme.referenceFontSize, closeTo(18, 0.001)); // 60% of 30
  });

  test(
    'a backup from a newer schema is refused with a clear message',
    () async {
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes(
            'manifest.json',
            bytes(utf8.encode(jsonEncode({'schemaVersion': 99}))),
          ),
        )
        ..addFile(ArchiveFile.bytes('data.json', bytes(utf8.encode('{}'))));
      expect(
        () => BackupService(makeRepo()).restore(
          bytes(ZipEncoder().encodeBytes(archive)),
          RestoreMode.replace,
        ),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('newer version'),
          ),
        ),
      );
    },
  );

  test('a file that is not a zip is refused', () async {
    expect(
      () => BackupService(
        makeRepo(),
      ).restore(bytes([1, 2, 3]), RestoreMode.merge),
      throwsA(isA<BackupException>()),
    );
  });
}
