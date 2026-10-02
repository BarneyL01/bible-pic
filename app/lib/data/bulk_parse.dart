import 'dart:convert';

import 'repository.dart';

/// Parses pasted text into verses.
///
/// Blocks are separated by a blank line. In each block the first line is the
/// reference, the following lines are the verse text. An optional last line
/// starting with `#` lists topics separated by commas (`# hope, peace`). A
/// trailing `(NIV)`-style label on the reference line is the translation.
List<ImportedVerse> parseVerseText(String input) {
  final result = <ImportedVerse>[];
  for (final block
      in input.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'))) {
    final lines = block
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 2) continue;
    var topics = <String>[];
    if (lines.last.startsWith('#') && lines.length >= 3) {
      topics = lines
          .removeLast()
          .substring(1)
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    var reference = lines.first;
    String? translation;
    final m = RegExp(r'^(.*?)\s*\(([^)]+)\)$').firstMatch(reference);
    if (m != null) {
      reference = m.group(1)!;
      translation = m.group(2);
    }
    result.add(
      ImportedVerse(
        reference: reference,
        text: lines.skip(1).join(' '),
        translation: translation,
        topics: topics,
      ),
    );
  }
  return result;
}

/// Parses a JSON array of
/// `{"reference","text","translation"?,"topics"?:[..],"favourite"?}`.
/// Throws [FormatException] on a malformed document.
List<ImportedVerse> parseVerseJson(String input) {
  final decoded = jsonDecode(input);
  final list = decoded is Map ? decoded['verses'] : decoded;
  if (list is! List) {
    throw const FormatException('Expected a JSON array of verses');
  }
  return [
    for (final item in list)
      if (item is Map && item['reference'] is String && item['text'] is String)
        ImportedVerse(
          reference: item['reference'] as String,
          text: item['text'] as String,
          translation: item['translation'] as String?,
          topics: [
            for (final t in (item['topics'] as List? ?? const [])) t.toString(),
          ],
          favourite: item['favourite'] == true,
        )
      else
        throw FormatException('Entry is missing "reference" or "text": $item'),
  ];
}
