import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Verses extends Table {
  TextColumn get id => text()();
  TextColumn get reference => text()();
  TextColumn get body => text()();
  TextColumn get translation => text().nullable()();
  TextColumn get pinnedPhotoId => text().nullable()();
  TextColumn get themeId => text().nullable()();
  // Text box override as fractions of the canvas; all three set or all null.
  RealColumn get boxX => real().nullable()();
  RealColumn get boxY => real().nullable()();
  RealColumn get boxW => real().nullable()();
  BoolColumn get favourite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Topics extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get themeId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Photos extends Table {
  TextColumn get id => text()();
  // Relative to the app's photo folder, never absolute.
  TextColumn get path => text()();
  RealColumn get boxX => real().withDefault(const Constant(0.1))();
  RealColumn get boxY => real().withDefault(const Constant(0.55))();
  RealColumn get boxW => real().withDefault(const Constant(0.8))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AppTheme')
class Themes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get font => text().withDefault(const Constant('sans-serif'))();
  RealColumn get fontSize => real().withDefault(const Constant(26))();
  IntColumn get textColor => integer().withDefault(const Constant(0xFFFFFFFF))();
  // 'left' | 'center' | 'right'
  TextColumn get alignment => text().withDefault(const Constant('center'))();
  IntColumn get panelColor => integer().withDefault(const Constant(0xFF000000))();
  RealColumn get panelOpacity => real().withDefault(const Constant(0.5))();
  RealColumn get cornerRadius => real().withDefault(const Constant(12))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class VerseTopics extends Table {
  TextColumn get verseId => text()();
  TextColumn get topicId => text()();

  @override
  Set<Column> get primaryKey => {verseId, topicId};
}

class PhotoTopics extends Table {
  TextColumn get photoId => text()();
  TextColumn get topicId => text()();

  @override
  Set<Column> get primaryKey => {photoId, topicId};
}

@DataClassName('AppMetaRow')
class AppMeta extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get schemaVersion => integer()();
  DateTimeColumn get lastBackup => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Verses, Topics, Photos, Themes, VerseTopics, PhotoTopics, AppMeta],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? driftDatabase(name: 'bible_pic'));

  static const dataSchemaVersion = 1;

  @override
  int get schemaVersion => dataSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(appMeta).insert(
            AppMetaCompanion.insert(schemaVersion: dataSchemaVersion),
          );
          await into(themes).insert(
            ThemesCompanion.insert(
              id: 'default-theme',
              name: 'Default',
              isDefault: const Value(true),
            ),
          );
        },
      );
}
