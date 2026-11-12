import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/study_enums.dart';
import '../../domain/entities/user_preferences.dart';

abstract interface class UserPreferencesDataSource {
  Future<UserPreferences> getPreferences();
  Future<void> savePreferences(UserPreferences preferences);
  Future<DateTime?> getLastSyncedAt();
  Future<void> setLastSyncedAt(DateTime timestamp);
}

class SharedPreferencesUserPreferencesDataSource
    implements UserPreferencesDataSource {
  static const String keyDefaultSessionType = 'pref_default_session_type';
  static const String keyDefaultPomodoroSets = 'pref_default_pomodoro_sets';
  static const String keyFocusModeEnabled = 'pref_focus_mode_enabled';
  static const String keyTimerVisualStyle = 'pref_timer_visual_style';
  static const String keyLastSyncedAt = 'pref_last_synced_at';

  final Future<SharedPreferences> Function() _prefsProvider;
  SharedPreferences? _cachedPrefs;

  SharedPreferencesUserPreferencesDataSource({
    Future<SharedPreferences> Function()? prefsProvider,
  }) : _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  Future<SharedPreferences> _getPrefs() async =>
      _cachedPrefs ??= await _prefsProvider();

  static SessionType _parseSessionTypeSafe(String? raw) {
    if (raw == null || raw.trim().isEmpty) return SessionType.pomodoro;
    try {
      return SessionType.fromStorageString(raw);
    } on FormatException {
      return SessionType.pomodoro;
    }
  }

  static TimerVisualStyle _parseTimerStyleSafe(String? raw) {
    if (raw == null || raw.trim().isEmpty) return TimerVisualStyle.digital;
    try {
      return TimerVisualStyle.fromStorageString(raw);
    } on FormatException {
      return TimerVisualStyle.digital;
    }
  }

  static DateTime? _parseDateSafe(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim())?.toUtc();
  }

  @override
  Future<UserPreferences> getPreferences() async {
    final SharedPreferences prefs = await _getPrefs();
    final String? rawType = prefs.getString(keyDefaultSessionType);
    final int rawSets = prefs.getInt(keyDefaultPomodoroSets) ?? 4;
    final bool focusMode = prefs.getBool(keyFocusModeEnabled) ?? true;
    final String? rawStyle = prefs.getString(keyTimerVisualStyle);
    final String? rawSync = prefs.getString(keyLastSyncedAt);

    return UserPreferences(
      defaultSessionType: _parseSessionTypeSafe(rawType),
      defaultPomodoroSets: rawSets.clamp(1, 8),
      focusModeEnabled: focusMode,
      timerVisualStyle: _parseTimerStyleSafe(rawStyle),
      lastSyncedAt: _parseDateSafe(rawSync),
    );
  }

  @override
  Future<void> savePreferences(UserPreferences preferences) async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.setString(
      keyDefaultSessionType,
      preferences.defaultSessionType.name,
    );
    await prefs.setInt(
      keyDefaultPomodoroSets,
      preferences.defaultPomodoroSets.clamp(1, 8),
    );
    await prefs.setBool(keyFocusModeEnabled, preferences.focusModeEnabled);
    await prefs.setString(
      keyTimerVisualStyle,
      preferences.timerVisualStyle.name,
    );
    if (preferences.lastSyncedAt != null) {
      await prefs.setString(
        keyLastSyncedAt,
        preferences.lastSyncedAt!.toUtc().toIso8601String(),
      );
    } else {
      await prefs.remove(keyLastSyncedAt);
    }
  }

  @override
  Future<DateTime?> getLastSyncedAt() async {
    final SharedPreferences prefs = await _getPrefs();
    return _parseDateSafe(prefs.getString(keyLastSyncedAt));
  }

  @override
  Future<void> setLastSyncedAt(DateTime timestamp) async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.setString(
      keyLastSyncedAt,
      timestamp.toUtc().toIso8601String(),
    );
  }
}

class InMemoryUserPreferencesDataSource implements UserPreferencesDataSource {
  UserPreferences _preferences;

  InMemoryUserPreferencesDataSource({UserPreferences? initialPreferences})
    : _preferences = initialPreferences ?? const UserPreferences();

  @override
  Future<UserPreferences> getPreferences() async => _preferences;

  @override
  Future<void> savePreferences(UserPreferences preferences) async {
    _preferences = preferences;
  }

  @override
  Future<DateTime?> getLastSyncedAt() async => _preferences.lastSyncedAt;

  @override
  Future<void> setLastSyncedAt(DateTime timestamp) async {
    _preferences = _preferences.copyWith(lastSyncedAt: timestamp.toUtc());
  }
}
