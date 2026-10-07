import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/providers.dart';
import '../data/repository.dart';
import '../db/database.dart';
import 'box_position_screen.dart';
import 'crop_screen.dart';
import 'photo_thumb.dart';
import 'topic_picker.dart';
import 'verse_canvas.dart';

class PhotoLibraryScreen extends ConsumerStatefulWidget {
  const PhotoLibraryScreen({super.key});

  @override
  ConsumerState<PhotoLibraryScreen> createState() => _PhotoLibraryScreenState();
}

class _PhotoLibraryScreenState extends ConsumerState<PhotoLibraryScreen> {
  bool _busy = false;
  bool _selecting = false;
  final _selected = <String>{};

  void _say(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _upload() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;
    setState(() => _busy = true);
    final repo = ref.read(repositoryProvider);
    var failed = 0;
    for (final x in picked) {
      try {
        final prepared = await repo.shrinkImage(await x.readAsBytes());
        if (!mounted) return;
        final cropped = await Navigator.of(context).push<Uint8List>(
          MaterialPageRoute(builder: (_) => CropScreen(bytes: prepared)),
        );
        if (cropped == null) continue; // cancelled: skip this photo
        await repo.addPhoto(cropped);
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (failed > 0) _say('$failed photo(s) could not be read.');
  }

  // ---------- selection ----------

  void _startSelecting([String? firstId]) => setState(() {
    _selecting = true;
    if (firstId != null) _selected.add(firstId);
  });

  void _stopSelecting() => setState(() {
    _selecting = false;
    _selected.clear();
  });

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  List<Photo> _selectedPhotos(List<Photo> all) =>
      all.where((p) => _selected.contains(p.id)).toList();

  Future<void> _deleteSelected(List<Photo> all) async {
    final photos = _selectedPhotos(all);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          photos.length == 1
              ? 'Delete 1 photo?'
              : 'Delete ${photos.length} photos?',
        ),
        content: const Text(
          'Verses pinned to them fall back to automatic pairing.',
        ),
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
    if (ok != true || !mounted) return;
    await ref.read(repositoryProvider).deletePhotos(photos);
    if (mounted) _stopSelecting();
  }

  Future<void> _topicsForSelected(List<Photo> all) async {
    final photos = _selectedPhotos(all);
    final topics = ref.read(topicsProvider).value ?? const <Topic>[];
    final links = ref.read(photoTopicsProvider).value ?? const <PhotoTopic>[];
    final ids = photos.map((p) => p.id).toSet();
    // For each topic: true when every selected photo has it, false when none
    // do, null when only some do.
    final initial = <String, bool?>{
      for (final t in topics)
        t.id: () {
          final n = links
              .where((l) => l.topicId == t.id && ids.contains(l.photoId))
              .length;
          return n == photos.length ? true : (n == 0 ? false : null);
        }(),
    };
    final result = await showDialog<Map<String, bool?>>(
      context: context,
      builder: (_) =>
          _TopicsDialog(count: photos.length, topics: topics, initial: initial),
    );
    if (result == null || !mounted) return;
    final add = {
      for (final e in result.entries)
        if (e.value == true && initial[e.key] != true) e.key,
    };
    final remove = {
      for (final e in result.entries)
        if (e.value == false && initial[e.key] != false) e.key,
    };
    if (add.isEmpty && remove.isEmpty) return;
    await ref
        .read(repositoryProvider)
        .applyTopicsToPhotos(ids.toList(), add: add, remove: remove);
    if (!mounted) return;
    _say('Topics updated on ${photos.length} photo(s).');
    _stopSelecting();
  }

  Future<void> _themeForSelected(List<Photo> all) async {
    final photos = _selectedPhotos(all);
    final themes = ref.read(themesProvider).value ?? const <AppTheme>[];
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(
          photos.length == 1
              ? 'Theme for 1 photo'
              : 'Theme for ${photos.length} photos',
        ),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('No theme (use topic or default)'),
          ),
          for (final t in themes)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, t.id),
              child: Text(t.name),
            ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    await ref
        .read(repositoryProvider)
        .setPhotosTheme(
          photos.map((p) => p.id).toList(),
          choice.isEmpty ? null : choice,
        );
    if (!mounted) return;
    _say(
      choice.isEmpty
          ? 'Theme cleared on ${photos.length} photo(s).'
          : 'Theme set on ${photos.length} photo(s).',
    );
    _stopSelecting();
  }

  PreferredSizeWidget _appBar(List<Photo> photos) {
    if (!_selecting) {
      return AppBar(
        title: const Text('Photo library'),
        actions: [
          if (photos.isNotEmpty)
            IconButton(
              tooltip: 'Select photos',
              icon: const Icon(Icons.checklist),
              onPressed: _startSelecting,
            ),
        ],
      );
    }
    final none = _selected.isEmpty;
    return AppBar(
      leading: IconButton(
        tooltip: 'Cancel selection',
        icon: const Icon(Icons.close),
        onPressed: _stopSelecting,
      ),
      title: Text('${_selected.length} selected'),
      actions: [
        IconButton(
          tooltip: 'Select all',
          icon: const Icon(Icons.select_all),
          onPressed: () => setState(() {
            _selected
              ..clear()
              ..addAll(photos.map((p) => p.id));
          }),
        ),
        IconButton(
          tooltip: 'Set topics',
          icon: const Icon(Icons.label),
          onPressed: none ? null : () => _topicsForSelected(photos),
        ),
        IconButton(
          tooltip: 'Set theme',
          icon: const Icon(Icons.palette),
          onPressed: none ? null : () => _themeForSelected(photos),
        ),
        IconButton(
          tooltip: 'Delete selected',
          icon: const Icon(Icons.delete),
          onPressed: none ? null : () => _deleteSelected(photos),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(photosProvider).value ?? const <Photo>[];
    return Scaffold(
      appBar: _appBar(photos),
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton(
              tooltip: 'Add photos',
              onPressed: _busy ? null : _upload,
              child: _busy
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.add_photo_alternate),
            ),
      body: photos.isEmpty
          ? const Center(
              child: Text('No photos yet. Tap the button to upload.'),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: photos.length,
              itemBuilder: (context, i) {
                final p = photos[i];
                final selected = _selected.contains(p.id);
                return GestureDetector(
                  onTap: () => _selecting
                      ? _toggle(p.id)
                      : Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PhotoDetailScreen(photoId: p.id),
                          ),
                        ),
                  onLongPress: _selecting ? null : () => _startSelecting(p.id),
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: 'Photo ${i + 1}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PhotoThumb(key: ValueKey(p.id), photo: p),
                        if (p.themeId != null)
                          const Positioned(
                            left: 4,
                            bottom: 4,
                            child: Icon(
                              Icons.palette,
                              size: 18,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 4)],
                            ),
                          ),
                        if (selected)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 4,
                              ),
                            ),
                          ),
                        if (_selecting)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white,
                              shadows: const [Shadow(blurRadius: 4)],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Topics for the selected photos: ticked when every selected photo has the
