import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/entities/study_session.dart';

class StudySessionModel {
  final String id;
  final String? userId;
  final String? subjectId;
  final String subject;
  final String topic;
  final String notes;
  final String activityType;
  final String sessionType;
  final String status;
  final String startedAtIso8601;
  final String? endedAtIso8601;
  final int elapsedSeconds;
  final int durationMinutes;
  final int pausedSeconds;
  final int pauseCount;
  final int completedPomodoroSets;
  final int? targetPomodoroSets;
  final int? targetDurationMinutes;
  final int? correctCount;
  final int? wrongCount;
  final int? blankCount;
  final List<String> reflectionTags;
  final List<String> topicsToReview;
  final int? focusRating;
  final String createdAtIso8601;
  final String updatedAtIso8601;
  final bool isDeleted;
  final String syncStatus;

  const StudySessionModel({
    required this.id,
    this.userId,
    this.subjectId,
    required this.subject,
    this.topic = '',
    this.notes = '',
    this.activityType = 'topicStudy',
    this.sessionType = 'freeStudy',
    this.status = 'completed',
    required this.startedAtIso8601,
    this.endedAtIso8601,
    required this.elapsedSeconds,
    required this.durationMinutes,
    this.pausedSeconds = 0,
    this.pauseCount = 0,
    this.completedPomodoroSets = 0,
    this.targetPomodoroSets,
    this.targetDurationMinutes,
    this.correctCount,
    this.wrongCount,
    this.blankCount,
    this.reflectionTags = const <String>[],
    this.topicsToReview = const <String>[],
    this.focusRating,
    required this.createdAtIso8601,
    required this.updatedAtIso8601,
    this.isDeleted = false,
    this.syncStatus = 'localOnly',
  });

  static String _reqStr(Map<String, Object?> map, String key) {
    final Object? v = map[key];
    if (v is! String || v.trim().isEmpty) {
      throw FormatException('Invalid or missing "$key" field.');
    }
    return v.trim();
  }

  static String? _optStr(Map<String, Object?> map, String key) {
    final Object? v = map[key];
    if (v == null) return null;
    if (v is! String) throw FormatException('Invalid "$key" field.');
    return v.trim();
  }

  static int? _optInt(Map<String, Object?> map, String key) {
    final Object? v = map[key];
    if (v == null) return null;
    if (v is! int) throw FormatException('Invalid "$key" field.');
    return v;
  }

  static bool _parseBool(Object? raw, String key, {bool defaultValue = false}) {
    if (raw == null) return defaultValue;
    if (raw is bool) return raw;
    if (raw is int && (raw == 0 || raw == 1)) return raw == 1;
    throw FormatException('Invalid "$key" field.');
  }

  static List<String> _parseStringList(Object? raw, String key) {
    if (raw == null) return const <String>[];
    if (raw is String) {
      final String trimmed = raw.trim();
      if (trimmed.isEmpty) return const <String>[];
      final Object? decoded = jsonDecode(trimmed);
      if (decoded is! List<Object?>) {
        throw FormatException('Invalid JSON list for "$key".');
      }
      return <String>[
        for (final Object? item in decoded)
          item is String
              ? item.trim()
              : throw FormatException('Invalid item in "$key".'),
      ];
    }
    if (raw is List<Object?>) {
      return <String>[
        for (final Object? item in raw)
          item is String
              ? item.trim()
              : throw FormatException('Invalid item in "$key".'),
      ];
    }
    throw FormatException('Invalid "$key" field.');
  }

  static DateTime _reqDate(Object? raw, String key) {
    if (raw is! String || raw.trim().isEmpty) {
      throw FormatException('Invalid or missing "$key" field.');
    }
    return DateTime.tryParse(raw.trim()) ??
        (throw FormatException('Malformed ISO-8601 "$key" field.'));
  }

  static DateTime? _optDate(Object? raw, String key) =>
      raw == null ? null : _reqDate(raw, key);

