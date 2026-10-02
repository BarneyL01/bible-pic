import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../data/layout.dart';
import '../data/repository.dart';
import '../db/database.dart';
import '../ui/verse_canvas.dart';

const kWidgetProvider = 'VerseWidgetProvider';
const kRenderDays = 30;
const _renderSize = Size(400, 300);
const _renderPixelRatio = 2.5; // 1000 x 750 px, well inside the widget bitmap limit

enum WidgetMode { fixed, verseOfTheDay }

class WidgetConfig {
  const WidgetConfig({
    this.mode = WidgetMode.verseOfTheDay,
    this.fixedVerseId,
    this.fixedPhotoId,
  });
  final WidgetMode mode;
  final String? fixedVerseId;
  final String? fixedPhotoId;

  static Future<WidgetConfig> load() async {
    final mode = await HomeWidget.getWidgetData<String>('mode');
    return WidgetConfig(
      mode: mode == 'fixed' ? WidgetMode.fixed : WidgetMode.verseOfTheDay,
      fixedVerseId: await HomeWidget.getWidgetData<String>('cfg_verse'),
      fixedPhotoId: await HomeWidget.getWidgetData<String>('cfg_photo'),
    );
  }

  Future<void> save() async {
    await HomeWidget.saveWidgetData<String>(
        'mode', mode == WidgetMode.fixed ? 'fixed' : 'votd');
    await HomeWidget.saveWidgetData<String>('cfg_verse', fixedVerseId);
    await HomeWidget.saveWidgetData<String>('cfg_photo', fixedPhotoId);
  }
}

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Verse of the day: random choice seeded by the date, so it is stable all
/// day and changes at midnight. Verses are ordered by id first so the choice
/// does not depend on database row order.
Verse verseOfTheDay(List<Verse> verses, DateTime day) {
  final sorted = [...verses]..sort((a, b) => a.id.compareTo(b.id));
  return sorted[Random(_seed(day)).nextInt(sorted.length)];
}

int _seed(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

class WidgetSync {
  WidgetSync(this.repo);
  final Repository repo;
  bool _running = false;
  bool _again = false;

  /// Renders the images the native provider shows. Safe to call often;
  /// overlapping calls collapse into one follow-up run.
  Future<void> sync(BuildContext context) async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        if (!context.mounted) return;
        await _run(context);
      } while (_again);
    } finally {
      _running = false;
    }
  }

  Future<void> _run(BuildContext context) async {
    final config = await WidgetConfig.load();
    final verses = await repo.allVerses();
    await config.save(); // writes the 'mode' key the native provider reads
    final today = DateTime.now();

    // Drop images for days that have passed.
    for (var i = 1; i <= 3; i++) {
      final old = dateKey(today.subtract(Duration(days: i)));
      await HomeWidget.saveWidgetData<String>('img_$old', null);
      await HomeWidget.saveWidgetData<String>('verse_$old', null);
    }

    if (verses.isEmpty) {
      await HomeWidget.saveWidgetData<String>('img_fixed', null);
      await HomeWidget.saveWidgetData<String>('verse_fixed', null);
    } else if (config.mode == WidgetMode.fixed) {
      final verse = verses.where((v) => v.id == config.fixedVerseId).firstOrNull ??
          verseOfTheDay(verses, today);
      Photo? photo;
      if (config.fixedPhotoId != null) {
        photo = await repo.photoById(config.fixedPhotoId!);
      }
      photo ??= await repo.pairPhoto(verse, random: Random(_seed(today)));
      if (!context.mounted) return;
      await _render(context, verse, photo, 'img_fixed');
      await HomeWidget.saveWidgetData<String>('verse_fixed', verse.id);
    } else {
      for (var i = 0; i < kRenderDays; i++) {
        final day = DateTime(today.year, today.month, today.day + i);
        final verse = verseOfTheDay(verses, day);
        final photo = await repo.pairPhoto(verse, random: Random(_seed(day) + 1));
        if (!context.mounted) return;
        await _render(context, verse, photo, 'img_${dateKey(day)}');
        await HomeWidget.saveWidgetData<String>('verse_${dateKey(day)}', verse.id);
      }
    }
    await HomeWidget.updateWidget(androidName: kWidgetProvider);
  }

  Future<void> _render(
      BuildContext context, Verse verse, Photo? photo, String key) async {
    final theme = await repo.resolveTheme(verse);
    ImageProvider? provider;
    if (photo != null) {
      final File file = await repo.photoFile(photo);
      provider = ResizeImage.resizeIfNeeded(1000, null, FileImage(file));
      if (!context.mounted) return;
      await precacheImage(provider, context);
    }
    await HomeWidget.renderFlutterWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: SizedBox(
            width: _renderSize.width,
            height: _renderSize.height,
            child: VerseCanvas(
              reference: verse.translation == null
                  ? verse.reference
                  : '${verse.reference} (${verse.translation})',
              text: verse.body,
              theme: theme,
              box: effectiveBox(verse, photo),
              photoProvider: provider,
            ),
          ),
        ),
      ),
      key: key,
      logicalSize: _renderSize,
      pixelRatio: _renderPixelRatio,
    );
  }
}
