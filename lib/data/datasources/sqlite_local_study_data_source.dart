import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/study_session_model.dart';
import '../models/study_subject_model.dart';
import 'local_study_data_source.dart';

typedef DatabasePathResolver = Future<String> Function();

class SqliteLocalStudyDataSource implements LocalStudyDataSource {
  static const int _schemaVersion = 1;
  static const String _sessionsTable = 'study_sessions';
  static const String _subjectsTable = 'study_subjects';

  final DatabasePathResolver _pathResolver;
  Database? _db;
  Future<Database>? _opening;

  SqliteLocalStudyDataSource({DatabasePathResolver? pathResolver})
    : _pathResolver = pathResolver ?? _defaultDatabasePathResolver;

  static Future<String> _defaultDatabasePathResolver() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'study_diary.db');
  }

  Future<Database> _getDatabase() async {
    if (_db != null && _db!.isOpen) return _db!;
    if (_opening != null) return _opening!;

    final Future<Database> openingFuture = _openDatabaseInternal();
    _opening = openingFuture;
    try {
      final Database db = await openingFuture;
      _db = db;
      return db;
    } catch (_) {
      if (identical(_opening, openingFuture)) {
        _opening = null;
      }
      rethrow;
    }
  }

  Future<Database> _openDatabaseInternal() async {
    try {
      final String dbPath = await _pathResolver();
      if (dbPath != inMemoryDatabasePath) {
        await Directory(p.dirname(dbPath)).create(recursive: true);
      }
      return await openDatabase(
        dbPath,
        version: _schemaVersion,
        onCreate: _onCreate,
      );
    } on LocalStorageException {
      rethrow;
    } catch (e) {
      throw LocalStorageException(
        'Failed to open local SQLite study database.',
        cause: e,
      );
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_subjectsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_sessionsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        subject_id TEXT,
        subject TEXT NOT NULL,
        topic TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        activity_type TEXT NOT NULL DEFAULT 'topicStudy',
        session_type TEXT NOT NULL DEFAULT 'freeStudy',
        status TEXT NOT NULL DEFAULT 'completed',
        started_at TEXT NOT NULL,
        ended_at TEXT,
        elapsed_seconds INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL,
        paused_seconds INTEGER NOT NULL DEFAULT 0,
        pause_count INTEGER NOT NULL DEFAULT 0,
        completed_pomodoro_sets INTEGER NOT NULL DEFAULT 0,
        target_pomodoro_sets INTEGER,
        target_duration_minutes INTEGER,
        correct_count INTEGER,
        wrong_count INTEGER,
        blank_count INTEGER,
        reflection_tags_json TEXT NOT NULL DEFAULT '[]',
        topics_to_review_json TEXT NOT NULL DEFAULT '[]',
        focus_rating INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'localOnly'
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_study_sessions_started_at ON $_sessionsTable (started_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_study_sessions_sync_status ON $_sessionsTable (sync_status)',
    );
  }

  @override
  Future<List<StudySessionModel>> getAllSessionModels() async {
    try {
      final Database db = await _getDatabase();
      final List<Map<String, Object?>> rows = await db.query(
        _sessionsTable,
        orderBy: 'started_at DESC',
      );
      return List<StudySessionModel>.unmodifiable(<StudySessionModel>[
        for (final Map<String, Object?> row in rows)
          StudySessionModel.fromSqlMap(row),
      ]);
    } on LocalStorageException {
      rethrow;
    } catch (e) {
      throw LocalStorageException(
        'Failed to query study sessions from SQLite.',
        cause: e,
      );
    }
  }

  @override
  Future<void> upsertSessionModel(StudySessionModel model) =>
      upsertSessionModels(<StudySessionModel>[model]);

  @override
  Future<void> upsertSessionModels(List<StudySessionModel> models) async {
    if (models.isEmpty) return;
    try {
      final Database db = await _getDatabase();
      await db.transaction((Transaction txn) async {
        final Batch batch = txn.batch();
        for (final StudySessionModel model in models) {
          batch.insert(
            _sessionsTable,
            model.toSqlMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } on LocalStorageException {
      rethrow;
    } catch (e) {
      throw LocalStorageException(
        'Failed to save study sessions to SQLite.',
        cause: e,
      );
    }
  }

  @override
  Future<void> hardDeleteSessionModel(String id) async {
    final String cleanId = id.trim();
    if (cleanId.isEmpty) return;
    try {
      final Database db = await _getDatabase();
      await db.delete(
        _sessionsTable,
        where: 'id = ?',
        whereArgs: <Object?>[cleanId],
      );
    } on LocalStorageException {
      rethrow;
    } catch (e) {
      throw LocalStorageException(
        'Failed to delete study session "$cleanId" from SQLite.',
        cause: e,
      );
    }
  }

  @override
  Future<List<StudySubjectModel>> getAllSubjectModels() async {
    try {
      final Database db = await _getDatabase();
      final List<Map<String, Object?>> rows = await db.query(
        _subjectsTable,
        orderBy: 'name ASC',
      );
      return List<StudySubjectModel>.unmodifiable(<StudySubjectModel>[
        for (final Map<String, Object?> row in rows)
          StudySubjectModel.fromSqlMap(row),
      ]);
    } on LocalStorageException {
      rethrow;
    } catch (e) {
      throw LocalStorageException(
        'Failed to query study subjects from SQLite.',
        cause: e,
      );
    }
  }

  @override
  Future<void> upsertSubjectModel(StudySubjectModel model) =>
      upsertSubjectModels(<StudySubjectModel>[model]);

  @override
  Future<void> upsertSubjectModels(List<StudySubjectModel> models) async {
    if (models.isEmpty) return;
    try {
      final Database db = await _getDatabase();
      await db.transaction((Transaction txn) async {
        final Batch batch = txn.batch();
        for (final StudySubjectModel model in models) {
          batch.insert(
            _subjectsTable,
            model.toSqlMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } on LocalStorageException {
      rethrow;
    } catch (e) {
      throw LocalStorageException(
        'Failed to save study subjects to SQLite.',
        cause: e,
      );
    }
  }

  Future<void> close() async {
    final Database? db = _db;
    _db = null;
    _opening = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}
