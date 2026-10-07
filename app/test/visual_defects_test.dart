import 'package:bible_pic/data/providers.dart';
import 'package:bible_pic/ui/favourites_screen.dart';
import 'package:bible_pic/ui/themes_screen.dart';
import 'package:bible_pic/ui/topics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Widget app(Widget home, repo) => ProviderScope(
  overrides: [repositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(home: home),
);

void main() {
  setUpAll(quietDriftWarnings);

  group('D1: the app bar over an empty viewer', () {
    testWidgets('Favourites with no favourites is not the grey band', (
      tester,
    ) async {
      final repo = makeRepo();
      await tester.pumpWidget(app(const FavouritesScreen(), repo));
      await tester.pumpAndSettle();
      final bar = tester.widget<AppBar>(find.byType(AppBar));
      expect(bar.backgroundColor, isNot(Colors.black45));
      expect(find.textContaining('No favourites yet'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('Favourites with a favourite keeps the translucent bar', (
      tester,
    ) async {
      final repo = makeRepo();
      await repo.saveVerse(verse('v', fav: true), const []);
      await tester.pumpWidget(app(const FavouritesScreen(), repo));
      await tester.pumpAndSettle();
      final bar = tester.widget<AppBar>(find.byType(AppBar));
      expect(bar.backgroundColor, Colors.black45);
      await finish(tester);
    });

    testWidgets('a topic with no verses is not the grey band either', (
      tester,
    ) async {
      final repo = makeRepo();
      await repo.topicIdForName('empty topic');
      await tester.pumpWidget(app(const TopicsScreen(), repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('empty topic'));
      await tester.pumpAndSettle();
      final bar = tester.widget<AppBar>(find.byType(AppBar).last);
      expect(bar.backgroundColor, isNot(Colors.black45));
      expect(find.textContaining('No verses in this topic'), findsOneWidget);
      await finish(tester);
    });
  });

  testWidgets('D2: the default theme says it is in use, not "Default"', (
    tester,
  ) async {
    final repo = makeRepo();
    await tester.pumpWidget(app(const ThemesScreen(), repo));
    await tester.pumpAndSettle();
    expect(find.text('In use as default'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget); // the theme's name, once
    await finish(tester);
  });
}
