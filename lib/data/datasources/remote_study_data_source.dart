import '../models/study_session_model.dart';
import '../models/study_subject_model.dart';

abstract interface class RemoteStudyDataSource {
  Future<bool> get isOnline;
  Future<void> pushSessions(List<StudySessionModel> sessions);
  Future<void> deleteRemoteSessions(List<String> sessionIds);
  Future<List<StudySessionModel>> pullSessions({DateTime? since});
  Future<void> pushSubjects(List<StudySubjectModel> subjects);
  Future<List<StudySubjectModel>> pullSubjects({DateTime? since});
}

class OfflineRemoteStudyDataSource implements RemoteStudyDataSource {
  const OfflineRemoteStudyDataSource();

  static Never _offline(String op) =>
      throw StateError('Cannot $op while RemoteStudyDataSource is offline.');

  @override
  Future<bool> get isOnline => Future<bool>.value(false);

  @override
  Future<void> pushSessions(List<StudySessionModel> sessions) async =>
      _offline('push sessions');

  @override
  Future<void> deleteRemoteSessions(List<String> sessionIds) async =>
      _offline('delete remote sessions');

  @override
  Future<List<StudySessionModel>> pullSessions({DateTime? since}) async =>
      _offline('pull sessions');

  @override
  Future<void> pushSubjects(List<StudySubjectModel> subjects) async =>
      _offline('push subjects');

  @override
  Future<List<StudySubjectModel>> pullSubjects({DateTime? since}) async =>
      _offline('pull subjects');
}
