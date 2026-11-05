import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_diary_app/data/datasources/local_study_data_source.dart';
import 'package:study_diary_app/data/datasources/remote_study_data_source.dart';
import 'package:study_diary_app/data/datasources/sqlite_local_study_data_source.dart';
import 'package:study_diary_app/data/models/study_subject_model.dart';
import 'package:study_diary_app/data/repositories/in_memory_study_session_repository.dart';
import 'package:study_diary_app/data/repositories/local_motivation_repository.dart';
import 'package:study_diary_app/data/repositories/offline_first_study_session_repository.dart';
import 'package:study_diary_app/domain/entities/motivational_prompt.dart';
import 'package:study_diary_app/domain/entities/study_session.dart';
import 'package:study_diary_app/domain/entities/study_subject.dart';
import 'package:study_diary_app/domain/entities/sync_result.dart';
import 'package:study_diary_app/main.dart';
import 'package:study_diary_app/presentation/notifiers/active_timer_notifier.dart';
import 'package:study_diary_app/presentation/notifiers/study_diary_notifier.dart';

class _ControllableRemote implements RemoteStudyDataSource {
  bool online = true;
  bool failPushSessions = false;
  bool failPullSessions = false;
  Completer<void>? pushGate;
  final Map<String, StudySessionModel> remoteSessions = <String, StudySessionModel>{};
  final Map<String, StudySubjectModel> remoteSubjects = <String, StudySubjectModel>{};
  final List<String> deletedIds = <String>[];

  @override
  Future<bool> get isOnline async => online;

  @override
  Future<void> pushSessions(List<StudySessionModel> sessions) async {
    if (pushGate != null) await pushGate!.future;
    if (failPushSessions) throw Exception('pushSessions network error');
    for (final StudySessionModel s in sessions) {
      remoteSessions[s.id] = s.copyWith(syncStatus: SyncStatus.synced.name);
    }
  }

  @override
  Future<void> deleteRemoteSessions(List<String> sessionIds) async {
    for (final String id in sessionIds) {
      deletedIds.add(id);
      remoteSessions.remove(id);
    }
  }

  @override
  Future<List<StudySessionModel>> pullSessions({DateTime? since}) async {
    if (failPullSessions) throw Exception('pullSessions network error');
    return remoteSessions.values.toList(growable: false);
  }

  @override
  Future<void> pushSubjects(List<StudySubjectModel> subjects) async {
    for (final StudySubjectModel s in subjects) {
      remoteSubjects[s.id] = s.copyWith(syncStatus: SyncStatus.synced.name);
    }
  }

  @override
  Future<List<StudySubjectModel>> pullSubjects({DateTime? since}) async =>
      remoteSubjects.values.toList(growable: false);
}

class _FakeTimer implements Timer {
  final void Function(Timer) cb;
  bool _active = true;
  int _tick = 0;
  _FakeTimer(this.cb);

  void fire([int n = 1]) {
    for (int i = 0; i < n && _active; i++) {
      _tick += 1;
      cb(this);
    }
  }

  @override
  void cancel() => _active = false;
  @override
  bool get isActive => _active;
  @override
  int get tick => _tick;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final DateTime t0 = DateTime.utc(2026, 10, 31, 9, 0);
  final DateTime t1 = DateTime.utc(2026, 10, 31, 10, 30);

