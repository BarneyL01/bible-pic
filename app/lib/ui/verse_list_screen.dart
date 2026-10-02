import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import 'verse_editor_screen.dart';

class VerseListScreen extends ConsumerWidget {
  const VerseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(versesProvider);
    final verses = async.value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Verses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const VerseEditorScreen())),
        child: const Icon(Icons.add),
      ),
      body: async.hasError && verses.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load verses:\n${async.error}',
                    textAlign: TextAlign.center),
              ),
            )
          : async.isLoading && verses.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : verses.isEmpty
          ? const Center(child: Text('No verses yet. Tap + to add one.'))
          : ListView.builder(
              itemCount: verses.length,
              itemBuilder: (context, i) {
                final v = verses[i];
                return ListTile(
                  title: Text(v.reference),
                  subtitle:
                      Text(v.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: v.favourite
                      ? const Icon(Icons.favorite, color: Colors.red)
                      : null,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => VerseEditorScreen(verseId: v.id))),
                );
              },
            ),
    );
  }
}
