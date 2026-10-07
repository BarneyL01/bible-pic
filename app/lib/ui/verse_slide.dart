import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/layout.dart';
import '../data/providers.dart';
import '../db/database.dart';
import 'verse_canvas.dart';

/// Full-screen verse on its photo. Tap toggles favourite; the lock button
/// pins the shown photo to the verse.
class VerseSlide extends ConsumerStatefulWidget {
  const VerseSlide({
    super.key,
    required this.initialVerse,
    required this.photo,
  });
  final Verse initialVerse;
  final Photo? photo;

  @override
  ConsumerState<VerseSlide> createState() => _VerseSlideState();
}

/// Top of the icon row so its centre lines up with the menu button. The viewer
/// body is padded below its app bar, so the row sits at that padding minus the
/// app bar's height (or at the status bar when there is no app bar).
double _toolbarTop(BuildContext context) {
  final top = MediaQuery.paddingOf(context).top;
  return top >= kToolbarHeight ? top - kToolbarHeight : top;
}

/// A small, translucent icon that stays readable on any photo but does not
/// compete with the verse. [strong] makes an active state a little clearer.
Widget _quietIcon(IconData icon, {required bool strong}) => Icon(
  icon,
  size: 22,
  color: Colors.white.withValues(alpha: strong ? 0.85 : 0.5),
  shadows: const [Shadow(blurRadius: 3, color: Colors.black54)],
);

class _VerseSlideState extends ConsumerState<VerseSlide> {
  late Future<ImageProvider?> _image;

  @override
  void initState() {
    super.initState();
    final p = widget.photo;
    _image = p == null
        ? Future.value(null)
        : ref.read(repositoryProvider).photoImage(p);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(repositoryProvider);
    // Live updates (favourite, edits) win; the snapshot covers the first frame.
    final verse =
        ref.watch(verseProvider(widget.initialVerse.id)).value ??
        widget.initialVerse;
    // Re-resolve the theme whenever themes or topics change.
    ref.watch(themesProvider);
    ref.watch(topicsProvider);
    return FutureBuilder<AppTheme>(
      future: repo.resolveTheme(verse, photo: widget.photo),
      builder: (context, themeSnap) {
        if (themeSnap.hasError) {
          return Center(
            child: Text(
              'Could not load theme: ${themeSnap.error}',
              textAlign: TextAlign.center,
            ),
          );
        }
        final theme = themeSnap.data;
        if (theme == null) return const SizedBox.shrink();
        return FutureBuilder<ImageProvider?>(
          future: _image,
          builder: (context, fileSnap) {
            final isPinned =
                verse.pinnedPhotoId != null &&
                verse.pinnedPhotoId == widget.photo?.id;
            return GestureDetector(
              onTap: () => repo.setFavourite(verse.id, !verse.favourite),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VerseCanvas(
                    reference: verse.translation == null
                        ? verse.reference
                        : '${verse.reference} (${verse.translation})',
                    text: verse.body,
                    theme: theme,
                    box: effectiveBox(verse, widget.photo),
                    photoProvider: fileSnap.data,
                  ),
                  // Quiet status icons in the menu button's row, top right. The
                  // viewer's body is padded below its (transparent) app bar, so
                  // the row starts at that padding minus the app bar's height.
                  Positioned(
                    top: _toolbarTop(context),
                    right: 4,
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.photo != null)
                            IconButton(
                              tooltip: isPinned
                                  ? 'Unlock photo'
                                  : 'Lock this photo to the verse',
                              visualDensity: VisualDensity.compact,
                              icon: _quietIcon(
                                isPinned ? Icons.lock : Icons.lock_open,
                                strong: isPinned,
                              ),
                              // Tapping a locked photo unlocks it, so the
                              // app picks photos for this verse again.
                              onPressed: () => repo.pinPhoto(
                                verse.id,
                                isPinned ? null : widget.photo!.id,
                              ),
                            ),
                          // A real button; tapping anywhere on the verse still
                          // toggles favourite too.
                          IconButton(
                            tooltip: verse.favourite
                                ? 'Remove from favourites'
                                : 'Add to favourites',
                            visualDensity: VisualDensity.compact,
                            icon: _quietIcon(
                              verse.favourite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              strong: verse.favourite,
                            ),
                            onPressed: () =>
                                repo.setFavourite(verse.id, !verse.favourite),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
