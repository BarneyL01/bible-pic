import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../data/repository.dart';
import '../db/database.dart';
import 'verse_canvas.dart';

const kFonts = ['sans-serif', 'serif', 'monospace', 'cursive'];
const kAlignments = ['left', 'center', 'right'];
const _swatches = <int>[
  0xFFFFFFFF, 0xFF000000, 0xFFFFF59D, 0xFFB3E5FC, 0xFFC8E6C9, 0xFFF8BBD0,
  0xFF3E2723, 0xFF0D47A1, 0xFF1B5E20, 0xFF4A148C,
];

class ThemesScreen extends ConsumerWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themes = ref.watch(themesProvider).value ?? const <AppTheme>[];
    final repo = ref.read(repositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Themes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const ThemeEditorScreen())),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: [
          for (final t in themes)
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(t.panelColor)
                      .withValues(alpha: t.panelOpacity.clamp(0.2, 1)),
                  borderRadius: BorderRadius.circular(t.cornerRadius.clamp(0, 20)),
                ),
                child: Text('Aa',
                    style: TextStyle(
                        color: Color(t.textColor), fontFamily: t.font)),
              ),
              title: Text(t.name),
              subtitle: t.isDefault ? const Text('Default') : null,
              trailing: t.isDefault
                  ? null
                  : TextButton(
                      onPressed: () => repo.setDefaultTheme(t.id),
                      child: const Text('Make default')),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ThemeEditorScreen(theme: t))),
            ),
        ],
      ),
    );
  }
}

class ThemeEditorScreen extends ConsumerStatefulWidget {
  const ThemeEditorScreen({super.key, this.theme});
  final AppTheme? theme;

  @override
  ConsumerState<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends ConsumerState<ThemeEditorScreen> {
  late AppTheme _t;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _t = widget.theme ??
        AppTheme(
          id: newId(),
          name: 'New theme',
          font: 'sans-serif',
          fontSize: 26,
          referenceFontSize: 16,
          textColor: 0xFFFFFFFF,
          alignment: 'center',
          panelColor: 0xFF000000,
          panelOpacity: 0.5,
          cornerRadius: 12,
          isDefault: false,
        );
    _name = TextEditingController(text: _t.name);
  }

  Future<void> _save() async {
    await ref
        .read(repositoryProvider)
        .saveTheme(_t.copyWith(name: _name.text.trim().isEmpty ? _t.name : _name.text.trim()));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(repositoryProvider).deleteTheme(_t.id);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _colors(String label, int current, ValueChanged<int> onPick) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Wrap(
            spacing: 8,
            children: [
              for (final c in _swatches)
                GestureDetector(
                  onTap: () => onPick(c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                          width: current == c ? 3 : 1,
                          color: current == c ? Colors.amber : Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
        actions: [
          if (widget.theme != null && !widget.theme!.isDefault)
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name')),
          DropdownButtonFormField<String>(
            initialValue: _t.font,
            decoration: const InputDecoration(labelText: 'Font'),
            items: [for (final f in kFonts) DropdownMenuItem(value: f, child: Text(f))],
            onChanged: (v) => setState(() => _t = _t.copyWith(font: v)),
          ),
          DropdownButtonFormField<String>(
            initialValue: _t.alignment,
            decoration: const InputDecoration(labelText: 'Alignment'),
            items: [for (final a in kAlignments) DropdownMenuItem(value: a, child: Text(a))],
            onChanged: (v) => setState(() => _t = _t.copyWith(alignment: v)),
          ),
          Text('Verse text size: ${_t.fontSize.round()}'),
          Slider(
            value: _t.fontSize.clamp(12, 60),
            min: 12,
            max: 60,
            onChanged: (v) => setState(() => _t = _t.copyWith(fontSize: v)),
          ),
          Text('Reference size: ${_t.referenceFontSize.round()}'),
          Slider(
            value: _t.referenceFontSize.clamp(8, 40),
            min: 8,
            max: 40,
            onChanged: (v) =>
                setState(() => _t = _t.copyWith(referenceFontSize: v)),
          ),
          _colors('Text colour', _t.textColor,
              (c) => setState(() => _t = _t.copyWith(textColor: c))),
          const SizedBox(height: 12),
          _colors('Panel colour', _t.panelColor,
              (c) => setState(() => _t = _t.copyWith(panelColor: c))),
          Text('Panel opacity: ${(_t.panelOpacity * 100).round()}%'),
          Slider(
            value: _t.panelOpacity,
            onChanged: (v) => setState(() => _t = _t.copyWith(panelOpacity: v)),
          ),
          Text('Corner radius: ${_t.cornerRadius.round()}'),
          Slider(
            value: _t.cornerRadius.clamp(0, 40),
            min: 0,
            max: 40,
            onChanged: (v) => setState(() => _t = _t.copyWith(cornerRadius: v)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: VerseCanvas(
              reference: 'Psalm 23:1',
              text: 'The Lord is my shepherd; I shall not want.',
              theme: _t,
              box: const BoxRect(0.1, 0.35, 0.8),
              marginColor: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }
}
