import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../db/database.dart';
import 'letter_index.dart';

/// Opens the topic picker. Returns the chosen topic ids when the user taps
/// **Done**, or null when the sheet is dismissed (swipe, scrim, back); the
/// caller then keeps its previous selection.
Future<Set<String>?> showTopicPicker(
  BuildContext context, {
  required Set<String> selected,
  String? subject,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.9,
      child: _TopicPickerSheet(selected: selected, subject: subject),
    ),
  );
}

String verseCountLabel(int n) => n == 1 ? '1 verse' : '$n verses';

/// Counts of `verse_topics` rows per topic id.
Map<String, int> verseCounts(List<VerseTopic> links) {
  final counts = <String, int>{};
  for (final l in links) {
    counts[l.topicId] = (counts[l.topicId] ?? 0) + 1;
  }
  return counts;
}

class _TopicPickerSheet extends ConsumerStatefulWidget {
  const _TopicPickerSheet({required this.selected, this.subject});
  final Set<String> selected;
  final String? subject;

  @override
  ConsumerState<_TopicPickerSheet> createState() => _TopicPickerSheetState();
}

class _TopicPickerSheetState extends ConsumerState<_TopicPickerSheet> {
  late final Set<String> _selected = {...widget.selected};
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _headings = <String, GlobalKey>{};

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim();

  Future<void> _create() async {
    final id = await ref.read(repositoryProvider).topicIdForName(_query);
    if (!mounted) return;
    setState(() {
      _selected.add(id);
      _search.clear();
    });
  }

  /// [name] with the part matching the search in bold.
  Widget _highlighted(String name, TextStyle? base) {
    final q = _query.toLowerCase();
    final at = q.isEmpty ? -1 : name.toLowerCase().indexOf(q);
    if (at < 0) return Text(name, style: base);
    final bold = base?.copyWith(fontWeight: FontWeight.w800);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: name.substring(0, at)),
          TextSpan(text: name.substring(at, at + q.length), style: bold),
          TextSpan(text: name.substring(at + q.length)),
        ],
      ),
    );
  }

  Widget _row(Topic t, Map<String, int> counts) {
    final scheme = Theme.of(context).colorScheme;
    final on = _selected.contains(t.id);
    return CheckboxListTile(
      value: on,
      tileColor: on ? scheme.secondaryContainer : null,
      controlAffinity: ListTileControlAffinity.leading,
      title: _highlighted(t.name, Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(verseCountLabel(counts[t.id] ?? 0)),
      onChanged: (v) => setState(
        () => v == true ? _selected.add(t.id) : _selected.remove(t.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(topicsProvider).value ?? const <Topic>[];
    final counts = verseCounts(
      ref.watch(verseTopicsProvider).value ?? const <VerseTopic>[],
    );
    final scheme = Theme.of(context).colorScheme;
    final query = _query;
    final lower = query.toLowerCase();
    final exact = topics.any((t) => t.name.toLowerCase() == lower);
    final chosen = sortedByName(topics.where((t) => _selected.contains(t.id)));
    final matches = sortedByName(
      topics.where((t) => t.name.toLowerCase().contains(lower)),
    );
    final groups = groupByLetter(topics);
    final showIndex = query.isEmpty && groups.length > 1;
    final titleSuffix = widget.subject == null ? '' : ' for ${widget.subject}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Topics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${_selected.length} selected$titleSuffix',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, {..._selected}),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _search,
            focusNode: _searchFocus,
            decoration: InputDecoration(
              hintText: 'Search or create a topic',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty && _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      // Hand focus back to the field: the button that was
                      // pressed disappears, and typing must carry on.
                      onPressed: () {
                        setState(_search.clear);
                        _searchFocus.requestFocus();
                      },
                    ),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (query.isNotEmpty && !exact)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: Text('Create topic “$query” and add it'),
              ),
            ),
          ),
        if (chosen.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  for (final t in chosen)
                    FilterChip(
                      label: Text(t.name),
                      selected: true,
                      onSelected: (_) => setState(() => _selected.remove(t.id)),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        if (query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                matches.length == 1 ? '1 match' : '${matches.length} matches',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: topics.isEmpty
                    ? const Center(
                        child: Text(
                          'No topics yet. Type a name to create one.',
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: query.isNotEmpty
                              ? [for (final t in matches) _row(t, counts)]
                              : [
                                  for (final g in groups) ...[
                                    Padding(
                                      key: _headings.putIfAbsent(
                                        g.key,
                                        GlobalKey.new,
                                      ),
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        12,
                                        16,
                                        4,
                                      ),
                                      child: Text(
                                        g.key,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(color: scheme.primary),
                                      ),
                                    ),
                                    for (final t in g.value) _row(t, counts),
                                  ],
                                ],
                        ),
                      ),
              ),
              if (showIndex)
                LetterIndex(
                  letters: [for (final g in groups) g.key],
                  onJump: (l) => jumpToHeading(_headings[l]!),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A compact topic section: what is chosen as chips, optionally the most used
/// topics as one-tap additions, and a button that opens the full picker.
class TopicSelector extends ConsumerWidget {
  const TopicSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.subject,
    this.showUsedMost = false,
    this.hint,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  /// Named in the picker's subtitle ("2 selected for Psalm 23:1").
  final String? subject;

  /// Offer up to four unselected topics, most verses first.
  final bool showUsedMost;

  /// Appended to the "N of M" line.
  final String? hint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(topicsProvider).value ?? const <Topic>[];
    final counts = verseCounts(
      ref.watch(verseTopicsProvider).value ?? const <VerseTopic>[],
    );
    final chosen = sortedByName(topics.where((t) => selected.contains(t.id)));
    final candidates =
        topics
            .where((t) => !selected.contains(t.id) && (counts[t.id] ?? 0) > 0)
            .toList()
          ..sort((a, b) {
            final byCount = (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0);
            return byCount != 0
                ? byCount
                : a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
    final usedMost = candidates.take(4).toList();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Topics', style: theme.textTheme.titleSmall),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${chosen.length} of ${topics.length}${hint == null ? '' : ' · $hint'}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        if (chosen.isNotEmpty)
          Wrap(
            spacing: 8,
            children: [
              for (final t in chosen)
                InputChip(
                  label: Text(t.name),
                  deleteButtonTooltipMessage: 'Remove ${t.name}',
                  onDeleted: () => onChanged({...selected}..remove(t.id)),
                ),
            ],
          ),
        if (showUsedMost && usedMost.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Used most', style: theme.textTheme.labelMedium),
          Wrap(
            spacing: 8,
            children: [
              for (final t in usedMost)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text(t.name),
                  onPressed: () => onChanged({...selected, t.id}),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.search),
          label: Text(
            topics.isEmpty
                ? 'Add a topic'
                : 'Choose from all ${topics.length} topics',
          ),
          onPressed: () async {
            final result = await showTopicPicker(
              context,
              selected: selected,
              subject: subject,
            );
            if (result != null) onChanged(result);
          },
        ),
      ],
    );
  }
}
