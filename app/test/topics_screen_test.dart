import 'package:bible_pic/data/providers.dart';
import 'package:bible_pic/data/repository.dart';
import 'package:bible_pic/ui/topics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<void> pumpTopics(WidgetTester tester, Repository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: TopicsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(quietDriftWarnings);

  late Repository repo;
  late String hope, grief;

  setUp(() async {
    repo = makeRepo();
    hope = await repo.topicIdForName('hope');
    grief = await repo.topicIdForName('grief');
    await repo.topicIdForName('peace');
    await repo.saveVerse(verse('a'), [hope, grief]);
    await repo.saveVerse(verse('b'), [hope]);
    await repo.savePhoto(photo('p'));
    await repo.setPhotoTopics('p', [
      grief,
    ]); // grief has a photo; hope and peace do not
  });

  testWidgets('rows show verse and photo counts', (tester) async {
    await pumpTopics(tester, repo);
    expect(find.text('2 verses · no photo'), findsOneWidget); // hope
    expect(find.text('1 verse · 1 photo'), findsOneWidget); // grief
    expect(find.text('0 verses · no photo'), findsOneWidget); // peace
    await finish(tester);
  });

  testWidgets('the theme name shows only when the topic has a theme', (
    tester,
  ) async {
    await pumpTopics(tester, repo);
    expect(find.byIcon(Icons.palette_outlined), findsNothing);
    await repo.setTopicTheme(hope, 'default-theme');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('A to Z is the default and groups under letter headings', (
    tester,
  ) async {
    await pumpTopics(tester, repo);
    final names = ['grief', 'hope', 'peace'];
    final ys = [for (final n in names) tester.getTopLeft(find.text(n)).dy];
    expect(ys, [...ys]..sort());
    // Headings (and the index) exist for G, H and P.
    for (final letter in ['G', 'H', 'P']) {
      expect(find.text(letter), findsNWidgets(2));
    }
    await finish(tester);
  });

  testWidgets('searching filters by name, ignoring case, and drops headings', (
    tester,
  ) async {
    await pumpTopics(tester, repo);
    await tester.enterText(find.byType(TextField), 'GRIE');
    await tester.pumpAndSettle();
    expect(find.text('grief'), findsOneWidget);
    expect(find.text('hope'), findsNothing);
    expect(find.text('G'), findsNothing); // no headings while searching
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No topics match “zzz”'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('Most verses puts the topic with the most verses first', (
    tester,
  ) async {
    await pumpTopics(tester, repo);
    await tester.tap(find.text('Most verses'));
    await tester.pumpAndSettle();
    final hopeY = tester.getTopLeft(find.text('hope')).dy;
    expect(hopeY, lessThan(tester.getTopLeft(find.text('grief')).dy));
    expect(hopeY, lessThan(tester.getTopLeft(find.text('peace')).dy));
    expect(find.text('H'), findsNothing); // no headings in this order
    await finish(tester);
  });

  testWidgets('No photo shows its count and hides topics that have a photo', (
    tester,
  ) async {
    await pumpTopics(tester, repo);
    expect(find.text('No photo · 2'), findsOneWidget);
    await tester.tap(find.text('No photo · 2'));
    await tester.pumpAndSettle();
    expect(find.text('grief'), findsNothing); // has a photo
    expect(find.text('hope'), findsOneWidget);
    expect(find.text('peace'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('the add button is labelled New topic', (tester) async {
    await pumpTopics(tester, repo);
    expect(
      find.widgetWithText(FloatingActionButton, 'New topic'),
      findsOneWidget,
    );
    await finish(tester);
  });

  testWidgets('with no topics, it says so', (tester) async {
    await pumpTopics(tester, makeRepo());
    expect(find.textContaining('No topics yet'), findsOneWidget);
    await finish(tester);
  });

  group('selecting topics', () {
    testWidgets('long press selects; tapping toggles; the add button hides', (
      tester,
    ) async {
      await pumpTopics(tester, repo);
      await tester.longPress(find.text('hope'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.tap(find.text('peace'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
      await tester.tap(find.text('peace'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      await tester.tap(find.byTooltip('Cancel selection'));
      await tester.pumpAndSettle();
      expect(find.text('Topics'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      await finish(tester);
    });

    testWidgets('Merge needs two topics', (tester) async {
      await pumpTopics(tester, repo);
      await tester.longPress(find.text('hope'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Merge'))
            .enabled,
        isFalse,
      );
      await tester.tap(find.text('grief'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Merge'))
            .enabled,
        isTrue,
      );
      await finish(tester);
    });

    testWidgets('merging keeps the chosen name and the union of verses', (
      tester,
    ) async {
      await pumpTopics(tester, repo);
      await tester.longPress(find.text('hope'));
      await tester.tap(find.text('grief'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Merge'));
      await tester.pumpAndSettle();
      expect(find.text('Merge 2 topics'), findsOneWidget);
      await tester.tap(find.text('hope').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
      await tester.pumpAndSettle();
      expect(find.text('grief'), findsNothing);
      expect(find.text('2 verses · 1 photo'), findsOneWidget);
      expect(find.text('Topics'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('delete asks first and keeps the verses', (tester) async {
      await pumpTopics(tester, repo);
      await tester.longPress(find.text('hope'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete selected topics'));
      await tester.pumpAndSettle();
      expect(find.text('Delete 1 topic?'), findsOneWidget);
      expect(
        find.text('Verses and photos stay; only these topic tags are removed.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('hope'), findsNothing);
      expect(
        (await tester.runAsync(() => repo.watchVerses().first))!.length,
        2,
      );
      await finish(tester);
    });
  });
}