  group('1. Domain Enums & Entities', () {
    test('Enums including SessionType expose labels, defaults, and storage parsing', () {
      expect(SessionType.freeStudy.displayLabel, 'Free Study');
      expect(SessionType.freeStudy.defaultMinutes, isNull);
      expect(SessionType.pomodoro.displayLabel, 'Pomodoro');
      expect(SessionType.pomodoro.defaultMinutes, 25);
      expect(SessionType.pomodoro.breakMinutes, 5);
      expect(SessionType.oneHour.displayLabel, '1 Hour Study');
      expect(SessionType.oneHour.defaultMinutes, 60);

      for (final SessionType t in SessionType.values) {
        expect(SessionType.fromStorageString(' ${t.name} '), t);
      }
      for (final StudyActivityType a in StudyActivityType.values) {
        expect(StudyActivityType.fromStorageString(' ${a.name} '), a);
      }
      for (final ReflectionTag r in ReflectionTag.values) {
        expect(ReflectionTag.fromStorageString(' ${r.name} '), r);
      }
      expect(() => SessionType.fromStorageString('sprint'), throwsFormatException);
      expect(() => SessionStatus.fromStorageString('bad'), throwsFormatException);
      expect(() => SyncStatus.fromStorageString('bad'), throwsFormatException);
      expect(() => PromptCategory.fromStorageString('bad'), throwsFormatException);
    });

    test('StudySubject, StudySession (with AI reflection & question metrics), StudySummary, Prompt & SyncResult invariants', () {
      final StudySubject sub = StudySubject.validated(
        id: ' s1 ', userId: ' ', name: ' Algebra ', colorHex: ' #FF3F51B5 ',
        createdAt: t0, updatedAt: t1,
      );
      expect(sub.id, 's1');
      expect(sub.userId, isNull);
      expect(sub.copyWith(userId: 'u1').copyWith(clearUserId: true), equals(sub));
      expect(() => StudySubject.validated(id: '', name: 'A', createdAt: t0), throwsA(isA<StudySubjectValidationException>()));
      expect(() => StudySubject.validated(id: '1', name: 'A', colorHex: 'bad', createdAt: t0), throwsA(isA<StudySubjectValidationException>()));

      final StudySession pomo = StudySession.validated(
        id: 'p1',
        subject: 'Physics',
        sessionType: SessionType.pomodoro,
        activityType: StudyActivityType.questionSolving,
        startedAt: t0,
        elapsedSeconds: 1800,
        pauseCount: 1,
        completedPomodoroSets: 2,
        targetPomodoroSets: 4,
        correctCount: 32,
        wrongCount: 4,
        blankCount: 4,
        reflectionTags: const <ReflectionTag>[ReflectionTag.carelessMistakes],
        topicsToReview: const <String>['Optics', 'Waves', 'optics'],
        focusRating: 5,
      );
      expect(pomo.sessionType, SessionType.pomodoro);
      expect(pomo.targetDurationMinutes, 100);
      expect(pomo.durationMinutes, 30);
      expect(pomo.totalQuestions, 40);
      expect(pomo.netScore, 31.0);
      expect(pomo.secondsPerQuestion, 45.0);
      expect(pomo.topicsToReview, const <String>['Optics', 'Waves']);
      expect(pomo.copyWith(sessionType: SessionType.oneHour), isNot(equals(pomo)));
      expect(pomo.copyWith(), equals(pomo));
      expect(pomo.copyWith().hashCode, equals(pomo.hashCode));

      for (final StudySession Function() bad in <StudySession Function()>[
        () => StudySession.validated(id: ' ', subject: 'M', startedAt: t0, elapsedSeconds: 60),
        () => StudySession.validated(id: '1', subject: ' ', startedAt: t0, elapsedSeconds: 60),
        () => StudySession.validated(id: '1', subject: 'M', elapsedSeconds: 60),
        () => StudySession.validated(id: '1', subject: 'M', startedAt: t0, elapsedSeconds: 0),
        () => StudySession.validated(id: '1', subject: 'M', startedAt: t0, elapsedSeconds: 60, pausedSeconds: -1),
        () => StudySession.validated(id: '1', subject: 'M', startedAt: t0, elapsedSeconds: 60, targetDurationMinutes: 0),
        () => StudySession.validated(id: '1', subject: 'M', startedAt: t0, elapsedSeconds: 60, correctCount: -1),
        () => StudySession.validated(id: '1', subject: 'M', startedAt: t0, elapsedSeconds: 60, focusRating: 6),
        () => StudySession.validated(id: '1', subject: 'M', startedAt: t1, endedAt: t0, elapsedSeconds: 60),
        () => StudySession.validated(id: '1', subject: 'M', startedAt: t0, elapsedSeconds: 60, createdAt: t1, updatedAt: t0),
      ]) {
        expect(bad, throwsA(isA<StudySessionValidationException>()));
      }

      final DateTime today = DateTime(2026, 10, 31, 14);
      final StudySummary sum = StudySummary.fromSessions(<StudySession>[
        StudySession.validated(
          id: '1',
          subject: 'M',
          startedAt: today,
          elapsedSeconds: 1500,
          pauseCount: 2,
          correctCount: 20,
          wrongCount: 4,
          topicsToReview: const <String>['Derivatives'],
        ),
        StudySession.validated(id: '2', subject: 'C', startedAt: today, elapsedSeconds: 900, isDeleted: true),
        StudySession.validated(id: '3', subject: 'B', status: SessionStatus.running, startedAt: today, elapsedSeconds: 300),
      ], referenceDate: today);
      expect(sum.sessionCount, 1);
      expect(sum.todayMinutes, 25);
      expect(sum.totalPauses, 2);
      expect(sum.totalQuestionsSolved, 24);
      expect(sum.totalNetScore, 19.0);
      expect(sum.topicsToReview, const <String>['Derivatives']);

      expect(MotivationalPrompt.validated(id: 'p', text: 'Go', authorOrOrigin: 'A', category: PromptCategory.quote).categoryLabel, 'Quote');
      expect(const SyncResult.offline().isOffline, isTrue);
      expect(const SyncResult(errorMessage: 'err').isSuccess, isFalse);
    });
  });

