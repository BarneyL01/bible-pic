import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import 'repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider =
    Provider<Repository>((ref) => Repository(ref.watch(databaseProvider)));

final versesProvider = StreamProvider<List<Verse>>(
    (ref) => ref.watch(repositoryProvider).watchVerses());
final topicsProvider = StreamProvider<List<Topic>>(
    (ref) => ref.watch(repositoryProvider).watchTopics());
final photosProvider = StreamProvider<List<Photo>>(
    (ref) => ref.watch(repositoryProvider).watchPhotos());
final themesProvider = StreamProvider<List<AppTheme>>(
    (ref) => ref.watch(repositoryProvider).watchThemes());
final verseTopicsProvider = StreamProvider<List<VerseTopic>>(
    (ref) => ref.watch(repositoryProvider).watchVerseTopics());
final photoTopicsProvider = StreamProvider<List<PhotoTopic>>(
    (ref) => ref.watch(repositoryProvider).watchPhotoTopics());
final metaProvider = StreamProvider<AppMetaRow>(
    (ref) => ref.watch(repositoryProvider).watchMeta());

final verseProvider = StreamProvider.family<Verse?, String>(
    (ref, id) => ref.watch(repositoryProvider).watchVerse(id));
