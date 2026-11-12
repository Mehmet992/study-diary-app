import 'package:flutter/foundation.dart';

import '../../data/datasources/user_preferences_data_source.dart';
import '../../domain/entities/study_enums.dart';
import '../../domain/entities/user_preferences.dart';

class UserPreferencesNotifier extends ChangeNotifier {
  final UserPreferencesDataSource dataSource;
  UserPreferences _preferences = const UserPreferences();
  bool _isDisposed = false;

  UserPreferencesNotifier({required this.dataSource});

  UserPreferences get preferences => _preferences;
  SessionType get defaultSessionType => _preferences.defaultSessionType;
  int get defaultPomodoroSets => _preferences.defaultPomodoroSets;
  bool get focusModeEnabled => _preferences.focusModeEnabled;
  TimerVisualStyle get timerVisualStyle => _preferences.timerVisualStyle;
  DateTime? get lastSyncedAt => _preferences.lastSyncedAt;

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  Future<void> loadPreferences() async {
    try {
      _preferences = await dataSource.getPreferences();
      _safeNotify();
    } catch (_) {}
  }

  Future<void> setFocusModeEnabled(bool enabled) async {
    _preferences = _preferences.copyWith(focusModeEnabled: enabled);
    _safeNotify();
    await dataSource.savePreferences(_preferences);
  }

  Future<void> setTimerVisualStyle(TimerVisualStyle style) async {
    _preferences = _preferences.copyWith(timerVisualStyle: style);
    _safeNotify();
    await dataSource.savePreferences(_preferences);
  }

  Future<void> updateDefaultTimerSettings({
    SessionType? sessionType,
    int? pomodoroSets,
  }) async {
    _preferences = _preferences.copyWith(
      defaultSessionType: sessionType,
      defaultPomodoroSets: pomodoroSets,
    );
    _safeNotify();
    await dataSource.savePreferences(_preferences);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
