import 'package:flutter/services.dart';

/// Photos bundled with the app, in `assets/photos/` (declared in pubspec.yaml).
/// Each is cropped to a tall phone shape (9:20). They are added to the photo
/// library once, on first launch, by `Repository.seedDefaultPhotos`.
const kDefaultPhotoAssets = [
  'assets/photos/default-1.jpg',
  'assets/photos/default-2.jpg',
  'assets/photos/default-3.jpg',
  'assets/photos/default-4.jpg',
  'assets/photos/default-5.jpg',
];

Future<Uint8List> loadAssetBytes(String asset) async =>
    (await rootBundle.load(asset)).buffer.asUint8List();
