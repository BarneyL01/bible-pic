import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../db/database.dart';
import 'bulk_import_screen.dart';
import 'favourites_screen.dart';
import 'photo_library_screen.dart';
import 'settings_screen.dart';
import 'themes_screen.dart';
import 'topics_screen.dart';
import 'verse_list_screen.dart';
import 'viewer_page.dart';

/// Fresh random verse each time the app opens (open question in the spec;
/// recorded in ADR 0006).
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late Future<List<Verse>> _pool;

  @override
  void initState() {
    super.initState();
    _pool = ref.read(repositoryProvider).allVerses();
  }

  void _open(Widget page) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => page))
      .then((_) {
        // Verses may have been added or removed; resample the pool.
        setState(() => _pool = ref.read(repositoryProvider).allVerses());
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        // A dark disc keeps the menu icon visible on bright photos and on the
        // empty state's light background.
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(6),
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
              tooltip: 'Menu',
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              _tile(Icons.topic, 'Topics', const TopicsScreen()),
              _tile(Icons.favorite, 'Favourites', const FavouritesScreen()),
              const Divider(),
              _tile(Icons.menu_book, 'Verses', const VerseListScreen()),
              _tile(
                Icons.photo_library,
                'Photo library',
                const PhotoLibraryScreen(),
              ),
              _tile(Icons.palette, 'Themes', const ThemesScreen()),
              _tile(Icons.upload_file, 'Bulk import', const BulkImportScreen()),
              const Divider(),
              _tile(Icons.settings, 'Settings', const SettingsScreen()),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Verse>>(
        future: _pool,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final verses = snap.data!;
          if (verses.isEmpty) return _emptyState();
          return ViewerPage(pool: verses, infinite: true);
        },
      ),
    );
  }

  Widget _tile(IconData icon, String title, Widget page) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    onTap: () {
      Navigator.of(context).pop(); // close drawer
      _open(page);
    },
  );

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No verses yet.', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _open(const VerseListScreen()),
            child: const Text('Add a verse'),
          ),
          TextButton(
            onPressed: () => _open(const BulkImportScreen()),
            child: const Text('Bulk import'),
          ),
          TextButton(
            onPressed: () => _open(const BackupScreen()),
            child: const Text('Restore from a backup'),
          ),
        ],
      ),
    ),
  );
}
