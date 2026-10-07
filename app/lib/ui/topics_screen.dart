import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../db/database.dart';
import 'grouped_list.dart';
import 'letter_index.dart';
import 'topic_picker.dart';
import 'viewer_page.dart';

enum TopicSort { az, mostVerses }

String photoCountLabel(int n) =>
    n == 0 ? 'no photo' : (n == 1 ? '1 photo' : '$n photos');

/// Counts of `photo_topics` rows per topic id.
Map<String, int> photoCounts(List<PhotoTopic> links) {
  final counts = <String, int>{};
  for (final l in links) {
    counts[l.topicId] = (counts[l.topicId] ?? 0) + 1;
  }
  return counts;
}

class TopicsScreen extends ConsumerStatefulWidget {
  const TopicsScreen({super.key});

  @override
  ConsumerState<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends ConsumerState<TopicsScreen> {
  final _search = TextEditingController();
  TopicSort _sort = TopicSort.az;
  bool _noPhotoOnly = false;
  final _headings = <String, GlobalKey>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ---------- actions on one topic ----------

  Future<void> _open(Topic t) async {
    final verses = await ref.read(repositoryProvider).versesForTopic(t.id);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ViewerScaffold(
          title: t.name,
          pool: verses,
          emptyMessage: 'No verses in this topic yet.',
        ),
      ),
    );
  }

  Future<void> _rename(Topic t) async {
    final name = await _askName(context, t.name);
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(repositoryProvider).renameTopic(t.id, name);
    }
  }

  Future<void> _setTheme(Topic t) async {
    final themes = ref.read(themesProvider).value ?? const <AppTheme>[];
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Topic theme'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Use default theme'),
          ),
          for (final th in themes)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, th.id),
              child: Text(th.name),
            ),
        ],
      ),
    );
    if (picked != null) {
      await ref
          .read(repositoryProvider)
          .setTopicTheme(t.id, picked.isEmpty ? null : picked);
    }
  }

  Future<void> _newTopic() async {
    final name = await _askName(context, '');
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(repositoryProvider).topicIdForName(name);
    }
  }

  // ---------- building ----------

  Widget _row(
    Topic t, {
    required bool isFirst,
    required bool isLast,
    required Map<String, int> verses,
    required Map<String, int> photos,
    required List<AppTheme> themes,
  }) {
    final themeName = t.themeId == null
        ? null
        : themes.where((x) => x.id == t.themeId).map((x) => x.name).firstOrNull;
    final small = Theme.of(context).textTheme.labelSmall;
    return GroupedTile(
      isFirst: isFirst,
      isLast: isLast,
      title: Text(t.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${verseCountLabel(verses[t.id] ?? 0)} · ${photoCountLabel(photos[t.id] ?? 0)}',
          ),
          if (t.themeId != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.palette_outlined, size: 14, color: small?.color),
                const SizedBox(width: 4),
                Text(themeName ?? '—', style: small),
              ],
            ),
        ],
      ),
      onTap: () => _open(t),
      trailing: PopupMenuButton<String>(
        tooltip: 'More for ${t.name}',
        onSelected: (v) async {
          if (v == 'rename') {
            await _rename(t);
          } else if (v == 'theme') {
            await _setTheme(t);
          } else if (v == 'delete') {
            await ref.read(repositoryProvider).deleteTopic(t.id);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'rename', child: Text('Rename')),
          PopupMenuItem(value: 'theme', child: Text('Set theme')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(topicsProvider).value ?? const <Topic>[];
    final themes = ref.watch(themesProvider).value ?? const <AppTheme>[];
    final verses = verseCounts(
      ref.watch(verseTopicsProvider).value ?? const <VerseTopic>[],
    );
    final photos = photoCounts(
      ref.watch(photoTopicsProvider).value ?? const <PhotoTopic>[],
    );
    final scheme = Theme.of(context).colorScheme;
    final query = _search.text.trim();
    final lower = query.toLowerCase();
    final noPhotoCount = topics.where((t) => (photos[t.id] ?? 0) == 0).length;

    var shown = topics.where((t) => t.name.toLowerCase().contains(lower));
    if (_noPhotoOnly) shown = shown.where((t) => (photos[t.id] ?? 0) == 0);
    final grouped = _sort == TopicSort.az && query.isEmpty;
    final ordered = _sort == TopicSort.az
        ? sortedByName(shown)
        : (shown.toList()..sort((a, b) {
            final byCount = (verses[b.id] ?? 0).compareTo(verses[a.id] ?? 0);
            return byCount != 0
                ? byCount
                : a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }));
    final groups = grouped ? groupByLetter(ordered) : [MapEntry('', ordered)];
    final showIndex = grouped && groups.length > 1;

    Widget list;
    if (topics.isEmpty) {
      list = const Center(
        child: Text('No topics yet. Tap New topic to add one.'),
      );
    } else if (ordered.isEmpty) {
      list = Center(
        child: Text(
          query.isNotEmpty
              ? 'No topics match “$query”'
              : 'Every topic has a photo.',
        ),
      );
    } else {
      // A Column, not a lazy ListView: the letter index scrolls to headings that
      // must already be built.
      list = SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final g in groups) ...[
              if (grouped)
                Padding(
                  key: _headings.putIfAbsent(g.key, GlobalKey.new),
                  padding: const EdgeInsets.fromLTRB(28, 16, 16, 6),
                  child: Text(
                    g.key,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: scheme.primary),
                  ),
                ),
              for (var i = 0; i < g.value.length; i++)
                _row(
                  g.value[i],
                  isFirst: i == 0,
                  isLast: i == g.value.length - 1,
                  verses: verses,
                  photos: photos,
                  themes: themes,
                ),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Topics')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newTopic,
        icon: const Icon(Icons.add),
        label: const Text('New topic'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search topics',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(_search.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<TopicSort>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: TopicSort.az, label: Text('A–Z')),
                    ButtonSegment(
                      value: TopicSort.mostVerses,
                      label: Text('Most verses'),
                    ),
                  ],
                  selected: {_sort},
                  onSelectionChanged: (s) => setState(() => _sort = s.first),
                ),
                FilterChip(
                  label: Text('No photo · $noPhotoCount'),
                  selected: _noPhotoOnly,
                  onSelected: (v) => setState(() => _noPhotoOnly = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: list),
                if (showIndex)
                  LetterIndex(
                    letters: [for (final g in groups) g.key],
                    onJump: (l) => jumpToHeading(_headings[l]!),
                  ),
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
