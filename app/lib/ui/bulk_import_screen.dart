import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bulk_parse.dart';
import '../data/providers.dart';
import '../data/repository.dart';

class BulkImportScreen extends ConsumerStatefulWidget {
  const BulkImportScreen({super.key});

  @override
  ConsumerState<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends ConsumerState<BulkImportScreen> {
  final _text = TextEditingController();

  void _say(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _import(List<ImportedVerse> items) async {
    if (items.isEmpty) {
      _say('No verses found in the input.');
      return;
    }
    final added = await ref.read(repositoryProvider).importVerses(items);
    if (!mounted) return;
    _say('Imported $added verse(s).');
    _text.clear();
  }

  Future<void> _fromText() async {
    try {
      await _import(parseVerseText(_text.text));
    } catch (e) {
      _say('Could not read the text: $e');
    }
  }

  Future<void> _fromJson() async {
    final res = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (res == null) return;
    try {
      await _import(parseVerseJson(utf8.decode(await res.readAsBytes())));
    } on FormatException catch (e) {
      _say('Invalid JSON file: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk import')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Paste verses as blocks separated by a blank line.\n'
            'Line 1 is the reference (add a translation like "(NIV)" at the end).\n'
            'The following lines are the text.\n'
            'An optional last line starting with # lists topics, e.g. "# hope, peace".',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            minLines: 8,
            maxLines: 16,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText:
                  'John 3:16 (ESV)\nFor God so loved the world…\n# love, salvation',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _fromText,
            child: const Text('Import pasted text'),
          ),
          const Divider(height: 32),
          const Text(
            'JSON file: an array of objects with "reference" and "text", and '
            'optionally "translation", "topics" (array of names) and "favourite" (true/false).',
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _fromJson,
            child: const Text('Pick a JSON file'),
          ),
        ],
      ),
    );
  }
}
