import '../../domain/entities/study_session.dart';
import '../../domain/entities/study_subject.dart';
import '../../domain/entities/sync_result.dart';
import '../../domain/repositories/study_session_repository.dart';
import '../datasources/local_study_data_source.dart';
import '../datasources/remote_study_data_source.dart';
import '../models/study_session_model.dart';
import '../models/study_subject_model.dart';

class OfflineFirstStudySessionRepository implements StudySessionRepository {
  final LocalStudyDataSource localDataSource;
  final RemoteStudyDataSource remoteDataSource;

  OfflineFirstStudySessionRepository({
    required this.localDataSource,
    RemoteStudyDataSource? remoteDataSource,
  }) : remoteDataSource = remoteDataSource ?? const OfflineRemoteStudyDataSource();

  static bool _needsSync(String s) =>
      s == SyncStatus.pendingSync.name || s == SyncStatus.syncFailed.name;

  Future<Map<String, StudySessionModel>> _sessionMap() async =>
      <String, StudySessionModel>{
        for (final StudySessionModel s in await localDataSource.getAllSessionModels())
          s.id: s,
      };

  Future<Map<String, StudySubjectModel>> _subjectMap() async =>
      <String, StudySubjectModel>{
        for (final StudySubjectModel s in await localDataSource.getAllSubjectModels())
          s.id: s,
      };

  @override
  Future<List<StudySession>> getSessions() async {
    final List<StudySession> active = <StudySession>[
      for (final StudySessionModel m in await localDataSource.getAllSessionModels())
        if (!m.isDeleted) m.toEntity(),
    ]..sort((StudySession a, StudySession b) => b.startedAt.compareTo(a.startedAt));
    return List<StudySession>.unmodifiable(active);
  }

  @override
  Future<void> addSession(StudySession session) =>
      localDataSource.upsertSessionModel(
        StudySessionModel.fromEntity(
          session.copyWith(isDeleted: false, syncStatus: SyncStatus.pendingSync),
        ),
      );

  @override
  Future<void> deleteSession(String id) async {
    final String cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Session ID must not be empty.');
    }
    final StudySessionModel? existing = (await _sessionMap())[cleanId];
    if (existing == null) return;

    DateTime updated = DateTime.now().toUtc();
    final DateTime? created = DateTime.tryParse(existing.createdAtIso8601);
    final DateTime? prev = DateTime.tryParse(existing.updatedAtIso8601);
    if (created != null && updated.isBefore(created)) updated = created;
    if (prev != null && updated.isBefore(prev)) updated = prev;