  factory StudySessionModel.fromEntity(StudySession e) {
    final StudySession v = StudySession.validated(
      id: e.id,
      userId: e.userId,
      subjectId: e.subjectId,
      subject: e.subject,
      topic: e.topic,
      notes: e.notes,
      activityType: e.activityType,
      sessionType: e.sessionType,
      status: e.status,
      startedAt: e.startedAt,
      endedAt: e.endedAt,
      elapsedSeconds: e.elapsedSeconds,
      pausedSeconds: e.pausedSeconds,
      pauseCount: e.pauseCount,
      completedPomodoroSets: e.completedPomodoroSets,
      targetPomodoroSets: e.targetPomodoroSets,
      targetDurationMinutes: e.targetDurationMinutes,
      correctCount: e.correctCount,
      wrongCount: e.wrongCount,
      blankCount: e.blankCount,
      reflectionTags: e.reflectionTags,
      topicsToReview: e.topicsToReview,
      focusRating: e.focusRating,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      isDeleted: e.isDeleted,
      syncStatus: e.syncStatus,
    );
    return StudySessionModel(
      id: v.id,
      userId: v.userId,
      subjectId: v.subjectId,
      subject: v.subject,
      topic: v.topic,
      notes: v.notes,
      activityType: v.activityType.name,
      sessionType: v.sessionType.name,
      status: v.status.name,
      startedAtIso8601: v.startedAt.toIso8601String(),
      endedAtIso8601: v.endedAt?.toIso8601String(),
      elapsedSeconds: v.elapsedSeconds,
      durationMinutes: v.durationMinutes,
      pausedSeconds: v.pausedSeconds,
      pauseCount: v.pauseCount,
      completedPomodoroSets: v.completedPomodoroSets,
      targetPomodoroSets: v.targetPomodoroSets,
      targetDurationMinutes: v.targetDurationMinutes,
      correctCount: v.correctCount,
      wrongCount: v.wrongCount,
      blankCount: v.blankCount,
      reflectionTags: List<String>.unmodifiable(
        v.reflectionTags.map((ReflectionTag t) => t.name),
      ),
      topicsToReview: List<String>.unmodifiable(v.topicsToReview),
      focusRating: v.focusRating,
      createdAtIso8601: v.createdAt.toIso8601String(),
      updatedAtIso8601: v.updatedAt.toIso8601String(),
      isDeleted: v.isDeleted,
      syncStatus: v.syncStatus.name,
    );
  }

  factory StudySessionModel.fromMap(Map<String, Object?> map) {
    final int? elapsed = _optInt(map, 'elapsedSeconds');
    final int? duration = _optInt(map, 'durationMinutes');
    if (duration != null && duration < 0) {
      throw const FormatException('Negative "durationMinutes" field.');
    }
    if (elapsed == null && duration == null) {
      throw const FormatException(
        'Missing "elapsedSeconds" or "durationMinutes" field.',
      );
    }
    final bool isDeleted = _parseBool(map['isDeleted'], 'isDeleted');
    final String? rawActivity = _optStr(map, 'activityType');
    final String? rawType = _optStr(map, 'sessionType');
    final String? rawStatus = _optStr(map, 'status');
    final String? rawSync = _optStr(map, 'syncStatus');
    final List<String> rawTags =
        _parseStringList(map['reflectionTags'], 'reflectionTags');
    final List<String> rawTopics =
        _parseStringList(map['topicsToReview'], 'topicsToReview');

    final DateTime startedAt = _reqDate(
      map['startedAt'] ??
          map['startedAtIso8601'] ??
          map['timestamp'] ??
          map['timestampIso8601'],
      'startedAt',
    );
    final DateTime? endedAt =
        _optDate(map['endedAt'] ?? map['endedAtIso8601'], 'endedAt');
    final DateTime createdAt =
        _optDate(map['createdAt'] ?? map['createdAtIso8601'], 'createdAt') ??
        startedAt;
    final DateTime updatedAt =
        _optDate(map['updatedAt'] ?? map['updatedAtIso8601'], 'updatedAt') ??
        (endedAt ?? createdAt);

    try {
      return StudySessionModel.fromEntity(
        StudySession.validated(
          id: _reqStr(map, 'id'),
          userId: _optStr(map, 'userId'),
          subjectId: _optStr(map, 'subjectId'),
          subject: _reqStr(map, 'subject'),
          topic: _optStr(map, 'topic') ?? '',
          notes: _optStr(map, 'notes') ?? '',
          activityType: rawActivity == null || rawActivity.isEmpty
              ? StudyActivityType.topicStudy
              : StudyActivityType.fromStorageString(rawActivity),
          sessionType: rawType == null
              ? SessionType.freeStudy
              : SessionType.fromStorageString(rawType),
          status: rawStatus == null
              ? SessionStatus.completed
              : SessionStatus.fromStorageString(rawStatus),
          startedAt: startedAt,
          endedAt: endedAt,
          elapsedSeconds: elapsed,
          durationMinutes: duration,
          pausedSeconds: _optInt(map, 'pausedSeconds') ?? 0,
          pauseCount: _optInt(map, 'pauseCount') ?? 0,
          completedPomodoroSets: _optInt(map, 'completedPomodoroSets') ?? 0,
          targetPomodoroSets: _optInt(map, 'targetPomodoroSets'),
          targetDurationMinutes: _optInt(map, 'targetDurationMinutes'),
          correctCount: _optInt(map, 'correctCount'),
          wrongCount: _optInt(map, 'wrongCount'),
          blankCount: _optInt(map, 'blankCount'),
          reflectionTags: <ReflectionTag>[
            for (final String tag in rawTags)
              ReflectionTag.fromStorageString(tag),
          ],
          topicsToReview: rawTopics,
          focusRating: _optInt(map, 'focusRating'),
          createdAt: createdAt,
          updatedAt: updatedAt,
          isDeleted: isDeleted,
          syncStatus: rawSync == null
              ? SyncStatus.localOnly
              : SyncStatus.fromStorageString(rawSync),
        ),
      );
    } on StudySessionValidationException catch (e) {
      throw FormatException(e.message);
    }
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'userId': userId,
    'subjectId': subjectId,
    'subject': subject,
    'topic': topic,
    'notes': notes,
    'activityType': activityType,
    'sessionType': sessionType,
    'status': status,
    'startedAt': startedAtIso8601,
    'endedAt': endedAtIso8601,
    'elapsedSeconds': elapsedSeconds,
    'durationMinutes': durationMinutes,
    'pausedSeconds': pausedSeconds,
    'pauseCount': pauseCount,
    'completedPomodoroSets': completedPomodoroSets,
    'targetPomodoroSets': targetPomodoroSets,
    'targetDurationMinutes': targetDurationMinutes,
    'correctCount': correctCount,
    'wrongCount': wrongCount,
    'blankCount': blankCount,
    'reflectionTags': reflectionTags,
    'topicsToReview': topicsToReview,
    'focusRating': focusRating,
    'createdAt': createdAtIso8601,
    'updatedAt': updatedAtIso8601,
    'isDeleted': isDeleted,
    'syncStatus': syncStatus,
  };

