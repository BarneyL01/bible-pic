import 'package:bible_pic/data/providers.dart';
import 'package:bible_pic/ui/main_screen.dart';
import 'package:bible_pic/ui/verse_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  setUpAll(quietDriftWarnings);

  testWidgets('adding a verse shows it in the verse list', (tester) async {
    final repo = makeRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: VerseListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No verses yet. Tap + to add one.'), findsOneWidget);

    await tester.tap(find.byTooltip('Add verse'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Reference'),
      'John 3:16',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Text'),
      'For God so loved the world.',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('John 3:16'), findsOneWidget);
    expect(find.text('For God so loved the world.'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('the main screen shows a saved verse', (tester) async {
    final repo = makeRepo();
    await repo.saveVerse(verse('v1'), const []);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: MainScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Body v1'), findsOneWidget);
    expect(find.text('Ref v1'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('tapping a verse toggles its favourite', (tester) async {
    final repo = makeRepo();
    await repo.saveVerse(verse('v1'), const []);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: MainScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Body v1'));
    await tester.pumpAndSettle();
    expect((await repo.verseById('v1'))!.favourite, isTrue);
    await finish(tester);
  });
}
