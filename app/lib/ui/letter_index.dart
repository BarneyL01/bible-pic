import 'package:flutter/material.dart';

import '../db/database.dart';

/// The heading letter for [name]: its first character upper-cased when that is
/// A to Z, otherwise `#`.
String letterOf(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '#';
  final c = trimmed[0].toUpperCase();
  return RegExp('[A-Z]').hasMatch(c) ? c : '#';
}

/// Topics ordered by name, ignoring case.
List<Topic> sortedByName(Iterable<Topic> topics) =>
    [...topics]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

/// Topics grouped under [letterOf] headings: A to Z, then `#`.
List<MapEntry<String, List<Topic>>> groupByLetter(Iterable<Topic> topics) {
  final groups = <String, List<Topic>>{};
  for (final t in sortedByName(topics)) {
    groups.putIfAbsent(letterOf(t.name), () => []).add(t);
  }
  final letters = groups.keys.toList()
    ..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });
  return [for (final l in letters) MapEntry(l, groups[l]!)];
}

/// Scrolls so the widget owning [key] is at the top of its scrollable.
void jumpToHeading(GlobalKey key) {
  final context = key.currentContext;
  if (context == null) return;
  Scrollable.ensureVisible(
    context,
    alignment: 0,
    duration: const Duration(milliseconds: 200),
  );
}

/// A narrow column of the letters that have topics. Tapping one calls [onJump].
class LetterIndex extends StatelessWidget {
  const LetterIndex({super.key, required this.letters, required this.onJump});
  final List<String> letters;
  final ValueChanged<String> onJump;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    return SizedBox(
      width: 24,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final l in letters)
            Flexible(
              child: Semantics(
                button: true,
                label: 'Jump to $l',
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => onJump(l),
                  child: Center(child: Text(l, style: style)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
