import 'dart:math';
import 'dart:typed_data';

import 'package:bible_pic/db/database.dart';
import 'package:bible_pic/services/widget_sync.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  setUpAll(quietDriftWarnings);
  test('a saved verse is emitted by watchVerses', () async {
    final repo = makeRepo();
    final expectation = expectLater(
      repo.watchVerses(),
      emitsThrough(predicate<List<Verse>>((l) => l.length == 1)),
    );
    await repo.saveVerse(verse('a'), const []);
    await expectation;
  });

  group('photo pairing', () {
    test('pinned photo wins, then topic match, then any', () async {
      final repo = makeRepo();
      for (final id in ['p1', 'p2', 'p3']) {
        await repo.savePhoto(photo(id));
      }
      final topic = await repo.topicIdForName('hope');
      await repo.setPhotoTopics('p2', [topic]);

      await repo.saveVerse(verse('v', pinned: 'p3'), [topic]);
      expect((await repo.pairPhoto((await repo.verseById('v'))!))!.id, 'p3');

      await repo.saveVerse(verse('v'), [topic]);
      for (var i = 0; i < 10; i++) {
        expect((await repo.pairPhoto((await repo.verseById('v'))!))!.id, 'p2');
      }

      await repo.saveVerse(verse('w'), const []);
      final seen = {
        for (var i = 0; i < 60; i++)
          (await repo.pairPhoto((await repo.verseById('w'))!))!.id,
      };
      expect(seen, {'p1', 'p2', 'p3'});
    });

    test('recent photos are skipped while others exist', () async {
      final repo = makeRepo();
      await repo.savePhoto(photo('a'));
      await repo.savePhoto(photo('b'));
      await repo.saveVerse(verse('v'), const []);
      final v = (await repo.verseById('v'))!;
      for (var i = 0; i < 20; i++) {
        expect((await repo.pairPhoto(v, recent: ['a']))!.id, 'b');
      }
      // Nothing else left: falls back to the recent one rather than none.
      expect((await repo.pairPhoto(v, recent: ['a', 'b'])), isNotNull);
    });

    test('no photos gives null', () async {
      final repo = makeRepo();
      await repo.saveVerse(verse('v'), const []);
      expect(await repo.pairPhoto((await repo.verseById('v'))!), isNull);
    });
  });

  test('theme resolves verse, then topic, then default', () async {
    final repo = makeRepo();
    AppTheme theme(String id) => AppTheme(
      id: id,
      name: id,
      font: 'serif',
      fontSize: 30,
      referenceFontSize: 18,
      textColor: 0xFFFFFFFF,
      alignment: 'left',
      panelColor: 0xFF000000,
      panelOpacity: 0.5,
      cornerRadius: 8,
      isDefault: false,
    );
    await repo.saveTheme(theme('verse-theme'));
    await repo.saveTheme(theme('topic-theme'));
    final topic = await repo.topicIdForName('peace');
    await repo.setTopicTheme(topic, 'topic-theme');

    await repo.saveVerse(verse('plain'), const []);
    expect(
      (await repo.resolveTheme((await repo.verseById('plain'))!)).id,
      'default-theme',
    );

    await repo.saveVerse(verse('topical'), [topic]);
    expect(
      (await repo.resolveTheme((await repo.verseById('topical'))!)).id,
      'topic-theme',
    );

    await repo.saveVerse(verse('own', themeId: 'verse-theme'), [topic]);
    expect(
      (await repo.resolveTheme((await repo.verseById('own'))!)).id,
      'verse-theme',
    );
  });

  test('the text box override beats the photo default', () async {
    final repo = makeRepo();
    await repo.saveVerse(verse('v'), const []);
    final base = (await repo.verseById('v'))!;
    expect(base.boxX, isNull);
    await repo.saveVerse(
      base.copyWith(
        boxX: const Value(0.2),
        boxY: const Value(0.3),
        boxW: const Value(0.5),
      ),
      const [],
    );
    final v = (await repo.verseById('v'))!;
    expect([v.boxX, v.boxY, v.boxW], [0.2, 0.3, 0.5]);
  });

  test('saving a verse can clear its pin, theme and box override', () async {
    final repo = makeRepo();
    await repo.savePhoto(photo('p'));
    await repo.saveVerse(
      verse('v', pinned: 'p', themeId: 'default-theme').copyWith(
        boxX: const Value(0.2),
        boxY: const Value(0.3),
        boxW: const Value(0.5),
      ),
      const [],
    );
    await repo.saveVerse(verse('v'), const []); // all three cleared
    final v = (await repo.verseById('v'))!;
    expect(
      [v.pinnedPhotoId, v.themeId, v.boxX, v.boxY, v.boxW],
      [null, null, null, null, null],
    );
  });

  group('photo themes and bulk actions', () {
    AppTheme theme(String id) => AppTheme(
      id: id,
      name: id,
      font: 'serif',
      fontSize: 30,
      referenceFontSize: 18,
      textColor: 0xFFFFFFFF,
      alignment: 'left',
      panelColor: 0xFF000000,
      panelOpacity: 0.5,
      cornerRadius: 8,
      isDefault: false,
    );

    test('theme order: verse, then photo, then topic, then default', () async {
      final repo = makeRepo();
      await repo.saveTheme(theme('verse-theme'));
      await repo.saveTheme(theme('photo-theme'));
      await repo.saveTheme(theme('topic-theme'));
      final topic = await repo.topicIdForName('peace');
      await repo.setTopicTheme(topic, 'topic-theme');
      await repo.savePhoto(photo('p'));
      await repo.setPhotosTheme(['p'], 'photo-theme');
      final p = (await repo.photoById('p'))!;

      await repo.saveVerse(verse('v'), [topic]);
      Future<String> resolved(String id, {Photo? on}) async =>
          (await repo.resolveTheme((await repo.verseById(id))!, photo: on)).id;

      expect(await resolved('v'), 'topic-theme'); // no photo: topic theme
      expect(await resolved('v', on: p), 'photo-theme'); // photo beats topic
      await repo.saveVerse(verse('own', themeId: 'verse-theme'), [topic]);
      expect(await resolved('own', on: p), 'verse-theme'); // verse beats photo

      await repo.setPhotosTheme(['p'], null); // cleared
      expect(
        await resolved('v', on: (await repo.photoById('p'))!),
        'topic-theme',
      );
    });

    test('setPhotosTheme changes only the selected photos', () async {
      final repo = makeRepo();
      await repo.saveTheme(theme('t'));
      for (final id in ['a', 'b', 'c']) {
        await repo.savePhoto(photo(id));
      }
      await repo.setPhotosTheme(['a', 'c'], 't');
      expect((await repo.photoById('a'))!.themeId, 't');
      expect((await repo.photoById('b'))!.themeId, isNull);
      expect((await repo.photoById('c'))!.themeId, 't');
    });

    test('deleting a theme clears it from photos', () async {
      final repo = makeRepo();
      await repo.saveTheme(theme('t'));
      await repo.savePhoto(photo('a'));
      await repo.setPhotosTheme(['a'], 't');
      await repo.deleteTheme('t');
      expect((await repo.photoById('a'))!.themeId, isNull);
    });

    test(
      'applyTopicsToPhotos adds and removes without touching others',
      () async {
        final repo = makeRepo();
        for (final id in ['a', 'b']) {
          await repo.savePhoto(photo(id));
        }
        final hope = await repo.topicIdForName('hope');
        final peace = await repo.topicIdForName('peace');
        final joy = await repo.topicIdForName('joy');
        await repo.setPhotoTopics('a', [hope, joy]);
        await repo.setPhotoTopics('b', [joy]);

        await repo.applyTopicsToPhotos(
          ['a', 'b'],
          add: {peace},
          remove: {hope},
        );
        expect((await repo.topicIdsForPhoto('a')).toSet(), {peace, joy});
        expect((await repo.topicIdsForPhoto('b')).toSet(), {peace, joy});

        // Adding a topic a photo already has is not an error.
        await repo.applyTopicsToPhotos(['a'], add: {peace});
        expect((await repo.topicIdsForPhoto('a')).toSet(), {peace, joy});
      },
    );

    test('deletePhotos removes rows, bytes and pins', () async {
      final storage = MemoryPhotoStorage();
      final repo = makeRepo(storage: storage);
      for (final id in ['a', 'b', 'c']) {
        storage.files['$id.jpg'] = Uint8List.fromList([1]);
        await repo.savePhoto(photo(id));
      }
      await repo.saveVerse(verse('v', pinned: 'a'), const []);
      await repo.deletePhotos([
        (await repo.photoById('a'))!,
        (await repo.photoById('b'))!,
      ]);
      expect((await repo.allPhotos()).map((p) => p.id), ['c']);
      expect(storage.files.keys, ['c.jpg']);
      expect((await repo.verseById('v'))!.pinnedPhotoId, isNull);
    });
  });

  group('default photos', () {
    final assets = ['a.jpg', 'b.jpg', 'c.jpg'];
    Future<Uint8List> load(String asset) async =>
        Uint8List.fromList(asset.codeUnits);

    test('are added once, with their bytes, under fixed ids', () async {
      final storage = MemoryPhotoStorage();
      final repo = makeRepo(storage: storage);
      await repo.seedDefaultPhotos(assets, load);
      final photos = await repo.allPhotos();
      expect(photos.map((p) => p.id).toSet(), {
        'default-photo-1',
        'default-photo-2',
        'default-photo-3',
      });
      expect(storage.files['default-photo-2.jpg'], 'b.jpg'.codeUnits);

      await repo.seedDefaultPhotos(assets, load); // second launch
      expect(await repo.allPhotos(), hasLength(3));
    });

    test('a deleted default photo does not come back', () async {
      final repo = makeRepo();
      await repo.seedDefaultPhotos(assets, load);
      await repo.deletePhoto((await repo.photoById('default-photo-1'))!);
      await repo.seedDefaultPhotos(assets, load);
      expect(await repo.photoById('default-photo-1'), isNull);
      expect(await repo.allPhotos(), hasLength(2));
    });

    test('are paired like any other photo', () async {
      final repo = makeRepo();
      await repo.seedDefaultPhotos(assets, load);
      await repo.saveVerse(verse('v'), const []);
      expect(await repo.pairPhoto((await repo.verseById('v'))!), isNotNull);
    });
  });

  test('a photo can be locked to a verse and unlocked again', () async {
    final repo = makeRepo();
    await repo.savePhoto(photo('p'));
    await repo.saveVerse(verse('v'), const []);
    await repo.pinPhoto('v', 'p');
    expect((await repo.verseById('v'))!.pinnedPhotoId, 'p');
    await repo.pinPhoto('v', null);
    expect((await repo.verseById('v'))!.pinnedPhotoId, isNull);
  });

  test('verse of the day is stable for a date and independent of order', () {
    final verses = [
      for (final id in ['c', 'a', 'b', 'd']) verse(id),
    ];
    final day = DateTime(2026, 10, 2);
    final first = verseOfTheDay(verses, day);
    expect(verseOfTheDay(verses.reversed.toList(), day).id, first.id);
    expect(verseOfTheDay(verses, day).id, first.id);
    final across = {
      for (var i = 0; i < 40; i++)
        verseOfTheDay(verses, DateTime(2026, 10, 1 + i)).id,
    };
    expect(across.length, greaterThan(1));
    expect(Random(1).nextInt(2), isNotNull); // keep dart:math import honest
  });
}
