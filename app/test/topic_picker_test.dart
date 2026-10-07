import 'package:bible_pic/data/providers.dart';
import 'package:bible_pic/data/repository.dart';
import 'package:bible_pic/ui/letter_index.dart';
import 'package:bible_pic/ui/topic_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

class PickerHarness {
  Set<String>? result;
  bool closed = false;
}

Future<PickerHarness> openPicker(
  WidgetTester tester,
  Repository repo, {
  Set<String> selected = const {},
  String? subject,
}) async {
  final h = PickerHarness();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                h.result = await showTopicPicker(
                  context,
                  selected: selected,
                  subject: subject,
                );
                h.closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return h;
}

void main() {
  setUpAll(quietDriftWarnings);

  late Repository repo;
  late String peace, hope, love;

  setUp(() async {
    repo = makeRepo();
    peace = await repo.topicIdForName('peace');
    hope = await repo.topicIdForName('hope');
    love = await repo.topicIdForName('love');
    await repo.saveVerse(verse('a'), [hope, love]);
    await repo.saveVerse(verse('b'), [hope]);
  });

  testWidgets('lists every topic with its verse count, under letter headings', (
    tester,
  ) async {
    await openPicker(tester, repo, subject: 'Psalm 1:1');
    expect(find.text('hope'), findsOneWidget);
    expect(find.text('2 verses'), findsOneWidget); // hope
    expect(find.text('1 verse'), findsOneWidget); // love
    expect(find.text('0 verses'), findsOneWidget); // peace
    expect(
      find.text('H'),
      findsNWidgets(2),
    ); // the heading and the letter index
    expect(find.text('0 selected for Psalm 1:1'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('typing filters the list and counts the matches', (tester) async {
    await openPicker(tester, repo);
    await tester.enterText(find.byType(TextField), 'pea');
    await tester.pumpAndSettle();
    expect(find.text('1 match'), findsOneWidget);
    expect(find.textContaining('hope', findRichText: true), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == 'peace',
      ),
      findsOneWidget,
    );
    await finish(tester);
  });

  testWidgets('an exact name hides the create button, a new name shows it', (
    tester,
  ) async {
    await openPicker(tester, repo);
    await tester.enterText(find.byType(TextField), 'PEACE'); // ignoring case
    await tester.pumpAndSettle();
    expect(find.textContaining('Create topic'), findsNothing);
    await tester.enterText(find.byType(TextField), 'lament');
    await tester.pumpAndSettle();
    expect(find.text('Create topic “lament” and add it'), findsOneWidget);
    await finish(tester);
  });

  testWidgets(
    'the create button makes the topic, selects it and clears search',
    (tester) async {
      final h = await openPicker(tester, repo);
      await tester.enterText(find.byType(TextField), 'lament');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create topic “lament” and add it'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'lament'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      final created = (await repo.db.select(repo.db.topics).get()).firstWhere(
        (t) => t.name == 'lament', // the case it was typed in
      );
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(h.result, {created.id});
      await finish(tester);
    },
  );

  testWidgets('Done returns the selection, dismissing returns null', (
    tester,
  ) async {
    var h = await openPicker(tester, repo, selected: {peace});
    await tester.tap(find.text('hope'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(h.result, {peace, hope});

    h = await openPicker(tester, repo, selected: {peace});
    await tester.tap(find.text('hope'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // the scrim
    await tester.pumpAndSettle();
    expect(h.closed, isTrue);
    expect(h.result, isNull); // the caller keeps its own selection
    await finish(tester);
  });

  test('letters: A to Z first, anything else under #', () {
    expect(letterOf('apple'), 'A');
    expect(letterOf('  zeal'), 'Z');
    expect(letterOf('1 Peter'), '#');
    expect(letterOf('élan'), '#');
    expect(letterOf(''), '#');
  });
}
