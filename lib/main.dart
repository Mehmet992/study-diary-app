import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/datasources/local_study_data_source.dart';
import 'data/datasources/remote_study_data_source.dart';
import 'data/datasources/sqlite_local_study_data_source.dart';
import 'data/datasources/user_preferences_data_source.dart';
import 'data/repositories/offline_first_study_session_repository.dart';
import 'domain/repositories/motivation_repository.dart';
import 'domain/repositories/study_session_repository.dart';
import 'presentation/notifiers/active_timer_notifier.dart';
import 'presentation/notifiers/study_diary_notifier.dart';
import 'presentation/notifiers/user_preferences_notifier.dart';
import 'presentation/screens/main_shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final UserPreferencesDataSource preferencesDataSource =
      SharedPreferencesUserPreferencesDataSource();
  final StudySessionRepository repository = OfflineFirstStudySessionRepository(
    localDataSource: SqliteLocalStudyDataSource(),
    remoteDataSource: const OfflineRemoteStudyDataSource(),
    preferencesDataSource: preferencesDataSource,
  );
  runApp(
    StudyDiaryApp(
      repository: repository,
      preferencesDataSource: preferencesDataSource,
    ),
  );
}

class StudyDiaryApp extends StatefulWidget {
  final StudySessionRepository? repository;
  final MotivationRepository? motivationRepository;
  final UserPreferencesDataSource? preferencesDataSource;

  const StudyDiaryApp({
    super.key,
    this.repository,
    this.motivationRepository,
    this.preferencesDataSource,
  });

  @override
  State<StudyDiaryApp> createState() => _StudyDiaryAppState();
}

class _StudyDiaryAppState extends State<StudyDiaryApp> {
  late UserPreferencesDataSource _resolvedPreferencesDataSource;
  late StudySessionRepository _resolvedRepository;
  late ActiveTimerNotifier _timerNotifier;
  late StudyDiaryNotifier _diaryNotifier;
  late UserPreferencesNotifier _preferencesNotifier;

  void _initNotifiers() {
    _resolvedPreferencesDataSource =
        widget.preferencesDataSource ?? InMemoryUserPreferencesDataSource();
    _resolvedRepository =
        widget.repository ??
        OfflineFirstStudySessionRepository(
          localDataSource: InMemoryLocalStudyDataSource(),
          remoteDataSource: const OfflineRemoteStudyDataSource(),
          preferencesDataSource: _resolvedPreferencesDataSource,
        );
    _timerNotifier = ActiveTimerNotifier(
      preferencesDataSource: _resolvedPreferencesDataSource,
    );
    _diaryNotifier = StudyDiaryNotifier(
      repository: _resolvedRepository,
      motivationRepository: widget.motivationRepository,
    );
    _preferencesNotifier = UserPreferencesNotifier(
      dataSource: _resolvedPreferencesDataSource,
    );
    unawaited(_preferencesNotifier.loadPreferences());
  }

  @override
  void initState() {
    super.initState();
    _initNotifiers();
  }

  @override
  void didUpdateWidget(covariant StudyDiaryApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.motivationRepository != widget.motivationRepository ||
        oldWidget.preferencesDataSource != widget.preferencesDataSource) {
      _timerNotifier.dispose();
      _diaryNotifier.dispose();
      _preferencesNotifier.dispose();
      _initNotifiers();
    }
  }

  @override
  void dispose() {
    _timerNotifier.dispose();
    _diaryNotifier.dispose();
    _preferencesNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<ActiveTimerNotifier>.value(
          value: _timerNotifier,
        ),
        ChangeNotifierProvider<StudyDiaryNotifier>.value(
          value: _diaryNotifier,
        ),
        ChangeNotifierProvider<UserPreferencesNotifier>.value(
          value: _preferencesNotifier,
        ),
      ],
      child: MaterialApp(
        title: 'Study Diary',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: MainShellScreen(
          timerNotifier: _timerNotifier,
          diaryNotifier: _diaryNotifier,
        ),
      ),
    );
  }
}

class MyApp extends StudyDiaryApp {
  const MyApp({
    super.key,
    super.repository,
    super.motivationRepository,
    super.preferencesDataSource,
  });
}
