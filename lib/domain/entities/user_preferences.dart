import 'study_enums.dart';

class UserPreferences {
  final SessionType defaultSessionType;
  final int defaultPomodoroSets;
  final bool focusModeEnabled;
  final TimerVisualStyle timerVisualStyle;
  final DateTime? lastSyncedAt;

  const UserPreferences({
    this.defaultSessionType = SessionType.pomodoro,
    int defaultPomodoroSets = 4,
    this.focusModeEnabled = true,
    this.timerVisualStyle = TimerVisualStyle.digital,
    this.lastSyncedAt,
  }) : defaultPomodoroSets = defaultPomodoroSets < 1
           ? 1
           : (defaultPomodoroSets > 8 ? 8 : defaultPomodoroSets);

  UserPreferences copyWith({
    SessionType? defaultSessionType,
    int? defaultPomodoroSets,
    bool? focusModeEnabled,
    TimerVisualStyle? timerVisualStyle,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
  }) {
    return UserPreferences(
      defaultSessionType: defaultSessionType ?? this.defaultSessionType,
      defaultPomodoroSets: defaultPomodoroSets ?? this.defaultPomodoroSets,
      focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
      timerVisualStyle: timerVisualStyle ?? this.timerVisualStyle,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreferences &&
          other.defaultSessionType == defaultSessionType &&
          other.defaultPomodoroSets == defaultPomodoroSets &&
          other.focusModeEnabled == focusModeEnabled &&
          other.timerVisualStyle == timerVisualStyle &&
          other.lastSyncedAt == lastSyncedAt);

  @override
  int get hashCode => Object.hash(
    defaultSessionType,
    defaultPomodoroSets,
    focusModeEnabled,
    timerVisualStyle,
    lastSyncedAt,
  );
}
