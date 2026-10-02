import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../db/database.dart';

/// A square-cropped thumbnail of [photo], decoded at [cacheWidth] pixels.
class PhotoThumb extends ConsumerStatefulWidget {
  const PhotoThumb({super.key, required this.photo, this.cacheWidth = 300});
  final Photo photo;
  final int cacheWidth;

  @override
  ConsumerState<PhotoThumb> createState() => _PhotoThumbState();
}

class _PhotoThumbState extends ConsumerState<PhotoThumb> {
  late final Future<ImageProvider?> _image = ref
      .read(repositoryProvider)
      .photoImage(widget.photo);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider?>(
      future: _image,
      builder: (context, snap) {
        final image = snap.data;
        if (image == null) {
          return ColoredBox(
            color: Colors.black12,
            child: snap.connectionState == ConnectionState.done
                ? const Icon(Icons.broken_image)
                : null,
          );
        }
        return Image(
          image: ResizeImage.resizeIfNeeded(widget.cacheWidth, null, image),
          fit: BoxFit.cover,
        );
      },
    );
  }
}
