import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_diary_app/main.dart';

void main() {
  testWidgets(
    'MyApp smoke test: 3-tab navigation, zero-friction study start, and post-session reflection',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bottomNavBar')), findsOneWidget);
      expect(find.byKey(const Key('dashboardTab')), findsOneWidget);
      expect(find.byKey(const Key('studyTab')), findsOneWidget);
      expect(find.byKey(const Key('diaryTab')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('totalMinutesText'))).data,
        '0 min',
      );

      // Cycle motivational prompt on Dashboard
      final String firstPrompt =
          tester.widget<Text>(find.byKey(const Key('promptText'))).data ?? '';
      await tester.tap(find.byKey(const Key('nextPromptButton')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('promptText'))).data,
        isNot(equals(firstPrompt)),
      );

      // Jump to Study tab — zero text inputs before starting!
      await tester.tap(find.byKey(const Key('openStudyPageButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reflectionSubjectField')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('timerDisplayText'))).data,
        '00:25:00',
      );

      // Start Pomodoro immediately with 1 tap
      await tester.tap(find.byKey(const Key('startTimerButton')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 65));
      expect(
        tester.widget<Text>(find.byKey(const Key('timerDisplayText'))).data,
        '00:23:55',
      );

      // Finish & Take Notes -> Post-Session Reflection appears with proud companion message
      await tester.tap(find.byKey(const Key('finishStudyButton')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'I am proud of you! I know that you will see the consequences of your studies.',
        ),
        findsOneWidget,
      );

      // Tap 1-tap subject chip & Save Session
      await tester.tap(find.byKey(const ValueKey<String>('subjectChip_TYT Mathematics')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('saveReflectionButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('saveReflectionButton')));
      await tester.pumpAndSettle();

      // Switch to Diary tab and verify saved card
      await tester.tap(find.byKey(const Key('diaryTab')));
      await tester.pumpAndSettle();
      expect(find.text('TYT Mathematics'), findsOneWidget);

      // Switch to Dashboard tab and verify updated stats
      await tester.tap(find.byKey(const Key('dashboardTab')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('totalMinutesText'))).data,
        '2 min',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('sessionCountText'))).data,
        '1',
      );
    },
  );
}
