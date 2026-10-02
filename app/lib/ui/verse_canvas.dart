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

/// Shows [child] (a full-window [VerseCanvas]) scaled down, with text sizes
/// scaled by the same factor, so the preview matches the real screen.
class CanvasPreview extends StatelessWidget {
  const CanvasPreview({super.key, required this.child, this.height = 360});
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Center(
      child: SizedBox(
        height: height,
        child: AspectRatio(
          aspectRatio: screen.width / screen.height,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: screen.width,
              height: screen.height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Space around the editable box that holds the corner dots, so each dot has
/// a 2 * [_dotPad] square touch target.
const _dotPad = 28.0;

/// The canvas: a plain margin colour, the photo fitted inside it, and the
/// verse text box positioned by fractions so it may extend past the photo.
class VerseCanvas extends StatelessWidget {
  const VerseCanvas({
    super.key,
    required this.reference,
    required this.text,
    required this.theme,
    required this.box,
    this.photoProvider,
    this.marginColor = const Color(0xFF111111),
    this.onBoxChanged,
  });

  final String reference;
  final String text;
  final AppTheme theme;
  final BoxRect box;
  final ImageProvider? photoProvider;
  final Color marginColor;

  /// When set, the box is draggable and its four corner dots change its width.
  final ValueChanged<BoxRect>? onBoxChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final provider = photoProvider;
        final boxWidth = box.w * w;
        final textBox = _TextBox(
          reference: reference,
          text: text,
          theme: theme,
          maxHeight: h * 0.8,
        );
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(child: ColoredBox(color: marginColor)),
              if (provider != null)
                Positioned.fill(
                  child: Image(image: provider, fit: BoxFit.contain),
                ),
              if (onBoxChanged == null)
                Positioned(
                  left: box.x * w,
                  top: box.y * h,
                  width: boxWidth,
                  child: textBox,
                )
              else
                Positioned(
                  left: box.x * w - _dotPad,
                  top: box.y * h - _dotPad,
                  width: boxWidth + 2 * _dotPad,
                  child: _editable(w, h, textBox),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _editable(double w, double h, Widget textBox) {
    void resize({required bool fromLeft, required double dx}) {
      final nw = (box.w + (fromLeft ? -dx : dx) / w).clamp(kMinBoxW, kMaxBoxW);
      onBoxChanged!(
        box.copyWith(x: fromLeft ? box.x + (box.w - nw) : box.x, w: nw),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.all(_dotPad),
          // Raw pointer events, not a pan gesture: a pan waits for ~18-36 px of
          // movement before it starts and drops that distance, which made the
          // box feel slow and the dots unresponsive.
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerMove: (e) => onBoxChanged!(
              box.copyWith(
                x: (box.x + e.delta.dx / w).clamp(kMinBoxX, 1.0),
                y: (box.y + e.delta.dy / h).clamp(-0.1, 1.0),
              ),
            ),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: textBox,
            ),
          ),
        ),
        for (final corner in const [
          (left: true, top: true),
          (left: false, top: true),
          (left: true, top: false),
          (left: false, top: false),
        ])
          Positioned(
            left: corner.left ? 0 : null,
            right: corner.left ? null : 0,
            top: corner.top ? 0 : null,
            bottom: corner.top ? null : 0,
            width: 2 * _dotPad,
            height: 2 * _dotPad,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerMove: (e) =>
                  resize(fromLeft: corner.left, dx: e.delta.dx),
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.indigo, width: 3),
                  ),
                ),
              ),
            ),
          ),
      ],
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
                fontSize: theme.referenceFontSize,
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
