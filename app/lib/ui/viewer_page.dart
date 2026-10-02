import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../db/database.dart';
import 'verse_slide.dart';

class _Item {
  const _Item(this.verse, this.photo);
  final Verse verse;
  final Photo? photo;
}

/// Swipes through a pool of verses. With [infinite] the pool is sampled at
/// random forever (main screen); otherwise each verse is shown once in order.
class ViewerPage extends ConsumerStatefulWidget {
  const ViewerPage({
    super.key,
    required this.pool,
    this.infinite = false,
    this.startVerseId,
    this.emptyMessage = 'No verses yet.',
  });

  final List<Verse> pool;
  final bool infinite;
  final String? startVerseId;
  final String emptyMessage;

  @override
  ConsumerState<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends ConsumerState<ViewerPage> {
  static const _recentWindow = 4;
  final _rng = Random();
  final _items = <int, Future<_Item>>{};
  final _recentPhotos = <String>[];
  Verse? _previous;

  Future<_Item> _itemAt(int index) => _items.putIfAbsent(index, () async {
        final repo = ref.read(repositoryProvider);
        Verse verse;
        if (!widget.infinite) {
          verse = widget.pool[index];
        } else if (index == 0 && widget.startVerseId != null) {
          verse = widget.pool.firstWhere((v) => v.id == widget.startVerseId,
              orElse: _randomVerse);
        } else {
          verse = _randomVerse();
        }
        _previous = verse;
        // Re-read so a pin or edit made since the pool snapshot is honoured.
        verse = await repo.verseById(verse.id) ?? verse;
        final photo = await repo.pairPhoto(verse, recent: _recentPhotos);
        if (photo != null) {
          _recentPhotos.add(photo.id);
          if (_recentPhotos.length > _recentWindow) _recentPhotos.removeAt(0);
        }
        return _Item(verse, photo);
      });

  Verse _randomVerse() {
    final pool = widget.pool;
    if (pool.length == 1) return pool.first;
    Verse v;
    do {
      v = pool[_rng.nextInt(pool.length)];
    } while (v.id == _previous?.id);
    return v;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pool.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(widget.emptyMessage, textAlign: TextAlign.center),
        ),
      );
    }
    return PageView.builder(
      itemCount: widget.infinite ? null : widget.pool.length,
      itemBuilder: (context, index) => FutureBuilder<_Item>(
        future: _itemAt(index),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load this verse:\n${snap.error}',
                    textAlign: TextAlign.center),
              ),
            );
          }
          final item = snap.data;
          if (item == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return VerseSlide(
            key: ValueKey('$index-${item.verse.id}'),
            initialVerse: item.verse,
            photo: item.photo,
          );
        },
      ),
    );
  }
}
