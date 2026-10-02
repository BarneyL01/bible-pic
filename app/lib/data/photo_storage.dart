import 'dart:typed_data';

/// Where photo image bytes live. Files on Android; the database on web.
/// Names are relative (`<uuid>.jpg`), never absolute paths.
abstract class PhotoStorage {
  Future<Uint8List?> read(String name);
  Future<void> write(String name, Uint8List bytes);
  Future<void> delete(String name);

  /// Removes every stored photo.
  Future<void> clear();
}