  Map<String, Object?> toSqlMap() => <String, Object?>{
    'id': id,
    'user_id': userId,
    'subject_id': subjectId,
    'subject': subject,
    'topic': topic,
    'notes': notes,
    'activity_type': activityType,
    'session_type': sessionType,
    'status': status,
    'started_at': startedAtIso8601,
    'ended_at': endedAtIso8601,
    'elapsed_seconds': elapsedSeconds,
    'duration_minutes': durationMinutes,
    'paused_seconds': pausedSeconds,
    'pause_count': pauseCount,
    'completed_pomodoro_sets': completedPomodoroSets,
    'target_pomodoro_sets': targetPomodoroSets,
    'target_duration_minutes': targetDurationMinutes,
    'correct_count': correctCount,
    'wrong_count': wrongCount,
    'blank_count': blankCount,
    'reflection_tags_json': jsonEncode(reflectionTags),
    'topics_to_review_json': jsonEncode(topicsToReview),
    'focus_rating': focusRating,
    'created_at': createdAtIso8601,
    'updated_at': updatedAtIso8601,
    'is_deleted': isDeleted ? 1 : 0,
    'sync_status': syncStatus,
  };

  factory StudySessionModel.fromSqlMap(Map<String, Object?> row) =>
      StudySessionModel.fromMap(<String, Object?>{
        'id': row['id'],
        'userId': row['user_id'],
        'subjectId': row['subject_id'],
        'subject': row['subject'],
        'topic': row['topic'],
        'notes': row['notes'],
        'activityType': row['activity_type'],
        'sessionType': row['session_type'],
        'status': row['status'],
        'startedAt': row['started_at'],
        'endedAt': row['ended_at'],
        'elapsedSeconds': row['elapsed_seconds'],
        'durationMinutes': row['duration_minutes'],
        'pausedSeconds': row['paused_seconds'],
        'pauseCount': row['pause_count'],
        'completedPomodoroSets': row['completed_pomodoro_sets'],
        'targetPomodoroSets': row['target_pomodoro_sets'],
        'targetDurationMinutes': row['target_duration_minutes'],
        'correctCount': row['correct_count'],
        'wrongCount': row['wrong_count'],
        'blankCount': row['blank_count'],
        'reflectionTags': row['reflection_tags_json'],
        'topicsToReview': row['topics_to_review_json'],
        'focusRating': row['focus_rating'],
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
        'isDeleted': row['is_deleted'],
        'syncStatus': row['sync_status'],
      });

