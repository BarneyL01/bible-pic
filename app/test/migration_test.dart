import 'dart:io';

import 'package:bible_pic/db/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  test('schema 1 database upgrades to 2 and gains referenceFontSize', () async {
    final dir = Directory.systemTemp.createTempSync('bible_pic_migration');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    // Build a current database, then rewind it to look like schema 1.
    var db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.customStatement(
      'ALTER TABLE themes DROP COLUMN reference_font_size',
    );
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    final columns = await db.customSelect('PRAGMA table_info(themes)').get();
    expect(
      columns.map((c) => c.read<String>('name')),
      contains('reference_font_size'),
    );
    final theme = await (db.select(db.themes)..limit(1)).getSingle();
    expect(theme.referenceFontSize, 16);
    final meta = await db.select(db.appMeta).getSingle();
    expect(meta.schemaVersion, 2);
    await db.close();
  });
}
