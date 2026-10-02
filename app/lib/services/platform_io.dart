import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/photo_storage.dart';
import '../db/database.dart';

/// Photos as files under `<app documents>/photos/`.
class FilePhotoStorage implements PhotoStorage {
  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'photos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _file(String name) async =>
      File(p.join((await _dir()).path, name));

  @override
  Future<Uint8List?> read(String name) async {
    final f = await _file(name);
    return await f.exists() ? f.readAsBytes() : null;
  }

  @override
  Future<void> write(String name, Uint8List bytes) async =>
      (await _file(name)).writeAsBytes(bytes);

  @override
  Future<void> delete(String name) async {
    final f = await _file(name);
    if (await f.exists()) await f.delete();
  }

  @override
  Future<void> clear() async {
    final dir = await _dir();
    await dir.delete(recursive: true);
    await dir.create(recursive: true);
  }
}

PhotoStorage createPhotoStorage(AppDatabase db) => FilePhotoStorage();

/// Hands a finished file to the user: writes it to a temp file and opens the
/// share sheet.
Future<void> exportFile(String name, Uint8List bytes) async {
  final out = await getTemporaryDirectory();
  final file = File(p.join(out.path, name));
  await file.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: name),
  );
}

const bool kHomeWidgetSupported = true;