/// topic, empty when none do, dashed when only some do. Tapping sets all or none.
class _TopicsDialog extends StatefulWidget {
  const _TopicsDialog({
    required this.count,
    required this.topics,
    required this.initial,
  });
  final int count;
  final List<Topic> topics;
  final Map<String, bool?> initial;

  @override
  State<_TopicsDialog> createState() => _TopicsDialogState();
}

class _TopicsDialogState extends State<_TopicsDialog> {
  late final Map<String, bool?> _state = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.count == 1
            ? 'Topics for 1 photo'
            : 'Topics for ${widget.count} photos',
      ),
      content: widget.topics.isEmpty
          ? const Text('No topics yet. Add one under Topics first.')
          : SizedBox(
              width: 320,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final t in widget.topics)
                    CheckboxListTile(
                      tristate: true,
                      title: Text(t.name),
                      value: _state[t.id],
                      onChanged: (_) => setState(
                        () =>
                            _state[t.id] = _state[t.id] == true ? false : true,
                      ),
                    ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.topics.isNotEmpty)
          FilledButton(
            onPressed: () => Navigator.pop(context, _state),
            child: const Text('Apply'),
          ),
      ],
    );
  }
}

/// Assign topics and set the default text box position for one photo.
class PhotoDetailScreen extends ConsumerStatefulWidget {
  const PhotoDetailScreen({super.key, required this.photoId});
  final String photoId;