  StudySession toEntity() => StudySession.validated(
    id: id,
    userId: userId,
    subjectId: subjectId,
    subject: subject,
    topic: topic,
    notes: notes,
    activityType: StudyActivityType.fromStorageString(activityType),
    sessionType: SessionType.fromStorageString(sessionType),
    status: SessionStatus.fromStorageString(status),
    startedAt: _reqDate(startedAtIso8601, 'startedAtIso8601'),
    endedAt: _optDate(endedAtIso8601, 'endedAtIso8601'),
    elapsedSeconds: elapsedSeconds,
    pausedSeconds: pausedSeconds,
    pauseCount: pauseCount,
    completedPomodoroSets: completedPomodoroSets,
    targetPomodoroSets: targetPomodoroSets,
    targetDurationMinutes: targetDurationMinutes,
    correctCount: correctCount,
    wrongCount: wrongCount,
    blankCount: blankCount,
    reflectionTags: <ReflectionTag>[
      for (final String tag in reflectionTags)
        ReflectionTag.fromStorageString(tag),
    ],
    topicsToReview: topicsToReview,
    focusRating: focusRating,
    createdAt: _reqDate(createdAtIso8601, 'createdAtIso8601'),
    updatedAt: _reqDate(updatedAtIso8601, 'updatedAtIso8601'),
    isDeleted: isDeleted,
    syncStatus: SyncStatus.fromStorageString(syncStatus),
  );

  StudySessionModel copyWith({
    String? id,
    String? userId,
    bool clearUserId = false,
    String? subjectId,
    bool clearSubjectId = false,
    String? subject,
    String? topic,
    String? notes,
    String? activityType,
    String? sessionType,
    String? status,
    String? startedAtIso8601,
    String? endedAtIso8601,
    bool clearEndedAt = false,
    int? elapsedSeconds,
    int? durationMinutes,
    int? pausedSeconds,
    int? pauseCount,
    int? completedPomodoroSets,
    int? targetPomodoroSets,
    bool clearTargetPomodoroSets = false,
    int? targetDurationMinutes,
    bool clearTargetDurationMinutes = false,
    int? correctCount,
    bool clearCorrectCount = false,
    int? wrongCount,
    bool clearWrongCount = false,
    int? blankCount,
    bool clearBlankCount = false,
    List<String>? reflectionTags,
    List<String>? topicsToReview,
    int? focusRating,
    bool clearFocusRating = false,
    String? createdAtIso8601,
    String? updatedAtIso8601,
    bool? isDeleted,
    String? syncStatus,
  }) {
    final int nextElapsed = elapsedSeconds ?? this.elapsedSeconds;
    final int nextDuration = durationMinutes ??
        (elapsedSeconds != null
            ? (nextElapsed <= 0 ? 0 : (nextElapsed + 59) ~/ 60)
            : this.durationMinutes);
    return StudySessionModel(
      id: id ?? this.id,
      userId: clearUserId ? null : (userId ?? this.userId),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      notes: notes ?? this.notes,
      activityType: activityType ?? this.activityType,
      sessionType: sessionType ?? this.sessionType,
      status: status ?? this.status,
      startedAtIso8601: startedAtIso8601 ?? this.startedAtIso8601,
      endedAtIso8601: clearEndedAt ? null : (endedAtIso8601 ?? this.endedAtIso8601),
      elapsedSeconds: nextElapsed,
      durationMinutes: nextDuration,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      pauseCount: pauseCount ?? this.pauseCount,
      completedPomodoroSets: completedPomodoroSets ?? this.completedPomodoroSets,
      targetPomodoroSets: clearTargetPomodoroSets
          ? null
          : (targetPomodoroSets ?? this.targetPomodoroSets),
      targetDurationMinutes: clearTargetDurationMinutes
          ? null
          : (targetDurationMinutes ?? this.targetDurationMinutes),
      correctCount: clearCorrectCount ? null : (correctCount ?? this.correctCount),
      wrongCount: clearWrongCount ? null : (wrongCount ?? this.wrongCount),
      blankCount: clearBlankCount ? null : (blankCount ?? this.blankCount),
      reflectionTags: reflectionTags ?? this.reflectionTags,
      topicsToReview: topicsToReview ?? this.topicsToReview,
      focusRating: clearFocusRating ? null : (focusRating ?? this.focusRating),
      createdAtIso8601: createdAtIso8601 ?? this.createdAtIso8601,
      updatedAtIso8601: updatedAtIso8601 ?? this.updatedAtIso8601,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  List<Object?> get _props => <Object?>[
    id,
    userId,
    subjectId,
    subject,
    topic,
    notes,
    activityType,
    sessionType,
    status,
    startedAtIso8601,
    endedAtIso8601,
    elapsedSeconds,
    durationMinutes,
    pausedSeconds,
    pauseCount,
    completedPomodoroSets,
    targetPomodoroSets,
    targetDurationMinutes,
    correctCount,
    wrongCount,
    blankCount,
    Object.hashAll(reflectionTags),
    Object.hashAll(topicsToReview),
    focusRating,
    createdAtIso8601,
    updatedAtIso8601,
    isDeleted,
    syncStatus,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StudySessionModel) return false;
    return listEquals(_props, other._props) &&
        listEquals(reflectionTags, other.reflectionTags) &&
        listEquals(topicsToReview, other.topicsToReview);
  }

  @override
  int get hashCode => Object.hashAll(_props);
}
