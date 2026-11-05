import 'package:flutter/material.dart';

import '../../domain/entities/motivational_prompt.dart';
import '../../domain/entities/study_session.dart';
import '../notifiers/active_timer_notifier.dart';
import '../notifiers/study_diary_notifier.dart';

class DashboardScreen extends StatelessWidget {
  final StudyDiaryNotifier diaryNotifier;
  final ActiveTimerNotifier timerNotifier;
  final VoidCallback onNavigateToStudy;

  const DashboardScreen({
    super.key,
    required this.diaryNotifier,
    required this.timerNotifier,
    required this.onNavigateToStudy,
  });

  static Widget _metric(ThemeData t, String label, String val, Key key) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: t.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(val, key: key, style: t.textTheme.headlineSmall),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[diaryNotifier, timerNotifier]),
      builder: (BuildContext context, Widget? _) {
        final ThemeData theme = Theme.of(context);
        final ColorScheme cs = theme.colorScheme;
        final MotivationalPrompt prompt = diaryNotifier.currentPrompt;
        final StudySummary summary = diaryNotifier.summary;
        final String? error = diaryNotifier.errorMessage;
        final bool offline = diaryNotifier.isOfflineMode;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: cs.inversePrimary,
            title: const Text('Dashboard'),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ActionChip(
                  key: const Key('syncStatusBadge'),
                  avatar: Icon(
                    offline ? Icons.cloud_off : Icons.cloud_done,
                    size: 18,
                  ),
                  label: Text(offline ? 'Offline Mode' : 'Synced'),
                  onPressed: diaryNotifier.isLoading
                      ? null
                      : diaryNotifier.syncNow,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (diaryNotifier.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (error != null)
                  Card(
                    key: const Key('dashboardErrorBanner'),
                    color: cs.errorContainer,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(color: cs.onErrorContainer),
                            ),
                          ),
                          TextButton(
                            onPressed: diaryNotifier.clearError,
                            child: const Text('Dismiss'),
                          ),
                        ],
                      ),
                    ),
                  ),
                Card(
                  key: const Key('motivationCard'),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.spaceBetween,
                          children: <Widget>[
                            Chip(
                              label: Text(prompt.categoryLabel),
                              visualDensity: VisualDensity.compact,
                            ),
                            TextButton.icon(
                              key: const Key('nextPromptButton'),
                              onPressed: diaryNotifier.nextPrompt,
                              icon: const Icon(Icons.autorenew, size: 18),
                              label: const Text('New Prompt'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          prompt.text,
                          key: const Key('promptText'),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          prompt.authorOrOrigin,
                          key: const Key('promptAuthorText'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  key: const Key('summaryCard'),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      alignment: WrapAlignment.spaceAround,
                      spacing: 16,
                      runSpacing: 12,
                      children: <Widget>[
                        _metric(
                          theme,
                          'Total Minutes',
                          '${summary.totalMinutes} min',
                          const Key('totalMinutesText'),
                        ),
                        _metric(
                          theme,
                          "Today's Minutes",
                          '${summary.todayMinutes} min',
                          const Key('todayMinutesText'),
                        ),
                        _metric(
                          theme,
                          'Completed Sessions',
                          '${summary.sessionCount}',
                          const Key('sessionCountText'),
                        ),
                        _metric(
                          theme,
                          'Questions Solved',
                          '${summary.totalQuestionsSolved}',
                          const Key('totalQuestionsText'),
                        ),
                        _metric(
                          theme,
                          'Total Net',
                          summary.totalNetScore.toStringAsFixed(2),
                          const Key('totalNetScoreText'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (summary.topicsToReview.isNotEmpty)
                  Card(
                    key: const Key('topicsToReviewCard'),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Topics to Look After',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap a topic once you have reviewed it to mark it resolved.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: <Widget>[
                              for (final String topic in summary.topicsToReview)
                                InputChip(
                                  key: ValueKey<String>('resolveTopic_$topic'),
                                  avatar: const Icon(
                                    Icons.check_circle_outline,
                                    size: 18,
                                  ),
                                  label: Text(topic),
                                  onPressed: diaryNotifier.isLoading
                                      ? null
                                      : () => diaryNotifier
                                            .markReviewTopicResolved(topic),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (timerNotifier.hasActiveSession)
                  Card(
                    key: const Key('activeSessionBanner'),
                    color: cs.secondaryContainer,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      onTap: onNavigateToStudy,
                      leading: Icon(
                        timerNotifier.isTimerRunning
                            ? Icons.timer
                            : Icons.pause_circle_outline,
                        color: cs.onSecondaryContainer,
                      ),
                      title: Text(
                        timerNotifier.isAwaitingReflection
                            ? 'Ready to Log Reflection'
                            : (timerNotifier.isOnBreak
                                  ? 'Pomodoro Break'
                                  : (timerNotifier.isPaused
                                        ? 'Paused Study'
                                        : 'Studying Now')),
                        style: TextStyle(color: cs.onSecondaryContainer),
                      ),
                      subtitle: Text(
                        '${timerNotifier.selectedSessionType.displayLabel} • ${timerNotifier.formattedTimerDisplay}',
                        style: TextStyle(color: cs.onSecondaryContainer),
                      ),
                    ),
                  ),
                FilledButton.icon(
                  key: const Key('openStudyPageButton'),
                  onPressed: onNavigateToStudy,
                  icon: const Icon(Icons.timer_outlined),
                  label: Text(
                    timerNotifier.hasActiveSession
                        ? 'Return to Study'
                        : 'Start Studying',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
