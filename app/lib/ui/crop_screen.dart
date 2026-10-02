import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Full-screen cropper. The whole window is the crop frame, so the result has
/// the screen's aspect ratio. Pinch to zoom, drag to pan. Pops the cropped
/// image bytes, the original bytes for "Use whole photo", or null on cancel.
class CropScreen extends StatefulWidget {
  const CropScreen({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  static const _outputWidth = 1080.0;
  final _frameKey = GlobalKey();
  bool _busy = false;

  Future<void> _crop() async {
    setState(() => _busy = true);
    try {
      final boundary = _frameKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(
          pixelRatio: _outputWidth / boundary.size.width);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      Navigator.pop(context, data!.buffer.asUint8List());
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Crop failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            key: _frameKey,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 8,
              child: SizedBox.expand(
                child: Image.memory(widget.bytes, fit: BoxFit.cover),
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
                          'Pinch to zoom and drag to choose what fits the screen.',
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
                                backgroundColor: Colors.white),
                            onPressed:
                                _busy ? null : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white),
                            onPressed: _busy
                                ? null
                                : () => Navigator.pop(context, widget.bytes),
                            child: const Text('Whole photo'),
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
