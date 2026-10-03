import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/layout.dart';
import '../data/providers.dart';
import '../data/repository.dart';
import '../db/database.dart';
import 'box_position_screen.dart';
import 'photo_thumb.dart';
import 'verse_canvas.dart';

class VerseEditorScreen extends ConsumerStatefulWidget {
  const VerseEditorScreen({super.key, this.verseId});
  final String? verseId;

  @override
  ConsumerState<VerseEditorScreen> createState() => _VerseEditorScreenState();
}

class _VerseEditorScreenState extends ConsumerState<VerseEditorScreen> {
  final _reference = TextEditingController();
  final _body = TextEditingController();
  final _translation = TextEditingController();
  late String _id;
  bool _loaded = false;
  bool _favourite = false;
  String? _pinnedPhotoId;
  String? _themeId;
  BoxRect? _override;
  Set<String> _topicIds = {};
  ImageProvider? _previewImage;
  Photo? _previewPhoto;

  @override
  void initState() {
    super.initState();
    _id = widget.verseId ?? newId();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(repositoryProvider);
    if (widget.verseId != null) {
      final v = await repo.verseById(widget.verseId!);
      if (v != null) {
        _reference.text = v.reference;
        _body.text = v.body;
        _translation.text = v.translation ?? '';
        _favourite = v.favourite;
        _pinnedPhotoId = v.pinnedPhotoId;
        _themeId = v.themeId;
        if (v.boxX != null && v.boxY != null && v.boxW != null) {
          _override = BoxRect(v.boxX!, v.boxY!, v.boxW!);
        }
        _topicIds = (await repo.topicIdsForVerse(v.id)).toSet();
      }
    }
    await _refreshPreviewPhoto();
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _refreshPreviewPhoto() async {
    final repo = ref.read(repositoryProvider);
    Photo? photo;
    if (_pinnedPhotoId != null) photo = await repo.photoById(_pinnedPhotoId!);
    photo ??= (await repo.allPhotos()).firstOrNull;
    _previewPhoto = photo;
    _previewImage = photo == null ? null : await repo.photoImage(photo);
    if (mounted) setState(() {});
  }

  Verse _build() => Verse(
    id: _id,
    reference: _reference.text.trim(),
    body: _body.text.trim(),
    translation: _translation.text.trim().isEmpty
        ? null
        : _translation.text.trim(),
    pinnedPhotoId: _pinnedPhotoId,
    themeId: _themeId,
    boxX: _override?.x,
    boxY: _override?.y,
    boxW: _override?.w,
    favourite: _favourite,
  );

  Future<void> _save() async {
    if (_reference.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reference and text are required.')),
      );
      return;
    }
    try {
      await ref
          .read(repositoryProvider)
          .saveVerse(_build(), _topicIds.toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this verse?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(repositoryProvider).deleteVerse(_id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickPhoto() async {
    final photos = ref.read(photosProvider).value ?? const <Photo>[];
    if (!mounted) return;
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Pinned photo'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('None (use pairing)'),
          ),
          SizedBox(
            width: 300,
            height: 300,
            child: GridView.count(
              crossAxisCount: 3,
              children: [
                for (final p in photos)
                  GestureDetector(
                    onTap: () => Navigator.pop(context, p.id),
                    child: PhotoThumb(
                      key: ValueKey(p.id),
                      photo: p,
                      cacheWidth: 200,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null) return;
    _pinnedPhotoId = picked.isEmpty ? null : picked;
    await _refreshPreviewPhoto();
  }

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(topicsProvider).value ?? const <Topic>[];
    final themes = ref.watch(themesProvider).value ?? const <AppTheme>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.verseId == null ? 'New verse' : 'Edit verse'),
        actions: [
          if (widget.verseId != null)
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _reference,
                  decoration: const InputDecoration(
                    labelText: 'Reference',
                    hintText: 'John 3:16',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                TextField(
                  controller: _body,
                  decoration: const InputDecoration(labelText: 'Text'),
                  maxLines: null,
                  onChanged: (_) => setState(() {}),
                ),
                TextField(
                  controller: _translation,
                  decoration: const InputDecoration(
                    labelText: 'Translation (optional)',
                  ),
                ),
                SwitchListTile(
                  title: const Text('Favourite'),
                  value: _favourite,
                  onChanged: (v) => setState(() => _favourite = v),
                ),
                const SizedBox(height: 8),
                Text('Topics', style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in topics)
                      FilterChip(
                        label: Text(t.name),
                        selected: _topicIds.contains(t.id),
                        onSelected: (s) => setState(
                          () =>
                              s ? _topicIds.add(t.id) : _topicIds.remove(t.id),
                        ),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: const Text('New topic'),
                      onPressed: _newTopic,
                    ),
                  ],
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pinned photo'),
                  subtitle: Text(
                    _pinnedPhotoId == null
                        ? 'None — paired automatically'
                        : 'Pinned',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickPhoto,
                ),
                DropdownButtonFormField<String?>(
                  initialValue: _themeId,
                  decoration: const InputDecoration(labelText: 'Theme'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Use topic / default theme'),
                    ),
                    for (final t in themes)
                      DropdownMenuItem(value: t.id, child: Text(t.name)),
                  ],
                  onChanged: (v) => setState(() => _themeId = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Text box position',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    if (_override != null)
                      TextButton(
                        onPressed: () => setState(() => _override = null),
                        child: const Text('Use photo default'),
                      ),
                  ],
                ),
                Text(
                  _override == null
                      ? 'Using the photo default.'
                      : 'Custom position for this verse, on every photo.',
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _position,
                  icon: const Icon(Icons.open_with),
                  label: const Text('Move or resize text box'),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _position,
                  child: AbsorbPointer(child: CanvasPreview(child: _preview())),
                ),
              ],
            ),
    );
  }

  Widget _preview() {
    final verse = _build();
    return FutureBuilder<AppTheme>(
      future: ref
          .read(repositoryProvider)
          .resolveThemeFor(
            verse,
            topicIds: _topicIds.toList(),
            photo: _previewPhoto,
          ),
      builder: (context, snap) {
        final theme = snap.data;
        if (theme == null) return const SizedBox.shrink();
        return VerseCanvas(
          reference: verse.reference.isEmpty ? 'Reference' : verse.reference,
          text: verse.body.isEmpty ? 'Verse text appears here.' : verse.body,
          theme: theme,
          box: effectiveBox(verse, _previewPhoto),
          photoProvider: _previewImage,
        );
      },
    );
  }

  Future<void> _position() async {
    final verse = _build();
    final theme = await ref
        .read(repositoryProvider)
        .resolveThemeFor(
          verse,
          topicIds: _topicIds.toList(),
          photo: _previewPhoto,
        );
    if (!mounted) return;
    final b = await Navigator.of(context).push<BoxRect>(
      MaterialPageRoute(
        builder: (_) => BoxPositionScreen(
          reference: verse.reference.isEmpty ? 'Reference' : verse.reference,
          text: verse.body.isEmpty ? 'Verse text appears here.' : verse.body,
          theme: theme,
          initial: effectiveBox(verse, _previewPhoto),
          photoProvider: _previewImage,
        ),
      ),
    );
    if (b != null) setState(() => _override = b);
  }

  Future<void> _newTopic() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New topic'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    final id = await ref.read(repositoryProvider).topicIdForName(name);
    setState(() => _topicIds.add(id));
  }
}
