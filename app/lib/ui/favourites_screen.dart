import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../db/database.dart';
import 'viewer_page.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Favourites'),
        backgroundColor: Colors.black45,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Verse>>(
        future: ref.read(repositoryProvider).favouriteVerses(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ViewerPage(
            pool: snap.data!,
            emptyMessage: 'No favourites yet. Tap a verse to favourite it.',
          );
        },
      ),
    );
  }
}
