import 'dart:async';

import '../models/study_session_model.dart';
import '../models/study_subject_model.dart';

class LocalStorageException implements Exception {
  final String message;
  final Object? cause;

  const LocalStorageException(this.message, {this.cause});

  @override
  String toString() => cause == null
      ? 'LocalStorageException: $message'
      : 'LocalStorageException: $message (cause: $cause)';
}

abstract interface class LocalStudyDataSource {
  Future<List<StudySessionModel>> getAllSessionModels();
  Future<void> upsertSessionModel(StudySessionModel model);
  Future<void> upsertSessionModels(List<StudySessionModel> models);
  Future<void> hardDeleteSessionModel(String id);
  Future<List<StudySubjectModel>> getAllSubjectModels();
  Future<void> upsertSubjectModel(StudySubjectModel model);
  Future<void> upsertSubjectModels(List<StudySubjectModel> models);
}

class InMemoryLocalStudyDataSource implements LocalStudyDataSource {
  final Map<String, StudySessionModel> _sessions =
      <String, StudySessionModel>{};
  final Map<String, StudySubjectModel> _subjects =
      <String, StudySubjectModel>{};
  Future<void> _pending = Future<void>.value();

  InMemoryLocalStudyDataSource({
    List<StudySessionModel> initialSessions = const <StudySessionModel>[],
    List<StudySubjectModel> initialSubjects = const <StudySubjectModel>[],
  }) {
    for (final StudySessionModel s in initialSessions) {
      _sessions[s.id] = s;
    }
    for (final StudySubjectModel s in initialSubjects) {
      _subjects[s.id] = s;
    }
  }

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final Future<void> prev = _pending;
    final Completer<void> done = Completer<void>();
    _pending = done.future;
    return prev.then<T>((_) => action()).whenComplete(() {
      if (!done.isCompleted) done.complete();
    });
  }

  @override
  Future<List<StudySessionModel>> getAllSessionModels() => _synchronized(
    () async => List<StudySessionModel>.unmodifiable(_sessions.values),
  );

  @override
  Future<void> upsertSessionModel(StudySessionModel model) =>
      _synchronized(() async => _sessions[model.id] = model);

  @override
  Future<void> upsertSessionModels(List<StudySessionModel> models) =>
      _synchronized(() async {
        for (final StudySessionModel m in models) {
          _sessions[m.id] = m;
        }
      });

  @override
  Future<void> hardDeleteSessionModel(String id) =>
      _synchronized(() async => _sessions.remove(id.trim()));

  @override
  Future<List<StudySubjectModel>> getAllSubjectModels() => _synchronized(
    () async => List<StudySubjectModel>.unmodifiable(_subjects.values),
  );

  @override
  Future<void> upsertSubjectModel(StudySubjectModel model) =>
      _synchronized(() async => _subjects[model.id] = model);

  @override
  Future<void> upsertSubjectModels(List<StudySubjectModel> models) =>
      _synchronized(() async {
        for (final StudySubjectModel m in models) {
          _subjects[m.id] = m;
        }
      });
}
