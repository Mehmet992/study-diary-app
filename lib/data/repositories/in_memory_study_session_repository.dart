import '../../domain/entities/study_session.dart';
import '../../domain/entities/study_subject.dart';
import '../../domain/entities/sync_result.dart';
import '../../domain/repositories/study_session_repository.dart';
import '../datasources/local_study_data_source.dart';
import '../models/study_session_model.dart';
import '../models/study_subject_model.dart';

export '../models/study_session_model.dart';

class InMemoryStudySessionRepository implements StudySessionRepository {
  final InMemoryLocalStudyDataSource _store;

  InMemoryStudySessionRepository({
    List<StudySession> initialSessions = const <StudySession>[],
    List<StudySubject> initialSubjects = const <StudySubject>[],
  }) : _store = InMemoryLocalStudyDataSource(
         initialSessions: <StudySessionModel>[
           for (final StudySession s in initialSessions)
             StudySessionModel.fromEntity(s),
         ],
         initialSubjects: <StudySubjectModel>[
           for (final StudySubject s in initialSubjects)
             StudySubjectModel.fromEntity(s),
         ],
       );

  @override
  Future<List<StudySession>> getSessions() async {
    final List<StudySession> list = <StudySession>[
      for (final StudySessionModel m in await _store.getAllSessionModels())
        if (!m.isDeleted) m.toEntity(),
    ]..sort((StudySession a, StudySession b) => b.startedAt.compareTo(a.startedAt));
    return List<StudySession>.unmodifiable(list);
  }

  @override
  Future<void> addSession(StudySession session) =>
      _store.upsertSessionModel(StudySessionModel.fromEntity(session));

  @override
  Future<void> deleteSession(String id) {
    if (id.trim().isEmpty) {
      return Future<void>.error(
        ArgumentError.value(id, 'id', 'Session ID must not be empty.'),
      );
    }
    return _store.hardDeleteSessionModel(id);
  }

  @override
  Future<List<StudySubject>> getSubjects({bool includeArchived = false}) async {
    final List<StudySubject> list = <StudySubject>[
      for (final StudySubjectModel m in await _store.getAllSubjectModels())
        if (includeArchived || !m.isArchived) m.toEntity(),
    ]..sort((StudySubject a, StudySubject b) {
      final int cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return cmp != 0 ? cmp : a.name.compareTo(b.name);
    });
    return List<StudySubject>.unmodifiable(list);
  }

  @override
  Future<void> saveSubject(StudySubject subject) =>
      _store.upsertSubjectModel(StudySubjectModel.fromEntity(subject));

  @override
  Future<SyncResult> syncSessions() async => const SyncResult.offline();
}
