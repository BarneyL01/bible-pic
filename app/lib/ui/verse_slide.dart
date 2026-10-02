import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/layout.dart';
import '../data/providers.dart';
import '../db/database.dart';
import 'verse_canvas.dart';

/// Full-screen verse on its photo. Tap toggles favourite; the lock button
/// pins the shown photo to the verse.
class VerseSlide extends ConsumerStatefulWidget {
  const VerseSlide({super.key, required this.initialVerse, required this.photo});
  final Verse initialVerse;
  final Photo? photo;

  @override
  ConsumerState<VerseSlide> createState() => _VerseSlideState();
}

class _VerseSlideState extends ConsumerState<VerseSlide> {
  late Future<File?> _file;

  @override
  void initState() {
    super.initState();
    final p = widget.photo;
    _file = p == null
        ? Future.value(null)
        : ref.read(repositoryProvider).photoFile(p);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(repositoryProvider);
    // Live updates (favourite, edits) win; the snapshot covers the first frame.
    final verse =
        ref.watch(verseProvider(widget.initialVerse.id)).value ?? widget.initialVerse;
    // Re-resolve the theme whenever themes or topics change.
    ref.watch(themesProvider);
    ref.watch(topicsProvider);
    return FutureBuilder<AppTheme>(
      future: repo.resolveTheme(verse),
      builder: (context, themeSnap) {
        if (themeSnap.hasError) {
          return Center(
              child: Text('Could not load theme: ${themeSnap.error}',
                  textAlign: TextAlign.center));
        }
        final theme = themeSnap.data;
        if (theme == null) return const SizedBox.shrink();
        return FutureBuilder<File?>(
          future: _file,
          builder: (context, fileSnap) {
            final isPinned = verse.pinnedPhotoId != null &&
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
                    photoFile: fileSnap.data,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: SafeArea(
                      child: Row(
                        children: [
                          if (widget.photo != null)
                            IconButton(
                              tooltip: isPinned
                                  ? 'Photo locked to this verse'
                                  : 'Lock this photo to the verse',
                              icon: Icon(
                                isPinned ? Icons.lock : Icons.lock_open,
                                color: Colors.white,
                              ),
                              onPressed: isPinned
                                  ? null
                                  : () => repo.pinPhoto(
                                      verse.id, widget.photo!.id),
                            ),
                          Icon(
                            verse.favourite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.white,
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
