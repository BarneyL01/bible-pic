import '../db/database.dart';
import 'repository.dart';

/// Verse override if set, otherwise the photo's default, otherwise a fallback.
BoxRect effectiveBox(Verse verse, Photo? photo) {
  if (verse.boxX != null && verse.boxY != null && verse.boxW != null) {
    return BoxRect(verse.boxX!, verse.boxY!, verse.boxW!);
  }
  if (photo != null) return BoxRect(photo.boxX, photo.boxY, photo.boxW);
  return const BoxRect(0.1, 0.55, 0.8);
}
