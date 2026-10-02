import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'data/providers.dart';
import 'services/widget_sync.dart';
import 'ui/main_screen.dart';
import 'ui/viewer_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BiblePicApp()));
}

final navigatorKey = GlobalKey<NavigatorState>();

class BiblePicApp extends ConsumerStatefulWidget {
  const BiblePicApp({super.key});

  @override
  ConsumerState<BiblePicApp> createState() => _BiblePicAppState();
}

class _BiblePicAppState extends ConsumerState<BiblePicApp> {
  StreamSubscription<Uri?>? _clicks;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _clicks = HomeWidget.widgetClicked.listen(_openFromWidget);
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_openFromWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleSync());
  }

  @override
  void dispose() {
    _clicks?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  /// Re-render the widget images shortly after data changes settle.
  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        WidgetSync(ref.read(repositoryProvider)).sync(ctx);
      }
    });
  }

  Future<void> _openFromWidget(Uri? uri) async {
    if (uri == null || uri.pathSegments.isEmpty) return;
    final id = uri.pathSegments.last;
    if (id.isEmpty) return;
    final repo = ref.read(repositoryProvider);
    final verses = await repo.allVerses();
    if (!verses.any((v) => v.id == id)) return;
    navigatorKey.currentState?.push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: ViewerPage(pool: verses, infinite: true, startVerseId: id),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(versesProvider, (_, __) => _scheduleSync());
    ref.listen(photosProvider, (_, __) => _scheduleSync());
    ref.listen(themesProvider, (_, __) => _scheduleSync());
    ref.listen(topicsProvider, (_, __) => _scheduleSync());
    ref.listen(verseTopicsProvider, (_, __) => _scheduleSync());
    ref.listen(photoTopicsProvider, (_, __) => _scheduleSync());
    return MaterialApp(
      title: 'Bible Pic',
      navigatorKey: navigatorKey,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
          useMaterial3: true),
      home: const MainScreen(),
    );
  }
}