  group('2. DTO Serialization & Legacy Migration', () {
    test('StudySubjectModel and StudySessionModel round-trip, default missing sessionType, and reject bad types', () {
      final StudySubjectModel sm = StudySubjectModel.fromEntity(
        StudySubject.validated(id: 'sub1', name: 'Calc', createdAt: t0, updatedAt: t1),
      );
      expect(StudySubjectModel.fromMap(sm.toMap()).toEntity().name, 'Calc');
      expect(() => StudySubjectModel.fromMap(const <String, Object?>{}), throwsFormatException);

      final StudySessionModel legacy = StudySessionModel.fromMap(<String, Object?>{
        'id': 'leg-1',
        'subject': 'History',
        'durationMinutes': 30,
        'timestamp': t0.toIso8601String(),
      });
      expect(legacy.sessionType, 'freeStudy');
      expect(legacy.toEntity().sessionType, SessionType.freeStudy);
      expect(legacy.elapsedSeconds, 1800);

      final StudySession deep = StudySession.validated(
        id: 'dw-1', subject: 'Algorithms', sessionType: SessionType.oneHour,
        startedAt: t0, endedAt: t1, elapsedSeconds: 3600, syncStatus: SyncStatus.pendingSync,
      );
      final StudySessionModel dm = StudySessionModel.fromEntity(deep);
      expect(dm.toMap()['sessionType'], 'oneHour');
      expect(StudySessionModel.fromMap(dm.toMap()).toEntity(), equals(deep));
      expect(dm.copyWith(elapsedSeconds: 65).durationMinutes, 2);

      expect(
        () => StudySessionModel.fromMap(<String, Object?>{...dm.toMap(), 'sessionType': 42}),
        throwsFormatException,
      );
      expect(
        () => StudySessionModel.fromMap(<String, Object?>{...dm.toMap(), 'sessionType': 'unknownMode'}),
        throwsFormatException,
      );
    });
  });

