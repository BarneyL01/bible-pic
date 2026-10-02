import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/providers.dart';
import '../data/repository.dart';
import '../db/database.dart';
import 'box_position_screen.dart';
import 'crop_screen.dart';
import 'verse_canvas.dart';

class PhotoLibraryScreen extends ConsumerStatefulWidget {
  const PhotoLibraryScreen({super.key});

  @override
  ConsumerState<PhotoLibraryScreen> createState() => _PhotoLibraryScreenState();
}

class _PhotoLibraryScreenState extends ConsumerState<PhotoLibraryScreen> {
  Directory? _dir;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.read(repositoryProvider).photoDir().then((d) {
      if (mounted) setState(() => _dir = d);
    });
  }

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
            MaterialPageRoute(builder: (_) => CropScreen(bytes: prepared)));
        if (cropped == null) continue; // cancelled: skip this photo
        await repo.addPhoto(cropped);
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (failed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$failed photo(s) could not be read.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(photosProvider).value ?? const <Photo>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Photo library')),
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : _upload,
        child: _busy
            ? const CircularProgressIndicator()
            : const Icon(Icons.add_photo_alternate),
      ),
      body: photos.isEmpty || _dir == null
          ? const Center(child: Text('No photos yet. Tap the button to upload.'))
          : GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4),
              itemCount: photos.length,
              itemBuilder: (context, i) {
                final p = photos[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => PhotoDetailScreen(photoId: p.id)),
                  ),
                  child: Image.file(File('${_dir!.path}/${p.path}'),
                      fit: BoxFit.cover, cacheWidth: 300),
                );
              },
            ),
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
  File? _file;
  AppTheme? _theme;
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
    _file = await repo.photoFile(p);
    _box = BoxRect(p.boxX, p.boxY, p.boxW);
    _topicIds = (await repo.topicIdsForPhoto(p.id)).toSet();
    _theme = await repo.defaultTheme();
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final repo = ref.read(repositoryProvider);
    await repo.savePhoto(
        _photo!.copyWith(boxX: _box.x, boxY: _box.y, boxW: _box.w));
    await repo.setPhotoTopics(_photo!.id, _topicIds.toList());
    if (mounted) Navigator.of(context).pop();
  }

  static const _sampleReference = 'John 3:16';
  static const _sampleText = 'For God so loved the world, that he gave his only '
      'Son, that whoever believes in him should not perish '
      'but have eternal life.';

  Future<void> _position() async {
    final b = await Navigator.of(context).push<BoxRect>(MaterialPageRoute(
      builder: (_) => BoxPositionScreen(
        reference: _sampleReference,
        text: _sampleText,
        theme: _theme!,
        initial: _box,
        photoFile: _file,
      ),
    ));
    if (b != null) setState(() => _box = b);
  }

  Future<void> _recrop() async {
    final bytes = await _file!.readAsBytes();
    if (!mounted) return;
    final cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => CropScreen(bytes: bytes)));
    if (cropped == null) return;
    await ref.read(repositoryProvider).replacePhotoImage(_photo!, cropped);
    imageCache.clear();
    imageCache.clearLiveImages();
    if (mounted) setState(() {});
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this photo?'),
        content: const Text('Verses pinned to it fall back to automatic pairing.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(repositoryProvider).deletePhoto(_photo!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(topicsProvider).value ?? const <Topic>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo'),
        actions: [
          IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: _photo == null || _theme == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Topics'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in topics)
                      FilterChip(
                        label: Text(t.name),
                        selected: _topicIds.contains(t.id),
                        onSelected: (s) => setState(() =>
                            s ? _topicIds.add(t.id) : _topicIds.remove(t.id)),
                      ),
                  ],
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
                const Text('Default text box position for this photo. Verses '
                    'can override it in the verse editor.'),
                const SizedBox(height: 8),
                CanvasPreview(
                  child: VerseCanvas(
                    reference: _sampleReference,
                    text: _sampleText,
                    theme: _theme!,
                    box: _box,
                    photoFile: _file,
                  ),
                ),
              ],
            ),
    );
  }
}
