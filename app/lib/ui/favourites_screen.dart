import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../db/database.dart';
import 'viewer_page.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Verse>>(
      future: ref.read(repositoryProvider).favouriteVerses(),
      builder: (context, snap) {
        final verses = snap.data;
        if (verses == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Favourites')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return ViewerScaffold(
          title: 'Favourites',
          pool: verses,
          emptyMessage: 'No favourites yet. Tap a verse to favourite it.',
        );
      },
    );
  }
}
