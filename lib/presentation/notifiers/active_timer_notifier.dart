import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/datasources/user_preferences_data_source.dart';
import '../../domain/entities/study_enums.dart';
import '../../domain/entities/user_preferences.dart';

enum StudyFlowPhase {
  idle,
  studying,
  breakTime,
  awaitingReflection,
}

class ActiveTimerNotifier extends ChangeNotifier {
  static const int pomodoroStudySeconds = 25 * 60;
  static const int pomodoroBreakSeconds = 5 * 60;
  static const int oneHourStudySeconds = 60 * 60;

  final UserPreferencesDataSource? preferencesDataSource;
  final DateTime Function() _clock;
  final Timer Function(Duration, void Function(Timer)) _timerFactory;

  SessionType _selectedSessionType = SessionType.pomodoro;
  int _targetPomodoroSets = 4;
  StudyFlowPhase _phase = StudyFlowPhase.idle;
  bool _isPaused = false;

  int _totalStudyElapsedSeconds = 0;
  int _currentPhaseRemainingSeconds = pomodoroStudySeconds;
  int _completedPomodoroSets = 0;
  int _currentPomodoroSet = 1;
  int _pausedSeconds = 0;
  int _pauseCount = 0;
  DateTime? _startedAt;
  DateTime? _endedAt;
  DateTime? _pauseStartedAt;
  String? _errorMessage;

  Timer? _timer;
  bool _isDisposed = false;

  ActiveTimerNotifier({
    this.preferencesDataSource,
    DateTime Function()? clock,
    Timer Function(Duration duration, void Function(Timer) callback)?
        timerFactory,
  }) : _clock = clock ?? DateTime.now,
       _timerFactory = timerFactory ??
           ((Duration d, void Function(Timer) cb) => Timer.periodic(d, cb)) {
    if (preferencesDataSource != null) {
      unawaited(loadSavedPreferences());
    }
  }

  SessionType get selectedSessionType => _selectedSessionType;
  int get targetPomodoroSets => _targetPomodoroSets;
  StudyFlowPhase get phase => _phase;
  bool get isPaused => _isPaused;
  bool get isIdle => _phase == StudyFlowPhase.idle;
  bool get isStudying => _phase == StudyFlowPhase.studying;
  bool get isOnBreak => _phase == StudyFlowPhase.breakTime;
  bool get isAwaitingReflection => _phase == StudyFlowPhase.awaitingReflection;
  bool get hasActiveSession => _phase != StudyFlowPhase.idle;
  bool get isTimerRunning =>
      (_phase == StudyFlowPhase.studying ||
          _phase == StudyFlowPhase.breakTime) &&
      !_isPaused;

  int get totalStudyElapsedSeconds => _totalStudyElapsedSeconds;
  int get currentPhaseRemainingSeconds => _currentPhaseRemainingSeconds;
  int get completedPomodoroSets => _completedPomodoroSets;
  int get currentPomodoroSet => _currentPomodoroSet;
  int get pausedSeconds => _pausedSeconds;
  int get pauseCount => _pauseCount;
  DateTime? get startedAt => _startedAt;
  DateTime? get endedAt => _endedAt;
  String? get errorMessage => _errorMessage;

  int? get targetDurationMinutes => switch (_selectedSessionType) {
    SessionType.pomodoro => _targetPomodoroSets * 25,
    SessionType.oneHour => 60,
    SessionType.freeStudy => null,
  };

  CompanionMood get companionMood {
    switch (_phase) {
      case StudyFlowPhase.idle:
        return CompanionMood.idle;
      case StudyFlowPhase.studying:
        return CompanionMood.studying;
      case StudyFlowPhase.breakTime:
        return (_completedPomodoroSets == _targetPomodoroSets - 1)
            ? CompanionMood.finalSetCheer
            : CompanionMood.breakRest;
      case StudyFlowPhase.awaitingReflection:
        return CompanionMood.proudCelebration;
    }
  }

  String get companionMessage {
    switch (_phase) {
      case StudyFlowPhase.idle:
        return 'Choose your study mode and jump right in—no setup required!';
      case StudyFlowPhase.studying:
        if (_isPaused) {
          return 'Take a breath. Resume whenever you are ready.';
        }
        if (_selectedSessionType == SessionType.pomodoro) {
          return 'Set $_currentPomodoroSet of $_targetPomodoroSets • Stay focused!';
        }
        return 'Stay focused! You will log your notes and questions at the end.';
      case StudyFlowPhase.breakTime:
        if (_completedPomodoroSets == _targetPomodoroSets - 1) {
          return 'There is one session left, you are doing a great job. Well done!';
        }
        return 'It was tiring, right? Take your time and get ready for the next session.';
      case StudyFlowPhase.awaitingReflection:
        return 'I am proud of you! I know that you will see the consequences of your studies.';
    }
  }