  group('3. SQLite (sqflite) Local Persistence & Sync Repository', () {
    test('SqliteLocalStudyDataSource persists sessions with AI reflection fields, subjects, and handles path errors', () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final Directory tempDir = await Directory.systemTemp.createTemp('study_sqlite_ds_');
      const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
      bool failChannel = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            if (call.method == 'getApplicationDocumentsDirectory') {
              if (failChannel) throw PlatformException(code: 'IO_ERR');
              return tempDir.path;
            }
            return null;
          });

      final SqliteLocalStudyDataSource ds = SqliteLocalStudyDataSource();
      addTearDown(() async {
        await ds.close();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });

      expect(await ds.getAllSessionModels(), isEmpty);
      expect(await ds.getAllSubjectModels(), isEmpty);

      await ds.upsertSubjectModel(
        StudySubjectModel.fromEntity(
          StudySubject.validated(
            id: 'sub-math',
            name: 'Mathematics',
            colorHex: '#3F51B5',
            createdAt: t0,
            updatedAt: t1,
          ),
        ),
      );
      final List<StudySubjectModel> subjects = await ds.getAllSubjectModels();
      expect(subjects.single.name, 'Mathematics');

      await Future.wait(<Future<void>>[
        for (int i = 0; i < 5; i++)
          ds.upsertSessionModel(
            StudySessionModel.fromEntity(
              StudySession.validated(
                id: 's-$i',
                subject: 'Sub $i',
                topic: 'Topic $i',
                activityType: StudyActivityType.questionSolving,
                sessionType: SessionType.pomodoro,
                startedAt: t0.add(Duration(minutes: i)),
                elapsedSeconds: 1500,
                completedPomodoroSets: 2,
                targetPomodoroSets: 4,
                correctCount: 20 + i,
                wrongCount: 4,
                blankCount: 1,
                reflectionTags: const <ReflectionTag>[
                  ReflectionTag.understoodWell,
                  ReflectionTag.carelessMistakes,
                ],
                topicsToReview: const <String>['Limits', 'Continuity'],
              ),
            ),
          ),
      ]);
      await ds.hardDeleteSessionModel('s-2');
      await ds.close();

      final File dbFile = File('${tempDir.path}/study_diary.db');
      expect(await dbFile.exists(), isTrue);

      final SqliteLocalStudyDataSource reloadedDs = SqliteLocalStudyDataSource();
      final List<StudySessionModel> reloaded = await reloadedDs.getAllSessionModels();
      await reloadedDs.close();

      expect(reloaded.length, 4);
      final StudySession firstEntity = reloaded.first.toEntity();
      expect(firstEntity.sessionType, SessionType.pomodoro);
      expect(firstEntity.activityType, StudyActivityType.questionSolving);
      expect(firstEntity.completedPomodoroSets, 2);
      expect(firstEntity.targetPomodoroSets, 4);
      expect(firstEntity.correctCount, 24);
      expect(firstEntity.wrongCount, 4);
      expect(firstEntity.blankCount, 1);
      expect(firstEntity.netScore, 23.0);
      expect(
        firstEntity.reflectionTags,
        const <ReflectionTag>[
          ReflectionTag.understoodWell,
          ReflectionTag.carelessMistakes,
        ],
      );
      expect(firstEntity.topicsToReview, const <String>['Limits', 'Continuity']);

      failChannel = true;
      final SqliteLocalStudyDataSource failingDs = SqliteLocalStudyDataSource();
      await expectLater(
        failingDs.getAllSessionModels(),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('OfflineFirstStudySessionRepository preserves SessionType, syncs tombstones/merges, and guards mid-sync edits', () async {
      expect(await const OfflineRemoteStudyDataSource().isOnline, isFalse);
      expect(await InMemoryStudySessionRepository().syncSessions(), const SyncResult.offline());

      final InMemoryLocalStudyDataSource local = InMemoryLocalStudyDataSource();
      final _ControllableRemote remote = _ControllableRemote()..online = false;
      final OfflineFirstStudySessionRepository repo = OfflineFirstStudySessionRepository(
        localDataSource: local, remoteDataSource: remote,
      );

      await repo.addSession(StudySession.validated(
        id: 'k1', subject: 'Rust', sessionType: SessionType.oneHour, startedAt: t0, elapsedSeconds: 3600,
      ));
      await repo.addSession(StudySession.validated(
        id: 'd1', subject: 'C', startedAt: t1, elapsedSeconds: 600,
      ));
      await repo.deleteSession('d1');
      expect((await repo.getSessions()).single.sessionType, SessionType.oneHour);
      expect(await repo.syncSessions(), const SyncResult.offline());

      remote.online = true;
      remote.failPushSessions = true;
      expect((await repo.syncSessions()).isSuccess, isFalse);
      expect((await repo.getSessions()).single.syncStatus, SyncStatus.syncFailed);

      remote.failPushSessions = false;
      remote.remoteSessions['r1'] = StudySessionModel.fromEntity(StudySession.validated(
        id: 'r1', subject: 'Go', sessionType: SessionType.pomodoro,
        startedAt: t1.add(const Duration(hours: 1)), elapsedSeconds: 1500, syncStatus: SyncStatus.synced,
      ));
      final SyncResult ok = await repo.syncSessions();
      expect(ok.isSuccess, isTrue);
      expect(ok.pushedCount, 1);
      expect(ok.deletedCount, 1);
      expect(ok.pulledCount, 1);

      // Mid-sync local edit protection
      await repo.addSession(StudySession.validated(
        id: 'c1', subject: 'AI', startedAt: t0, elapsedSeconds: 600, createdAt: t0, updatedAt: t0,
      ));
      final Completer<void> gate = Completer<void>();
      remote.pushGate = gate;
      final Future<SyncResult> inflight = repo.syncSessions();
      await Future<void>.delayed(Duration.zero);
      await repo.addSession(StudySession.validated(
        id: 'c1', subject: 'AI', notes: 'Edited locally', startedAt: t0, elapsedSeconds: 1200, createdAt: t0, updatedAt: t1,
      ));
      gate.complete();
      await inflight;

      final StudySession kept = (await repo.getSessions()).firstWhere((StudySession s) => s.id == 'c1');
      expect(kept.notes, 'Edited locally');
      expect(kept.syncStatus, SyncStatus.pendingSync);
    });
  });