    await localDataSource.upsertSessionModel(
      existing.copyWith(
        isDeleted: true,
        syncStatus: SyncStatus.pendingDelete.name,
        updatedAtIso8601: updated.toIso8601String(),
      ),
    );
  }

  @override
  Future<List<StudySubject>> getSubjects({bool includeArchived = false}) async {
    final List<StudySubject> list = <StudySubject>[
      for (final StudySubjectModel m in await localDataSource.getAllSubjectModels())
        if (includeArchived || !m.isArchived) m.toEntity(),
    ]..sort((StudySubject a, StudySubject b) {
      final int cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return cmp != 0 ? cmp : a.name.compareTo(b.name);
    });
    return List<StudySubject>.unmodifiable(list);
  }

  @override
  Future<void> saveSubject(StudySubject subject) =>
      localDataSource.upsertSubjectModel(
        StudySubjectModel.fromEntity(
          subject.copyWith(syncStatus: SyncStatus.pendingSync),
        ),
      );

  @override
  Future<SyncResult> syncSessions() async {
    try {
      if (!await remoteDataSource.isOnline) return const SyncResult.offline();
    } catch (e) {
      return SyncResult(errorMessage: 'Failed to check connectivity: $e');
    }

    final List<StudySubjectModel> subjectsToPush = <StudySubjectModel>[
      for (final StudySubjectModel s in await localDataSource.getAllSubjectModels())
        if (_needsSync(s.syncStatus)) s,
    ];
    final List<StudySessionModel> snap = await localDataSource.getAllSessionModels();
    final List<StudySessionModel> sessionsToPush = <StudySessionModel>[
      for (final StudySessionModel s in snap)
        if (!s.isDeleted && _needsSync(s.syncStatus)) s,
    ];
    final List<StudySessionModel> tombstones = <StudySessionModel>[
      for (final StudySessionModel s in snap)
        if (s.isDeleted &&
            (s.syncStatus == SyncStatus.pendingDelete.name ||
                s.syncStatus == SyncStatus.syncFailed.name))
          s,
    ];

    int pushed = 0, pulled = 0, deleted = 0;

    try {
      if (subjectsToPush.isNotEmpty) {
        await remoteDataSource.pushSubjects(subjectsToPush);
        pushed += subjectsToPush.length;
        final Map<String, StudySubjectModel> cur = await _subjectMap();
        final List<StudySubjectModel> synced = <StudySubjectModel>[
          for (final StudySubjectModel p in subjectsToPush)
            if (cur[p.id]?.updatedAtIso8601 == p.updatedAtIso8601)
              cur[p.id]!.copyWith(syncStatus: SyncStatus.synced.name),
        ];
        if (synced.isNotEmpty) await localDataSource.upsertSubjectModels(synced);
      }

      if (sessionsToPush.isNotEmpty) {
        await remoteDataSource.pushSessions(sessionsToPush);
        pushed += sessionsToPush.length;
        final Map<String, StudySessionModel> cur = await _sessionMap();
        final List<StudySessionModel> synced = <StudySessionModel>[
          for (final StudySessionModel p in sessionsToPush)
            if (cur[p.id] != null &&
                !cur[p.id]!.isDeleted &&
                cur[p.id]!.updatedAtIso8601 == p.updatedAtIso8601)
              cur[p.id]!.copyWith(syncStatus: SyncStatus.synced.name),
        ];
        if (synced.isNotEmpty) await localDataSource.upsertSessionModels(synced);
      }

      if (tombstones.isNotEmpty) {
        await remoteDataSource.deleteRemoteSessions(
          <String>[for (final StudySessionModel t in tombstones) t.id],
        );
        final Map<String, StudySessionModel> cur = await _sessionMap();
        for (final StudySessionModel t in tombstones) {
          if (cur[t.id]?.isDeleted == true) {
            await localDataSource.hardDeleteSessionModel(t.id);
            deleted += 1;
          }
        }
      }

      final List<StudySubjectModel> remoteSubjects =
          await remoteDataSource.pullSubjects();
      if (remoteSubjects.isNotEmpty) {
        final Map<String, StudySubjectModel> local = await _subjectMap();
        final List<StudySubjectModel> merged = <StudySubjectModel>[];
        for (final StudySubjectModel r in remoteSubjects) {
          final StudySubjectModel? l = local[r.id];
          if (l == null ||
              (l.syncStatus == SyncStatus.synced.name &&
                  DateTime.parse(r.updatedAtIso8601)
                      .isAfter(DateTime.parse(l.updatedAtIso8601)))) {
            merged.add(r.copyWith(syncStatus: SyncStatus.synced.name));
            pulled += 1;
          }
        }
        if (merged.isNotEmpty) await localDataSource.upsertSubjectModels(merged);
      }

      final List<StudySessionModel> remoteSessions =
          await remoteDataSource.pullSessions();
      if (remoteSessions.isNotEmpty) {
        final Map<String, StudySessionModel> local = await _sessionMap();
        final List<StudySessionModel> merged = <StudySessionModel>[];
        for (final StudySessionModel r in remoteSessions) {
          final StudySessionModel? l = local[r.id];
          if (r.isDeleted) {
            if (l?.syncStatus == SyncStatus.synced.name) {
              await localDataSource.hardDeleteSessionModel(r.id);
              pulled += 1;
            }
            continue;
          }
          if (l == null ||
              (!l.isDeleted &&
                  l.syncStatus == SyncStatus.synced.name &&
                  DateTime.parse(r.updatedAtIso8601)
                      .isAfter(DateTime.parse(l.updatedAtIso8601)))) {
            merged.add(r.copyWith(syncStatus: SyncStatus.synced.name));
            pulled += 1;
          }
        }
        if (merged.isNotEmpty) await localDataSource.upsertSessionModels(merged);
      }

      return SyncResult(
        pushedCount: pushed,
        pulledCount: pulled,
        deletedCount: deleted,
      );
    } catch (e) {
      await _markFailed(subjectsToPush, <StudySessionModel>[
        ...sessionsToPush,
        ...tombstones,
      ]);
      return SyncResult(
        pushedCount: pushed,
        pulledCount: pulled,
        deletedCount: deleted,
        errorMessage: 'Synchronization failed: $e',
      );
    }
  }

  Future<void> _markFailed(
    List<StudySubjectModel> subjects,
    List<StudySessionModel> sessions,
  ) async {
    try {
      if (subjects.isNotEmpty) {
        final Map<String, StudySubjectModel> cur = await _subjectMap();
        final List<StudySubjectModel> failed = <StudySubjectModel>[
          for (final StudySubjectModel a in subjects)
            if (cur[a.id] != null &&
                cur[a.id]!.syncStatus != SyncStatus.synced.name &&
                cur[a.id]!.updatedAtIso8601 == a.updatedAtIso8601)
              cur[a.id]!.copyWith(syncStatus: SyncStatus.syncFailed.name),
        ];
        if (failed.isNotEmpty) await localDataSource.upsertSubjectModels(failed);
      }
      if (sessions.isNotEmpty) {
        final Map<String, StudySessionModel> cur = await _sessionMap();
        final List<StudySessionModel> failed = <StudySessionModel>[
          for (final StudySessionModel a in sessions)
            if (cur[a.id] != null &&
                cur[a.id]!.syncStatus != SyncStatus.synced.name &&
                cur[a.id]!.updatedAtIso8601 == a.updatedAtIso8601)
              cur[a.id]!.copyWith(syncStatus: SyncStatus.syncFailed.name),
        ];
        if (failed.isNotEmpty) await localDataSource.upsertSessionModels(failed);
      }
    } catch (_) {}
  }
}