  static String formatHms(int totalSeconds) {
    final int s = totalSeconds < 0 ? 0 : totalSeconds;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(s ~/ 3600)}:${two((s % 3600) ~/ 60)}:${two(s % 60)}';
  }

  String get formattedTimerDisplay {
    if (_phase == StudyFlowPhase.idle) {
      return switch (_selectedSessionType) {
        SessionType.pomodoro => formatHms(pomodoroStudySeconds),
        SessionType.oneHour => formatHms(oneHourStudySeconds),
        SessionType.freeStudy => formatHms(0),
      };
    }
    if (_phase == StudyFlowPhase.breakTime) {
      return formatHms(_currentPhaseRemainingSeconds);
    }
    if (_selectedSessionType == SessionType.freeStudy) {
      return formatHms(_totalStudyElapsedSeconds);
    }
    return formatHms(_currentPhaseRemainingSeconds);
  }

  String get formattedTotalStudyTime => formatHms(_totalStudyElapsedSeconds);

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void setSelectedSessionType(SessionType type) {
    if (_phase != StudyFlowPhase.idle) return;
    _selectedSessionType = type;
    _currentPhaseRemainingSeconds = switch (type) {
      SessionType.pomodoro => pomodoroStudySeconds,
      SessionType.oneHour => oneHourStudySeconds,
      SessionType.freeStudy => 0,
    };
    _errorMessage = null;
    _safeNotify();
    unawaited(_persistTimerPreferences());
  }

  void setTargetPomodoroSets(int sets) {
    if (_phase != StudyFlowPhase.idle) return;
    _targetPomodoroSets = sets.clamp(1, 8);
    _safeNotify();
    unawaited(_persistTimerPreferences());
  }

  Future<void> loadSavedPreferences() async {
    final UserPreferencesDataSource? ds = preferencesDataSource;
    if (ds == null) return;
    try {
      final UserPreferences prefs = await ds.getPreferences();
      if (_isDisposed || _phase != StudyFlowPhase.idle) return;
      _selectedSessionType = prefs.defaultSessionType;
      _targetPomodoroSets = prefs.defaultPomodoroSets.clamp(1, 8);
      _currentPhaseRemainingSeconds = switch (_selectedSessionType) {
        SessionType.pomodoro => pomodoroStudySeconds,
        SessionType.oneHour => oneHourStudySeconds,
        SessionType.freeStudy => 0,
      };
      _safeNotify();
    } catch (_) {}
  }

  Future<void> _persistTimerPreferences() async {
    final UserPreferencesDataSource? ds = preferencesDataSource;
    if (ds == null) return;
    try {
      final UserPreferences current = await ds.getPreferences();
      await ds.savePreferences(
        current.copyWith(
          defaultSessionType: _selectedSessionType,
          defaultPomodoroSets: _targetPomodoroSets,
        ),
      );
    } catch (_) {}
  }

  bool startSession({SessionType? sessionType, int? targetPomodoroSets}) {
    if (_phase != StudyFlowPhase.idle) {
      _errorMessage = 'A study session is already active.';
      _safeNotify();
      return false;
    }
    if (sessionType != null) {
      _selectedSessionType = sessionType;
    }
    if (targetPomodoroSets != null) {
      _targetPomodoroSets = targetPomodoroSets.clamp(1, 8);
    }

    _cancelTimer();
    _errorMessage = null;
    _totalStudyElapsedSeconds = 0;
    _completedPomodoroSets = 0;
    _currentPomodoroSet = 1;
    _pausedSeconds = 0;
    _pauseCount = 0;
    _startedAt = _clock();
    _endedAt = null;
    _pauseStartedAt = null;
    _isPaused = false;
    _phase = StudyFlowPhase.studying;
    _currentPhaseRemainingSeconds = switch (_selectedSessionType) {
      SessionType.pomodoro => pomodoroStudySeconds,
      SessionType.oneHour => oneHourStudySeconds,
      SessionType.freeStudy => 0,
    };
    _startPeriodicTimer();
    _safeNotify();
    return true;
  }

  void _startPeriodicTimer() {
    _cancelTimer();
    _timer = _timerFactory(const Duration(seconds: 1), (Timer timer) {
      if (_isDisposed || !isTimerRunning) {
        timer.cancel();
        return;
      }
      _onTick();
    });
  }

  void _onTick() {
    if (_phase == StudyFlowPhase.studying) {
      _totalStudyElapsedSeconds += 1;
      if (_selectedSessionType == SessionType.freeStudy) {
        _safeNotify();
        return;
      }

      if (_currentPhaseRemainingSeconds > 0) {
        _currentPhaseRemainingSeconds -= 1;
      }

      if (_currentPhaseRemainingSeconds == 0) {
        if (_selectedSessionType == SessionType.pomodoro) {
          _completedPomodoroSets += 1;
          if (_completedPomodoroSets < _targetPomodoroSets) {
            // Transition into 5-minute Companion Break phase (no note-taking!)
            _phase = StudyFlowPhase.breakTime;
            _currentPhaseRemainingSeconds = pomodoroBreakSeconds;
            _safeNotify();
            return;
          }
        }
        // Final Pomodoro set or 1-Hour Study finished -> transition to Reflection
        _transitionToReflectionInternal();
        return;
      }
      _safeNotify();
    } else if (_phase == StudyFlowPhase.breakTime) {
      if (_currentPhaseRemainingSeconds > 0) {
        _currentPhaseRemainingSeconds -= 1;
      }
      if (_currentPhaseRemainingSeconds == 0) {
        _startNextPomodoroSetInternal();
        return;
      }
      _safeNotify();
    }
  }

  void _startNextPomodoroSetInternal() {
    _currentPomodoroSet = _completedPomodoroSets + 1;
    _phase = StudyFlowPhase.studying;
    _isPaused = false;
    _pauseStartedAt = null;
    _currentPhaseRemainingSeconds = pomodoroStudySeconds;
    _startPeriodicTimer();
    _safeNotify();
  }

  /// Allows the student to skip the remaining 5-minute break and start the next Pomodoro set immediately.
  void startNextPomodoroSet() {
    if (_phase != StudyFlowPhase.breakTime) return;
    _startNextPomodoroSetInternal();
  }

  void pauseTimer() {
    if (!isTimerRunning) return;
    _cancelTimer();
    _isPaused = true;
    if (_phase == StudyFlowPhase.studying) {
      _pauseStartedAt = _clock();
      _pauseCount += 1;
    }
    _safeNotify();
  }

  void resumeTimer() {
    if ((_phase != StudyFlowPhase.studying &&
            _phase != StudyFlowPhase.breakTime) ||
        !_isPaused) {
      return;
    }
    if (_phase == StudyFlowPhase.studying && _pauseStartedAt != null) {
      final int delta = _clock().difference(_pauseStartedAt!).inSeconds;
      if (delta > 0) _pausedSeconds += delta;
      _pauseStartedAt = null;
    }
    _isPaused = false;
    _errorMessage = null;
    _startPeriodicTimer();
    _safeNotify();
  }

  void _transitionToReflectionInternal() {
    _cancelTimer();
    if (_isPaused && _pauseStartedAt != null) {
      final int delta = _clock().difference(_pauseStartedAt!).inSeconds;
      if (delta > 0) _pausedSeconds += delta;
      _pauseStartedAt = null;
    }
    _isPaused = false;
    _endedAt = _clock();
    _phase = StudyFlowPhase.awaitingReflection;
    _safeNotify();
  }

  /// Ends the active study session and moves to the Post-Session Reflection phase.
  bool finishStudyForReflection() {
    if (_phase != StudyFlowPhase.studying &&
        _phase != StudyFlowPhase.breakTime) {
      return false;
    }
    if (_totalStudyElapsedSeconds <= 0) {
      _errorMessage =
          'Study for at least 1 second before finishing, or tap Reset to discard.';
      _safeNotify();
      return false;
    }
    _errorMessage = null;
    _transitionToReflectionInternal();
    return true;
  }

  /// Resets the timer back to idle (either after saving reflection or when discarding).
  void resetToIdle() {
    _cancelTimer();
    _phase = StudyFlowPhase.idle;
    _isPaused = false;
    _totalStudyElapsedSeconds = 0;
    _completedPomodoroSets = 0;
    _currentPomodoroSet = 1;
    _pausedSeconds = 0;
    _pauseCount = 0;
    _startedAt = null;
    _endedAt = null;
    _pauseStartedAt = null;
    _errorMessage = null;
    _currentPhaseRemainingSeconds = switch (_selectedSessionType) {
      SessionType.pomodoro => pomodoroStudySeconds,
      SessionType.oneHour => oneHourStudySeconds,
      SessionType.freeStudy => 0,
    };
    _safeNotify();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _safeNotify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelTimer();
    super.dispose();
  }
}