  group('4. Motivation, ActiveTimerNotifier & StudyDiaryNotifier', () {
    test('ActiveTimerNotifier & StudyDiaryNotifier drive zero-friction Pomodoro breaks, companion messages, and AI reflection save', () async {
      final LocalMotivationRepository mRepo = LocalMotivationRepository();
      expect(mRepo.getNextPrompt(currentPromptId: mRepo.getInitialPrompt().id), isNot(equals(mRepo.getInitialPrompt())));

      DateTime now = DateTime(2026, 10, 31, 9);
      _FakeTimer? fakeTimer;
      final ActiveTimerNotifier timerN = ActiveTimerNotifier(
        clock: () => now,
        timerFactory: (Duration _, void Function(Timer) cb) =>
            fakeTimer = _FakeTimer(cb),
      );
      final StudyDiaryNotifier diaryN = StudyDiaryNotifier(
        repository: InMemoryStudySessionRepository(),
        clock: () => now,
      );
      addTearDown(() {
        timerN.dispose();
        diaryN.dispose();
      });

      // Default is Pomodoro with 4 sets, 00:25:00 display, idle companion mood
      expect(timerN.selectedSessionType, SessionType.pomodoro);
      expect(timerN.targetPomodoroSets, 4);
      expect(timerN.formattedTimerDisplay, '00:25:00');
      expect(timerN.companionMood, CompanionMood.idle);

      // Configure 3 Pomodoro sets to test:
      // Set 1 -> normal break -> Set 2 -> penultimate break ('one session left') -> Set 3 -> proud completion
      timerN.setTargetPomodoroSets(3);
      expect(timerN.startSession(), isTrue);
      expect(timerN.phase, StudyFlowPhase.studying);
      expect(timerN.currentPomodoroSet, 1);

      // Finish Set 1 (25 min = 1500s)
      fakeTimer!.fire(1500);
      now = now.add(const Duration(minutes: 25));
      expect(timerN.phase, StudyFlowPhase.breakTime);
      expect(timerN.completedPomodoroSets, 1);
      expect(timerN.companionMood, CompanionMood.breakRest);
      expect(
        timerN.companionMessage,
        'It was tiring, right? Take your time and get ready for the next session.',
      );
      expect(timerN.formattedTimerDisplay, '00:05:00');

      // Finish 5-min break (300s) -> automatically starts Set 2
      fakeTimer!.fire(300);
      now = now.add(const Duration(minutes: 5));
      expect(timerN.phase, StudyFlowPhase.studying);
      expect(timerN.currentPomodoroSet, 2);

      // Finish Set 2 (1500s) -> penultimate break (1 session left!)
      fakeTimer!.fire(1500);
      now = now.add(const Duration(minutes: 25));
      expect(timerN.phase, StudyFlowPhase.breakTime);
      expect(timerN.completedPomodoroSets, 2);
      expect(timerN.companionMood, CompanionMood.finalSetCheer);
      expect(
        timerN.companionMessage,
        'There is one session left, you are doing a great job. Well done!',
      );

      // Skip remaining break early and start final Set 3
      timerN.startNextPomodoroSet();
      expect(timerN.phase, StudyFlowPhase.studying);
      expect(timerN.currentPomodoroSet, 3);

      // Finish Set 3 (1500s) -> transitions to awaitingReflection with proud celebration!
      fakeTimer!.fire(1500);
      now = now.add(const Duration(minutes: 25));
      expect(timerN.phase, StudyFlowPhase.awaitingReflection);
      expect(timerN.completedPomodoroSets, 3);
      expect(timerN.totalStudyElapsedSeconds, 4500);
      expect(timerN.companionMood, CompanionMood.proudCelebration);
      expect(
        timerN.companionMessage,
        'I am proud of you! I know that you will see the consequences of your studies.',
      );

      // Save Post-Session Reflection via StudyDiaryNotifier
      final bool saved = await diaryN.saveSession(
        subject: 'AYT Mathematics',
        topic: 'Integrals',
        activityType: StudyActivityType.questionSolving,
        sessionType: timerN.selectedSessionType,
        elapsedSeconds: timerN.totalStudyElapsedSeconds,
        completedPomodoroSets: timerN.completedPomodoroSets,
        targetPomodoroSets: timerN.targetPomodoroSets,
        correctCount: 36,
        wrongCount: 4,
        blankCount: 0,
        reflectionTags: const <ReflectionTag>[ReflectionTag.understoodWell],
        topicsToReview: const <String>['Definite Integral Area'],
        startedAt: timerN.startedAt,
        endedAt: timerN.endedAt,
      );
      expect(saved, isTrue);
      timerN.resetToIdle();
      expect(timerN.isIdle, isTrue);

      expect(diaryN.sessions.length, 1);
      expect(diaryN.summary.totalQuestionsSolved, 40);
      expect(diaryN.summary.totalNetScore, 35.0);
      expect(diaryN.summary.topicsToReview, const <String>['Definite Integral Area']);

      // Mark review topic as resolved
      expect(await diaryN.markReviewTopicResolved('Definite Integral Area'), isTrue);
      expect(diaryN.summary.topicsToReview, isEmpty);
    });
  });

