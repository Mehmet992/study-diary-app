T _parseEnum<T extends Enum>(List<T> values, String raw, String typeName) {
  final String normalized = raw.trim();
  for (final T item in values) {
    if (item.name == normalized) return item;
  }
  throw FormatException('Unknown $typeName value: "$raw".');
}

enum SessionStatus {
  running,
  paused,
  completed,
  abandoned;

  static SessionStatus fromStorageString(String value) =>
      _parseEnum(SessionStatus.values, value, 'SessionStatus');
}

enum SyncStatus {
  localOnly,
  pendingSync,
  synced,
  pendingDelete,
  syncFailed;

  static SyncStatus fromStorageString(String value) =>
      _parseEnum(SyncStatus.values, value, 'SyncStatus');
}

enum PromptCategory {
  encouragement('Encouragement'),
  idiom('Idiom'),
  quote('Quote');

  final String displayLabel;
  const PromptCategory(this.displayLabel);

  static PromptCategory fromStorageString(String value) =>
      _parseEnum(PromptCategory.values, value, 'PromptCategory');
}

enum SessionType {
  pomodoro(
    displayLabel: 'Pomodoro',
    subtitle: '25m study • 5m break sets',
    defaultMinutes: 25,
    breakMinutes: 5,
  ),
  freeStudy(
    displayLabel: 'Free Study',
    subtitle: 'Open-ended stopwatch',
    defaultMinutes: null,
    breakMinutes: null,
  ),
  oneHour(
    displayLabel: '1 Hour Study',
    subtitle: 'Strict 60m countdown',
    defaultMinutes: 60,
    breakMinutes: null,
  );

  final String displayLabel;
  final String subtitle;
  final int? defaultMinutes;
  final int? breakMinutes;

  const SessionType({
    required this.displayLabel,
    required this.subtitle,
    required this.defaultMinutes,
    required this.breakMinutes,
  });

  static SessionType fromStorageString(String value) {
    final String normalized = value.trim();
    if (normalized == 'deepWork') return SessionType.oneHour;
    if (normalized == 'quickReview') return SessionType.pomodoro;
    return _parseEnum(SessionType.values, normalized, 'SessionType');
  }
}

enum StudyActivityType {
  topicStudy('Topic Study'),
  questionSolving('Question Solving'),
  mockExam('Mock Exam');

  final String displayLabel;
  const StudyActivityType(this.displayLabel);

  bool get hasQuestions =>
      this == StudyActivityType.questionSolving ||
      this == StudyActivityType.mockExam;

  static StudyActivityType fromStorageString(String value) =>
      _parseEnum(StudyActivityType.values, value, 'StudyActivityType');
}

enum ReflectionTag {
  understoodWell('Understood Well'),
  needMorePractice('Need More Practice'),
  carelessMistakes('Careless Mistakes'),
  timePressure('Time Pressure'),
  conceptGap('Concept Gap');

  final String displayLabel;
  const ReflectionTag(this.displayLabel);

  static ReflectionTag fromStorageString(String value) =>
      _parseEnum(ReflectionTag.values, value, 'ReflectionTag');
}

enum CompanionMood {
  idle,
  studying,
  breakRest,
  finalSetCheer,
  proudCelebration,
}
