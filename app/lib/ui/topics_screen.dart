import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../db/database.dart';
import 'viewer_page.dart';

class TopicsScreen extends ConsumerWidget {
  const TopicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(topicsProvider).value ?? const <Topic>[];
    final themes = ref.watch(themesProvider).value ?? const <AppTheme>[];
    final repo = ref.read(repositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Topics')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final name = await _askName(context, '');
          if (name != null && name.trim().isNotEmpty) {
            await repo.topicIdForName(name);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: topics.isEmpty
          ? const Center(child: Text('No topics yet. Tap + to add one.'))
          : ListView(
              children: [
                for (final t in topics)
                  ListTile(
                    title: Text(t.name),
                    subtitle: Text(
                      t.themeId == null
                          ? 'Default theme'
                          : 'Theme: ${themes.where((x) => x.id == t.themeId).map((x) => x.name).firstOrNull ?? '—'}',
                    ),
                    onTap: () async {
                      final verses = await repo.versesForTopic(t.id);
                      if (!context.mounted) return;
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          extendBodyBehindAppBar: true,
                          appBar: AppBar(
                            title: Text(t.name),
                            backgroundColor: Colors.black45,
                            foregroundColor: Colors.white,
                          ),
                          body: ViewerPage(
                            pool: verses,
                            emptyMessage: 'No verses in this topic yet.',
                          ),
                        ),
                      ));
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'rename') {
                          final name = await _askName(context, t.name);
                          if (name != null && name.trim().isNotEmpty) {
                            await repo.renameTopic(t.id, name);
                          }
                        } else if (v == 'theme') {
                          if (!context.mounted) return;
                          final picked = await showDialog<String>(
                            context: context,
                            builder: (_) => SimpleDialog(
                              title: const Text('Topic theme'),
                              children: [
                                SimpleDialogOption(
                                  onPressed: () =>
                                      Navigator.pop(context, ''),
                                  child: const Text('Use default theme'),
                                ),
                                for (final th in themes)
                                  SimpleDialogOption(
                                    onPressed: () =>
                                        Navigator.pop(context, th.id),
                                    child: Text(th.name),
                                  ),
                              ],
                            ),
                          );
                          if (picked != null) {
                            await repo.setTopicTheme(
                                t.id, picked.isEmpty ? null : picked);
                          }
                        } else if (v == 'delete') {
                          await repo.deleteTopic(t.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'theme', child: Text('Set theme')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

Future<String?> _askName(BuildContext context, String initial) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Topic name'),
      content: TextField(controller: controller, autofocus: true),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save')),
      ],
    ),
  );
}
