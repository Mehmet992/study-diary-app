import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/study_session.dart';
import '../notifiers/study_diary_notifier.dart';
import '../widgets/post_session_reflection_sheet.dart';

class DiaryScreen extends StatelessWidget {
  static final DateFormat _dateFormat = DateFormat('MMM d, y • HH:mm');

  final StudyDiaryNotifier diaryNotifier;

  const DiaryScreen({super.key, required this.diaryNotifier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: diaryNotifier,
      builder: (BuildContext context, Widget? _) {
        final ThemeData theme = Theme.of(context);
        final ColorScheme cs = theme.colorScheme;
        final bool busy = diaryNotifier.isLoading;
        final List<StudySession> sessions = diaryNotifier.sessions;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: cs.inversePrimary,
            title: const Text('Study Diary'),
            actions: <Widget>[
              IconButton(
                key: const Key('logPastSessionButton'),
                icon: const Icon(Icons.add),
                tooltip: 'Add Study Session',
                onPressed: busy
                    ? null
                    : () => PostSessionReflectionCard.showManualLogSheet(
                        context,
                        diaryNotifier: diaryNotifier,
                      ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              if (sessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.menu_book_outlined,
                        size: 48,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No study sessions logged yet.\nFinish a study timer or tap + to log a past session.',
                        key: Key('emptyStateText'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                for (final StudySession s in sessions)
                  Card(
                    key: ValueKey<String>('session-card-${s.id}'),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      s.topic.isNotEmpty
                                          ? '${s.subject} • ${s.topic}'
                                          : s.subject,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _dateFormat.format(s.startedAt.toLocal()),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Delete session',
                                onPressed: busy
                                    ? null
                                    : () => diaryNotifier.deleteSession(s.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: <Widget>[
                              Chip(
                                label: Text(
                                  '${s.sessionType.displayLabel} • ${s.durationMinutes} min',
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              Chip(
                                label: Text(s.activityType.displayLabel),
                                visualDensity: VisualDensity.compact,
                              ),
                              if (s.totalQuestions > 0 && s.netScore != null)
                                Chip(
                                  backgroundColor: cs.secondaryContainer,
                                  label: Text(
                                    '${s.totalQuestions} Q (${s.correctCount ?? 0}C / ${s.wrongCount ?? 0}W) • Net: ${s.netScore!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: cs.onSecondaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                          if (s.reflectionTags.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: <Widget>[
                                for (final ReflectionTag tag
                                    in s.reflectionTags)
                                  Text(
                                    '#${tag.displayLabel}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          if (s.topicsToReview.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 6),
                            Text(
                              'Look after: ${s.topicsToReview.join(', ')}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.tertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (s.notes.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 6),
                            Text(s.notes, style: theme.textTheme.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
