import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/local_motivation_repository.dart';
import '../../domain/entities/motivational_prompt.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/sync_result.dart';
import '../../domain/repositories/motivation_repository.dart';
import '../../domain/repositories/study_session_repository.dart';

class StudyDiaryNotifier extends ChangeNotifier {
  static const List<String> defaultSubjectChips = <String>[
    'TYT Mathematics',
    'TYT Turkish',
    'AYT Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Geometry',
    'History',
  ];

  final StudySessionRepository repository;
  final MotivationRepository motivationRepository;
  final DateTime Function() _clock;
  final Uuid _uuid;

  List<StudySession> _sessions = const <StudySession>[];
  StudySummary _summary = const StudySummary(totalMinutes: 0, sessionCount: 0);
  int _loadingCount = 0;
  String? _errorMessage;
  late MotivationalPrompt _currentPrompt;
  bool _isOfflineMode = true;
  SyncResult? _lastSyncResult;
  bool _isDisposed = false;

  StudyDiaryNotifier({
    required this.repository,
    MotivationRepository? motivationRepository,
    DateTime Function()? clock,
    Uuid? uuid,
  }) : motivationRepository =
           motivationRepository ?? LocalMotivationRepository(),
       _clock = clock ?? DateTime.now,
       _uuid = uuid ?? const Uuid() {
    _currentPrompt = this.motivationRepository.getInitialPrompt();
  }

  List<StudySession> get sessions => _sessions;
  StudySummary get summary => _summary;
  bool get isLoading => _loadingCount > 0;
  String? get errorMessage => _errorMessage;
  MotivationalPrompt get currentPrompt => _currentPrompt;
  bool get isOfflineMode => _isOfflineMode;
  SyncResult? get lastSyncResult => _lastSyncResult;

  List<String> get suggestedSubjects {
    final Set<String> seen = <String>{};
    final List<String> result = <String>[];
    for (final StudySession s in _sessions) {
      final String trimmed = s.subject.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed.toLowerCase())) {
        result.add(trimmed);
      }
    }
    for (final String preset in defaultSubjectChips) {
      if (seen.add(preset.toLowerCase())) {
        result.add(preset);
      }
    }
    return List<String>.unmodifiable(result.take(10));
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _reloadFromRepository() async {
    _sessions = List<StudySession>.unmodifiable(await repository.getSessions());
    _summary = StudySummary.fromSessions(_sessions, referenceDate: _clock());
  }

  Future<T> _runBusy<T>(Future<T> Function() action) async {
    _loadingCount += 1;
    _errorMessage = null;
    _safeNotify();
    try {
      return await action();
    } finally {
      if (_loadingCount > 0) _loadingCount -= 1;
      _safeNotify();
    }
  }

  Future<void> loadSessions() => _runBusy(() async {
    try {
      await _reloadFromRepository();
    } on StudySessionValidationException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load study sessions: $e';
    }
  });

  void nextPrompt({PromptCategory? category}) {
    _currentPrompt = motivationRepository.getNextPrompt(
      currentPromptId: _currentPrompt.id,
      category: category,
    );
    _safeNotify();
  }

  Future<bool> saveSession({
    required String subject,
    String topic = '',
    StudyActivityType activityType = StudyActivityType.topicStudy,
    SessionType sessionType = SessionType.freeStudy,
    int? elapsedSeconds,
    int? durationMinutes,
    int pausedSeconds = 0,
    int pauseCount = 0,
    int completedPomodoroSets = 0,
    int? targetPomodoroSets,
    int? targetDurationMinutes,
    int? correctCount,
    int? wrongCount,
    int? blankCount,
    List<ReflectionTag> reflectionTags = const <ReflectionTag>[],
    List<String> topicsToReview = const <String>[],
    int? focusRating,
    String notes = '',
    DateTime? startedAt,
    DateTime? endedAt,
    String? id,
    String? subjectId,
  }) => _runBusy(() async {
    try {
      final DateTime now = _clock();
      final DateTime start = startedAt ?? now;
      final DateTime end = endedAt != null && !endedAt.isBefore(start)
          ? endedAt
          : (now.isBefore(start) ? start : now);

      await repository.addSession(
        StudySession.validated(
          id: id ?? _uuid.v4(),
          subjectId: subjectId,
          subject: subject,
          topic: topic,
          notes: notes,
          activityType: activityType,
          sessionType: sessionType,
          status: SessionStatus.completed,
          startedAt: start,
          endedAt: end,
          elapsedSeconds: elapsedSeconds,
          durationMinutes: durationMinutes,
          pausedSeconds: pausedSeconds,
          pauseCount: pauseCount,
          completedPomodoroSets: completedPomodoroSets,
          targetPomodoroSets: targetPomodoroSets,
          targetDurationMinutes: targetDurationMinutes,
          correctCount: correctCount,
          wrongCount: wrongCount,
          blankCount: blankCount,
          reflectionTags: reflectionTags,
          topicsToReview: topicsToReview,
          focusRating: focusRating,
          createdAt: start,
          updatedAt: end,
        ),
      );
      await _reloadFromRepository();
      return true;
    } on StudySessionValidationException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to save study session: $e';
      return false;
    }
  });

  Future<bool> markReviewTopicResolved(String topicToResolve) =>
      _runBusy(() async {
        final String target = topicToResolve.trim().toLowerCase();
        if (target.isEmpty) return false;
        try {
          final DateTime now = _clock();
          for (final StudySession s in _sessions) {
            final bool hasTopic = s.topicsToReview.any(
              (String t) => t.trim().toLowerCase() == target,
            );
            if (!hasTopic) continue;
            final List<String> remaining = <String>[
              for (final String t in s.topicsToReview)
                if (t.trim().toLowerCase() != target) t,
            ];
            await repository.addSession(
              s.copyWith(
                topicsToReview: remaining,
                updatedAt: now.isBefore(s.createdAt) ? s.createdAt : now,
              ),
            );
          }
          await _reloadFromRepository();
          return true;
        } catch (e) {
          _errorMessage = 'Failed to update review topic: $e';
          return false;
        }
      });

  Future<bool> deleteSession(String id) => _runBusy(() async {
    try {
      await repository.deleteSession(id);
      await _reloadFromRepository();
      return true;
    } on ArgumentError catch (e) {
      _errorMessage = e.message?.toString() ?? 'Invalid session ID.';
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete study session: $e';
      return false;
    }
  });

  Future<SyncResult> syncNow() => _runBusy(() async {
    try {
      final SyncResult result = await repository.syncSessions();
      _lastSyncResult = result;
      _isOfflineMode = result.isOffline || !result.isSuccess;
      if (!result.isSuccess) _errorMessage = result.errorMessage;
      await _reloadFromRepository();
      return result;
    } catch (e) {
      final SyncResult failed = SyncResult(
        errorMessage: 'Failed to synchronize study sessions: $e',
      );
      _lastSyncResult = failed;
      _isOfflineMode = true;
      _errorMessage = failed.errorMessage;
      return failed;
    }
  });

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _safeNotify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
