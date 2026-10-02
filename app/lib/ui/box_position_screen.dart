import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../db/database.dart';
import 'verse_canvas.dart';

/// Full-screen editor for the text box. The canvas fills the window, so a
/// position set here is the position shown in the viewer. Pops the new
/// [BoxRect], or null on cancel.
class BoxPositionScreen extends StatefulWidget {
  const BoxPositionScreen({
    super.key,
    required this.reference,
    required this.text,
    required this.theme,
    required this.initial,
    this.photoProvider,
  });

  final String reference;
  final String text;
  final AppTheme theme;
  final BoxRect initial;
  final ImageProvider? photoProvider;

  @override
  State<BoxPositionScreen> createState() => _BoxPositionScreenState();
}

class _BoxPositionScreenState extends State<BoxPositionScreen> {
  late BoxRect _box = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          VerseCanvas(
            reference: widget.reference,
            text: widget.text,
            theme: widget.theme,
            box: _box,
            photoProvider: widget.photoProvider,
            onBoxChanged: (b) => setState(() => _box = b),
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
                          'Drag the box to move it. Drag a corner dot to change its width.',
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
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, _box),
                            child: const Text('Done'),
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
