import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/datasources/local_study_data_source.dart';
import 'data/datasources/remote_study_data_source.dart';
import 'data/datasources/sqlite_local_study_data_source.dart';
import 'data/repositories/offline_first_study_session_repository.dart';
import 'domain/repositories/motivation_repository.dart';
import 'domain/repositories/study_session_repository.dart';
import 'presentation/notifiers/active_timer_notifier.dart';
import 'presentation/notifiers/study_diary_notifier.dart';
import 'presentation/screens/main_shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final StudySessionRepository repository = OfflineFirstStudySessionRepository(
    localDataSource: SqliteLocalStudyDataSource(),
    remoteDataSource: const OfflineRemoteStudyDataSource(),
  );
  runApp(StudyDiaryApp(repository: repository));
}

class StudyDiaryApp extends StatefulWidget {
  final StudySessionRepository? repository;
  final MotivationRepository? motivationRepository;

  const StudyDiaryApp({
    super.key,
    this.repository,
    this.motivationRepository,
  });

  @override
  State<StudyDiaryApp> createState() => _StudyDiaryAppState();
}

class _StudyDiaryAppState extends State<StudyDiaryApp> {
  late StudySessionRepository _resolvedRepository;
  late ActiveTimerNotifier _timerNotifier;
  late StudyDiaryNotifier _diaryNotifier;

  void _initNotifiers() {
    _resolvedRepository =
        widget.repository ??
        OfflineFirstStudySessionRepository(
          localDataSource: InMemoryLocalStudyDataSource(),
          remoteDataSource: const OfflineRemoteStudyDataSource(),
        );
    _timerNotifier = ActiveTimerNotifier();
    _diaryNotifier = StudyDiaryNotifier(
      repository: _resolvedRepository,
      motivationRepository: widget.motivationRepository,
    );
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
        oldWidget.motivationRepository != widget.motivationRepository) {
      _timerNotifier.dispose();
      _diaryNotifier.dispose();
      _initNotifiers();
    }
  }

  @override
  void dispose() {
    _timerNotifier.dispose();
    _diaryNotifier.dispose();
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
  });
}
