import 'dart:typed_data';

import 'package:bible_pic/data/photo_storage.dart';
import 'package:bible_pic/data/repository.dart';
import 'package:bible_pic/db/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryPhotoStorage implements PhotoStorage {
  final files = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String name) async => files[name];
  @override
  Future<void> write(String name, Uint8List bytes) async => files[name] = bytes;
  @override
  Future<void> delete(String name) async => files.remove(name);
  @override
  Future<void> clear() async => files.clear();
}

// Each test builds its own in-memory database.
void quietDriftWarnings() =>
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

Repository makeRepo({MemoryPhotoStorage? storage}) => Repository(
  AppDatabase(NativeDatabase.memory()),
  storage ?? MemoryPhotoStorage(),
);

Verse verse(String id, {String? pinned, String? themeId, bool fav = false}) =>
    Verse(
      id: id,
      reference: 'Ref $id',
      body: 'Body $id',
      translation: null,
      pinnedPhotoId: pinned,
      themeId: themeId,
      boxX: null,
      boxY: null,
      boxW: null,
      favourite: fav,
    );

Photo photo(String id) => Photo(
  id: id,
  path: '$id.jpg',
  boxX: 0.1,
  boxY: 0.5,
  boxW: 0.8,
  themeId: null,
);

/// Disposes the widget tree and lets drift's stream-cleanup timers fire, so a
/// widget test does not end with pending timers.
Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}