  @override
  ConsumerState<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends ConsumerState<PhotoDetailScreen> {
  Photo? _photo;
  ImageProvider? _image;
  AppTheme? _theme;
  String? _themeId;
  Set<String> _topicIds = {};
  BoxRect _box = const BoxRect(0.1, 0.55, 0.8);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(repositoryProvider);
    final p = await repo.photoById(widget.photoId);
    if (p == null) return;
    _photo = p;
    _image = await repo.photoImage(p);
    _box = BoxRect(p.boxX, p.boxY, p.boxW);
    _topicIds = (await repo.topicIdsForPhoto(p.id)).toSet();
    _theme = await repo.defaultTheme();
    _themeId = p.themeId;
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final repo = ref.read(repositoryProvider);
    await repo.savePhoto(
      _photo!.copyWith(
        boxX: _box.x,
        boxY: _box.y,
        boxW: _box.w,
        themeId: Value(_themeId),
      ),
    );
    await repo.setPhotoTopics(_photo!.id, _topicIds.toList());
    if (mounted) Navigator.of(context).pop();
  }

  /// The theme this photo will give a verse: its own, else the default.
  AppTheme _chosenTheme(List<AppTheme> themes) =>
      themes.where((t) => t.id == _themeId).firstOrNull ?? _theme!;

  static const _sampleReference = 'John 3:16';
  static const _sampleText =
      'For God so loved the world, that he gave his only '
      'Son, that whoever believes in him should not perish '
      'but have eternal life.';

  Future<void> _position() async {
    final b = await Navigator.of(context).push<BoxRect>(
      MaterialPageRoute(
        builder: (_) => BoxPositionScreen(
          reference: _sampleReference,
          text: _sampleText,
          theme: _chosenTheme(ref.read(themesProvider).value ?? const []),
          initial: _box,
          photoProvider: _image,
        ),
      ),
    );
    if (b != null) setState(() => _box = b);
  }

  Future<void> _recrop() async {
    final repo = ref.read(repositoryProvider);
    final bytes = await repo.photoBytes(_photo!);
    if (bytes == null || !mounted) return;
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => CropScreen(bytes: bytes)),
    );
    if (cropped == null) return;
    await repo.replacePhotoImage(_photo!, cropped);
    final fresh = await repo.photoImage(_photo!);
    if (mounted) setState(() => _image = fresh);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this photo?'),
        content: const Text(
          'Verses pinned to it fall back to automatic pairing.',
        ),
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
    await ref.read(repositoryProvider).deletePhoto(_photo!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final themes = ref.watch(themesProvider).value ?? const <AppTheme>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo'),
        actions: [
          IconButton(
            tooltip: 'Delete photo',
            onPressed: _delete,
            icon: const Icon(Icons.delete),
          ),
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: _photo == null || _theme == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TopicSelector(
                  selected: _topicIds,
                  hint: 'verses in these topics prefer this photo',
                  onChanged: (ids) => setState(() => _topicIds = ids),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: themes.any((t) => t.id == _themeId)
                      ? _themeId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Theme for verses on this photo',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No theme (use topic or default)'),
                    ),
                    for (final t in themes)
                      DropdownMenuItem(value: t.id, child: Text(t.name)),
                  ],
                  onChanged: (v) => setState(() => _themeId = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _recrop,
                        icon: const Icon(Icons.crop),
                        label: const Text('Crop to screen'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _position,
                        icon: const Icon(Icons.open_with),
                        label: const Text('Move text box'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Default text box position for this photo. Verses '
                  'can override it in the verse editor.',
                ),
                const SizedBox(height: 8),
                CanvasPreview(
                  child: VerseCanvas(
                    reference: _sampleReference,
                    text: _sampleText,
                    theme: _chosenTheme(themes),
                    box: _box,
                    photoProvider: _image,
                  ),
                ),
              ],
            ),
    );
  }
}
