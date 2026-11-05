import '../entities/study_session.dart';
import '../entities/study_subject.dart';
import '../entities/sync_result.dart';

abstract interface class StudySessionRepository {
  Future<List<StudySession>> getSessions();
  Future<void> addSession(StudySession session);
  Future<void> deleteSession(String id);
  Future<List<StudySubject>> getSubjects({bool includeArchived = false});
  Future<void> saveSubject(StudySubject subject);
  Future<SyncResult> syncSessions();
}