  group('5. 3-Tab Navigation Shell, Distraction-Free Study & AI Post-Session Reflection UI', () {
    testWidgets('Runs 1 Hour Study countdown, logs question-solving reflection with Net score & review topics, and resolves topic on Dashboard', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const StudyDiaryApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bottomNavBar')), findsOneWidget);
      expect(find.byKey(const Key('activeSessionBanner')), findsNothing);

      // Switch to Study tab via bottom NavigationBar
      await tester.tap(find.byKey(const Key('studyTab')));
      await tester.pumpAndSettle();

      // Select 1 Hour Study mode card
      await tester.ensureVisible(find.byKey(const ValueKey<String>('modeCard_oneHour')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('modeCard_oneHour')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(const Key('timerDisplayText'))).data,
        '01:00:00',
      );

      // Start immediately — no upfront subject field needed!
      await tester.tap(find.byKey(const Key('startTimerButton')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 65));
      expect(
        tester.widget<Text>(find.byKey(const Key('timerDisplayText'))).data,
        '00:58:55',
      );

      // Pause and switch to Dashboard tab -> activeSessionBanner reflects 1 Hour Study & countdown
      await tester.tap(find.byKey(const Key('pauseTimerButton')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('dashboardTab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('activeSessionBanner')), findsOneWidget);
      expect(find.textContaining('1 Hour Study • 00:58:55'), findsOneWidget);

      // Tap banner to jump back to Study tab, resume 10s, then Finish & Take Notes
      await tester.tap(find.byKey(const Key('activeSessionBanner')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('resumeTimerButton')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));

      await tester.tap(find.byKey(const Key('finishStudyButton')));
      await tester.pumpAndSettle();

      // Now in Post-Session Reflection phase: enter Subject, Question Solving metrics, and review topic
      await tester.enterText(find.byKey(const Key('reflectionSubjectField')), 'Linear Algebra');
      await tester.enterText(find.byKey(const Key('reflectionTopicField')), 'Eigenvalues');

      await tester.tap(find.byKey(const ValueKey<String>('activityType_questionSolving')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('correctCountField')), '20');
      await tester.enterText(find.byKey(const Key('wrongCountField')), '4');
      await tester.enterText(find.byKey(const Key('blankCountField')), '1');
      await tester.pump();

      expect(find.text('Total: 25 questions • Net: 19.00'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('topicsToReviewField')), 'Diagonalization');
      await tester.ensureVisible(find.byKey(const Key('saveReflectionButton')));
      await tester.tap(find.byKey(const Key('saveReflectionButton')));
      await tester.pumpAndSettle();

      // Check Dashboard for Topics to Look After & Question/Net metrics
      await tester.tap(find.byKey(const Key('dashboardTab')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('topicsToReviewCard')), findsOneWidget);
      expect(find.text('Diagonalization'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('totalQuestionsText'))).data, '25');
      expect(tester.widget<Text>(find.byKey(const Key('totalNetScoreText'))).data, '19.00');

      // Tap review topic chip to resolve it
      await tester.tap(find.byKey(const ValueKey<String>('resolveTopic_Diagonalization')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('topicsToReviewCard')), findsNothing);

      // Switch to Diary tab to inspect and delete the logged session
      await tester.tap(find.byKey(const Key('diaryTab')));
      await tester.pumpAndSettle();
      expect(find.text('Linear Algebra • Eigenvalues'), findsOneWidget);
      expect(find.textContaining('25 Q (20C / 4W) • Net: 19.00'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete session'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('emptyStateText')), findsOneWidget);
    });

    testWidgets('Handles sync badge states, manual session sheet on Diary tab, and 320x480 compact screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final _ControllableRemote remote = _ControllableRemote()..online = true;
      final OfflineFirstStudySessionRepository repo = OfflineFirstStudySessionRepository(
        localDataSource: InMemoryLocalStudyDataSource(), remoteDataSource: remote,
      );

      await tester.pumpWidget(StudyDiaryApp(repository: repo));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('syncStatusBadge')));
      await tester.pumpAndSettle();
      expect(find.text('Synced'), findsOneWidget);

      remote.failPullSessions = true;
      await tester.tap(find.byKey(const Key('syncStatusBadge')));
      await tester.pumpAndSettle();
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.byKey(const Key('dashboardErrorBanner')), findsOneWidget);

      // Switch to Diary tab and test manual log validation + dismissal
      await tester.tap(find.byKey(const Key('diaryTab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('logPastSessionButton')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('saveReflectionButton')));
      await tester.tap(find.byKey(const Key('saveReflectionButton')));
      await tester.pumpAndSettle();
      expect(find.text('Subject must not be empty.'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('discardSessionButton')));
      await tester.tap(find.byKey(const Key('discardSessionButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reflectionErrorBanner')), findsNothing);
    });
  });
}
