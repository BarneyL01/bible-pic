import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../db/database.dart';

TextAlign alignmentFromName(String name) => switch (name) {
      'left' => TextAlign.left,
      'right' => TextAlign.right,
      _ => TextAlign.center,
    };

const kMinBoxW = 0.2;
const kMaxBoxW = 1.2;
const kMinBoxX = -0.5;

/// The canvas: a plain margin colour, the photo fitted inside it, and the
/// verse text box positioned by fractions so it may extend past the photo.
class VerseCanvas extends StatelessWidget {
  const VerseCanvas({
    super.key,
    required this.reference,
    required this.text,
    required this.theme,
    required this.box,
    this.photoFile,
    this.photoProvider,
    this.marginColor = const Color(0xFF111111),
    this.onBoxChanged,
  });

  final String reference;
  final String text;
  final AppTheme theme;
  final BoxRect box;
  final File? photoFile;
  final ImageProvider? photoProvider;
  final Color marginColor;

  /// When set, the box can be dragged and its width changed.
  final ValueChanged<BoxRect>? onBoxChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final provider =
          photoProvider ?? (photoFile != null ? FileImage(photoFile!) : null);
      final boxWidth = box.w * w;
      return ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: ColoredBox(color: marginColor)),
            if (provider != null)
              Positioned.fill(
                child: Image(image: provider, fit: BoxFit.contain),
              ),
            Positioned(
              left: box.x * w,
              top: box.y * h,
              width: boxWidth,
              child: _TextBox(
                reference: reference,
                text: text,
                theme: theme,
                maxHeight: h * 0.8,
              ),
            ),
            if (onBoxChanged != null) ..._handles(w, h),
          ],
        ),
      );
    });
  }

  List<Widget> _handles(double w, double h) {
    final left = box.x * w;
    final width = box.w * w;
    final top = box.y * h;
    return [
      // Drag anywhere on the box to move it.
      Positioned(
        left: left,
        top: top,
        width: width,
        height: h * 0.3,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (d) => onBoxChanged!(box.copyWith(
            x: (box.x + d.delta.dx / w).clamp(kMinBoxX, 1.0),
            y: (box.y + d.delta.dy / h).clamp(-0.1, 0.95),
          )),
        ),
      ),
      _edgeHandle(left - 14, top, h, (dx) {
        final nw = (box.w - dx / w).clamp(kMinBoxW, kMaxBoxW);
        onBoxChanged!(box.copyWith(x: box.x + (box.w - nw), w: nw));
      }),
      _edgeHandle(left + width - 14, top, h, (dx) {
        onBoxChanged!(box.copyWith(w: (box.w + dx / w).clamp(kMinBoxW, kMaxBoxW)));
      }),
    ];
  }

  Widget _edgeHandle(
      double left, double top, double h, void Function(double dx) onDrag) {
    return Positioned(
      left: left,
      top: top,
      width: 28,
      height: h * 0.15,
      child: GestureDetector(
        onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
        child: Center(
          child: Container(
            width: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black54),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextBox extends StatelessWidget {
  const _TextBox({
    required this.reference,
    required this.text,
    required this.theme,
    required this.maxHeight,
  });

  final String reference;
  final String text;
  final AppTheme theme;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final color = Color(theme.textColor);
    final align = alignmentFromName(theme.alignment);
    final crossAxis = switch (align) {
      TextAlign.left => CrossAxisAlignment.start,
      TextAlign.right => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.center,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(theme.panelColor).withValues(alpha: theme.panelOpacity),
        borderRadius: BorderRadius.circular(theme.cornerRadius),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxis,
          children: [
            Flexible(
              child: AutoSizeText(
                text,
                textAlign: align,
                minFontSize: 8,
                style: TextStyle(
                  fontFamily: theme.font,
                  fontSize: theme.fontSize,
                  color: color,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              reference,
              textAlign: align,
              style: TextStyle(
                fontFamily: theme.font,
                fontSize: theme.fontSize * 0.6,
                color: color.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
