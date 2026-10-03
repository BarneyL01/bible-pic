import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'verse_canvas.dart';

/// Full-screen cropper. The whole window is the crop frame, so the result has
/// the screen's aspect ratio. Drag to move the photo, pinch or scroll to zoom.
/// The photo starts filling the screen. While it is larger than the screen on
/// an axis it always covers the screen on that axis; zoomed out smaller, it can
/// be placed anywhere but stays fully visible, and the space around it is the
/// canvas margin colour. Pops the cropped image bytes, the original bytes for
/// "No crop", or null on cancel.
class CropScreen extends StatefulWidget {
  const CropScreen({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  static const _outputWidth = 1080.0;
  final _frameKey = GlobalKey();
  final _controller = TransformationController();
  Size? _imageSize;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_keepInView);
    decodeImageFromList(widget.bytes).then((image) {
      if (!mounted) return;
      final size = Size(image.width.toDouble(), image.height.toDouble());
      _imageSize = size;
      _reset();
      setState(() => _imageSize = size);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_keepInView);
    _controller.dispose();
    super.dispose();
  }

  /// Fill the screen with the middle of the photo, as on opening.
  void _reset() {
    final image = _imageSize;
    if (image == null) return;
    final viewport = MediaQuery.sizeOf(context);
    final cover = _coverSize(image, viewport);
    _controller.value = Matrix4.translationValues(
      -(cover.width - viewport.width) / 2,
      -(cover.height - viewport.height) / 2,
      0,
    );
  }

  /// Keeps the photo on screen: it never leaves a gap while it is larger than
  /// the screen on an axis, and never leaves the screen while it is smaller.
  void _keepInView() {
    final image = _imageSize;
    if (image == null) return;
    final viewport = MediaQuery.sizeOf(context);
    final cover = _coverSize(image, viewport);
    final m = _controller.value;
    final scale = m.getMaxScaleOnAxis();
    double fit(double t, double photo, double view) {
      final lo = photo >= view ? view - photo : 0.0;
      final hi = photo >= view ? 0.0 : view - photo;
      return t.clamp(lo, hi);
    }

    final tx = fit(m.getTranslation().x, cover.width * scale, viewport.width);
    final ty = fit(m.getTranslation().y, cover.height * scale, viewport.height);
    if (tx != m.getTranslation().x || ty != m.getTranslation().y) {
      _controller.value = m.clone()
        ..setEntry(0, 3, tx)
        ..setEntry(1, 3, ty);
    }
  }

  /// How far the photo can be zoomed out, relative to its cover size: the
  /// whole photo visible, or at least half size for a photo that already
  /// fits the screen.
  double _minScale(Size image, Size viewport) {
    final fitW = viewport.width / image.width;
    final fitH = viewport.height / image.height;
    final contain = fitW < fitH ? fitW : fitH;
    final cover = fitW < fitH ? fitH : fitW;
    final whole = contain / cover;
    return whole < 0.5 ? whole : 0.5;
  }

  /// The photo scaled to just cover [viewport]. It is larger than the viewport
  /// along one axis, and that overflow is what the user drags across.
  Size _coverSize(Size image, Size viewport) {
    final scale =
        (viewport.width / image.width) > (viewport.height / image.height)
        ? viewport.width / image.width
        : viewport.height / image.height;
    return Size(image.width * scale, image.height * scale);
  }

  Future<void> _crop() async {
    setState(() => _busy = true);
    try {
      final boundary =
          _frameKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: _outputWidth / boundary.size.width,
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      Navigator.pop(context, data!.buffer.asUint8List());
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Crop failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final image = _imageSize;
              if (image == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final viewport = constraints.biggest;
              final cover = _coverSize(image, viewport);
              return RepaintBoundary(
                key: _frameKey,
                child: ColoredBox(
                  color: kCanvasMargin,
                  child: InteractiveViewer(
                    transformationController: _controller,
                    constrained: false,
                    // Movement is limited by _keepInView (run on every change
                    // to the transform, including the coast after a fast
                    // drag), not by the viewer.
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    minScale: _minScale(image, viewport),
                    maxScale: 8,
                    child: SizedBox(
                      width: cover.width,
                      height: cover.height,
                      child: Image.memory(widget.bytes, fit: BoxFit.fill),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Reset',
                icon: const Icon(Icons.restart_alt),
                onPressed: _busy ? null : _reset,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Drag the photo to position it. Pinch or scroll to zoom in or out.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            onPressed: _busy
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            onPressed: _busy
                                ? null
                                : () => Navigator.pop(context, widget.bytes),
                            child: const Text('No crop'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: _busy ? null : _crop,
                            child: const Text('Crop'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
