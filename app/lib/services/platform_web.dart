import 'dart:js_interop';

import 'package:drift/drift.dart';
import 'package:web/web.dart' as web;

import '../data/photo_storage.dart';
import '../db/database.dart';

/// Photos as BLOB rows in the app's own database (persisted by the browser),
/// so backups and the library work without a file system.
class DbPhotoStorage implements PhotoStorage {
  DbPhotoStorage(this._db);
  final AppDatabase _db;
  Future<void>? _ready;

  Future<void> _init() => _ready ??= _db.customStatement(
    'CREATE TABLE IF NOT EXISTS photo_blobs '
    '(name TEXT NOT NULL PRIMARY KEY, bytes BLOB NOT NULL)',
  );

  @override
  Future<Uint8List?> read(String name) async {
    await _init();
    final row = await _db
        .customSelect(
          'SELECT bytes FROM photo_blobs WHERE name = ?',
          variables: [Variable.withString(name)],
        )
        .getSingleOrNull();
    return row?.read<Uint8List>('bytes');
  }

  @override
  Future<void> write(String name, Uint8List bytes) async {
    await _init();
    await _db.customStatement(
      'INSERT OR REPLACE INTO photo_blobs (name, bytes) VALUES (?, ?)',
      [name, bytes],
    );
  }

  @override
  Future<void> delete(String name) async {
    await _init();
    await _db.customStatement('DELETE FROM photo_blobs WHERE name = ?', [name]);
  }

  @override
  Future<void> clear() async {
    await _init();
    await _db.customStatement('DELETE FROM photo_blobs');
  }
}

PhotoStorage createPhotoStorage(AppDatabase db) => DbPhotoStorage(db);

/// Starts a browser download of [bytes] as [name].
Future<void> exportFile(String name, Uint8List bytes) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/octet-stream'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  anchor.click();
  web.URL.revokeObjectURL(url);
}

const bool kHomeWidgetSupported = false;
