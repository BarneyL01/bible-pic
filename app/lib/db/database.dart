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
  // Added in schema 2.
  RealColumn get referenceFontSize => real().withDefault(const Constant(16))();
  IntColumn get textColor =>
      integer().withDefault(const Constant(0xFFFFFFFF))();
  // 'left' | 'center' | 'right'
  TextColumn get alignment => text().withDefault(const Constant('center'))();
  IntColumn get panelColor =>
      integer().withDefault(const Constant(0xFF000000))();
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
  // Added in schema 3: the bundled default photos are added once, then never again.
  BoolColumn get defaultPhotosSeeded =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Verses, Topics, Photos, Themes, VerseTopics, PhotoTopics, AppMeta],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  static QueryExecutor _openConnection() => driftDatabase(
    name: 'bible_pic',
    // Web only: the files are copied into web/ (see tool/fetch_web_assets).
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );

  /// Database schema version (bump with a migration below).
  static const dataSchemaVersion = 3;

  /// Version of the backup zip's `data.json`. Unchanged since schema 2: schema 3
  /// added a column that backups do not carry, so a v3 app writes v2 backups.
  static const backupFormatVersion = 2;

  @override
  int get schemaVersion => dataSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(themes, themes.referenceFontSize);
      }
      if (from < 3) {
        await m.addColumn(appMeta, appMeta.defaultPhotosSeeded);
      }
      await (update(appMeta)).write(AppMetaCompanion(schemaVersion: Value(to)));
    },
    onCreate: (m) async {
      await m.createAll();
      await into(
        appMeta,
      ).insert(AppMetaCompanion.insert(schemaVersion: dataSchemaVersion));
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
