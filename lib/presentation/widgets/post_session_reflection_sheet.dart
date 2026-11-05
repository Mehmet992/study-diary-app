import 'package:flutter/material.dart';

import '../../domain/entities/study_session.dart';
import '../notifiers/active_timer_notifier.dart';
import '../notifiers/study_diary_notifier.dart';
import 'companion_mascot_card.dart';

class PostSessionReflectionCard extends StatefulWidget {
  final StudyDiaryNotifier diaryNotifier;
  final ActiveTimerNotifier? activeTimerNotifier;
  final bool isManualLog;
  final VoidCallback? onSaved;
  final VoidCallback? onCancelOrDiscard;

  const PostSessionReflectionCard({
    super.key,
    required this.diaryNotifier,
    this.activeTimerNotifier,
    this.isManualLog = false,
    this.onSaved,
    this.onCancelOrDiscard,
  });

  static Future<bool> showManualLogSheet(
    BuildContext context, {
    required StudyDiaryNotifier diaryNotifier,
  }) async {
    bool saved = false;
    diaryNotifier.clearError();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
          ),
          child: SingleChildScrollView(
            child: PostSessionReflectionCard(
              diaryNotifier: diaryNotifier,
              isManualLog: true,
              onSaved: () {
                saved = true;
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
              onCancelOrDiscard: () {
                diaryNotifier.clearError();
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
            ),
          ),
        );
      },
    );
    if (!saved) diaryNotifier.clearError();
    return saved;
  }

  @override
  State<PostSessionReflectionCard> createState() =>
      _PostSessionReflectionCardState();
}

class _PostSessionReflectionCardState extends State<PostSessionReflectionCard> {
  final TextEditingController _subjectCtrl = TextEditingController();
  final TextEditingController _topicCtrl = TextEditingController();
  final TextEditingController _durationMinutesCtrl = TextEditingController(
    text: '25',
  );
  final TextEditingController _correctCtrl = TextEditingController();
  final TextEditingController _wrongCtrl = TextEditingController();
  final TextEditingController _blankCtrl = TextEditingController();
  final TextEditingController _topicsToReviewCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  SessionType _manualSessionType = SessionType.pomodoro;
  StudyActivityType _activityType = StudyActivityType.topicStudy;
  final Set<ReflectionTag> _selectedTags = <ReflectionTag>{};

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _subjectCtrl,
      _topicCtrl,
      _durationMinutesCtrl,
      _correctCtrl,
      _wrongCtrl,
      _blankCtrl,
      _topicsToReviewCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _parseOptNonNegative(String raw) {
    final String t = raw.trim();
    if (t.isEmpty) return null;
    final int? val = int.tryParse(t);
    return (val != null && val >= 0) ? val : null;
  }

  (int total, double net) _computeLiveQuestionMetrics() {
    final int c = _parseOptNonNegative(_correctCtrl.text) ?? 0;
    final int w = _parseOptNonNegative(_wrongCtrl.text) ?? 0;
    final int b = _parseOptNonNegative(_blankCtrl.text) ?? 0;
    return (c + w + b, c - (w * 0.25));
  }

  List<String> _parseTopicsToReview() {
    final String raw = _topicsToReviewCtrl.text.trim();
    if (raw.isEmpty) return const <String>[];
    return <String>[
      for (final String part in raw.split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  Future<void> _handleSave() async {
    final ActiveTimerNotifier? timer = widget.activeTimerNotifier;
    final bool hasQuestions = _activityType.hasQuestions;
    final int? correct =
        hasQuestions ? _parseOptNonNegative(_correctCtrl.text) : null;
    final int? wrong =
        hasQuestions ? _parseOptNonNegative(_wrongCtrl.text) : null;
    final int? blank =
        hasQuestions ? _parseOptNonNegative(_blankCtrl.text) : null;

    final int? manualDuration = widget.isManualLog
        ? (int.tryParse(_durationMinutesCtrl.text.trim()) ?? 0)
        : null;

    final bool ok = await widget.diaryNotifier.saveSession(
      subject: _subjectCtrl.text,
      topic: _topicCtrl.text,
      activityType: _activityType,
      sessionType: widget.isManualLog
          ? _manualSessionType
          : (timer?.selectedSessionType ?? SessionType.freeStudy),
      elapsedSeconds:
          widget.isManualLog ? null : timer?.totalStudyElapsedSeconds,
      durationMinutes: manualDuration,
      pausedSeconds: timer?.pausedSeconds ?? 0,
      pauseCount: timer?.pauseCount ?? 0,
      completedPomodoroSets: timer?.completedPomodoroSets ?? 0,
      targetPomodoroSets: timer?.selectedSessionType == SessionType.pomodoro
          ? timer?.targetPomodoroSets
          : null,
      targetDurationMinutes: timer?.targetDurationMinutes,
      correctCount: correct,
      wrongCount: wrong,
      blankCount: blank,
      reflectionTags: _selectedTags.toList(growable: false),
      topicsToReview: _parseTopicsToReview(),
      notes: _notesCtrl.text,
      startedAt: timer?.startedAt,
      endedAt: timer?.endedAt,
    );

    if (ok) {
      timer?.resetToIdle();
      widget.onSaved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.diaryNotifier,
      builder: (BuildContext context, Widget? _) {
        final ThemeData theme = Theme.of(context);
        final ColorScheme cs = theme.colorScheme;
        final ActiveTimerNotifier? timer = widget.activeTimerNotifier;
        final String? error = widget.diaryNotifier.errorMessage;
        final bool busy = widget.diaryNotifier.isLoading;
        final List<String> subjects = widget.diaryNotifier.suggestedSubjects;
        final (int totalQuestions, double netScore) =
            _computeLiveQuestionMetrics();

        return Column(
          key: const Key('postSessionReflectionCard'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!widget.isManualLog && timer != null) ...<Widget>[
              CompanionMascotCard(
                mood: CompanionMood.proudCelebration,
                message: timer.companionMessage,
                subtitle:
                    'Studied ${timer.formattedTotalStudyTime} (${timer.selectedSessionType.displayLabel})',
              ),
              const SizedBox(height: 16),
            ] else ...<Widget>[
              Text(
                'Log Study Session',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (error != null)
              Container(
                key: const Key('reflectionErrorBanner'),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  error,
                  style: TextStyle(color: cs.onErrorContainer),
                ),
              ),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Quick Study Reflection',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap your subject and key signals so your AI coach can guide your next study block.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.isManualLog) ...<Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<SessionType>(
                              key: const Key('manualSessionTypeDropdown'),
                              initialValue: _manualSessionType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Study Mode',
                                isDense: true,
                              ),
                              items: <DropdownMenuItem<SessionType>>[
                                for (final SessionType t in SessionType.values)
                                  DropdownMenuItem<SessionType>(
                                    value: t,
                                    child: Text(t.displayLabel),
                                  ),
                              ],
                              onChanged: busy
                                  ? null
                                  : (SessionType? v) {
                                      if (v == null) return;
                                      setState(() {
                                        _manualSessionType = v;
                                        if (v.defaultMinutes != null) {
                                          _durationMinutesCtrl.text =
                                              '${v.defaultMinutes}';
                                        }
                                      });
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              key: const Key('durationField'),
                              controller: _durationMinutesCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Minutes',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        for (final String sub in subjects.take(6))
                          ActionChip(
                            key: ValueKey<String>('subjectChip_$sub'),
                            label: Text(sub),
                            visualDensity: VisualDensity.compact,
                            onPressed: busy
                                ? null
                                : () => setState(() => _subjectCtrl.text = sub),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            key: const Key('reflectionSubjectField'),
                            controller: _subjectCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Subject (e.g. Mathematics)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            key: const Key('reflectionTopicField'),
                            controller: _topicCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Topic (optional)',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Activity Type', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        for (final StudyActivityType act
                            in StudyActivityType.values)
                          ChoiceChip(
                            key: ValueKey<String>(
                              'activityType_${act.name}',
                            ),
                            label: Text(act.displayLabel),
                            selected: _activityType == act,
                            onSelected: busy
                                ? null
                                : (_) => setState(() => _activityType = act),
                          ),
                      ],
                    ),
                    if (_activityType.hasQuestions) ...<Widget>[
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              key: const Key('correctCountField'),
                              controller: _correctCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Correct',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              key: const Key('wrongCountField'),
                              controller: _wrongCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Wrong',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              key: const Key('blankCountField'),
                              controller: _blankCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Blank',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Total: $totalQuestions questions • Net: ${netScore.toStringAsFixed(2)}',
                        key: const Key('liveNetScoreText'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'How did it go? (AI Coach Signals)',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        for (final ReflectionTag tag in ReflectionTag.values)
                          FilterChip(
                            key: ValueKey<String>('reflectionTag_${tag.name}'),
                            label: Text(tag.displayLabel),
                            visualDensity: VisualDensity.compact,
                            selected: _selectedTags.contains(tag),
                            onSelected: busy
                                ? null
                                : (bool sel) {
                                    setState(() {
                                      if (sel) {
                                        _selectedTags.add(tag);
                                      } else {
                                        _selectedTags.remove(tag);
                                      }
                                    });
                                  },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('topicsToReviewField'),
                      controller: _topicsToReviewCtrl,
                      decoration: const InputDecoration(
                        labelText:
                            'Topics to look after (comma-separated, optional)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('reflectionNotesField'),
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Thoughts / Notes (optional)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 10,
                      runSpacing: 8,
                      children: <Widget>[
                        TextButton(
                          key: const Key('discardSessionButton'),
                          onPressed: busy
                              ? null
                              : () {
                                  widget.diaryNotifier.clearError();
                                  timer?.resetToIdle();
                                  widget.onCancelOrDiscard?.call();
                                },
                          child: Text(
                            widget.isManualLog ? 'Cancel' : 'Discard Session',
                          ),
                        ),
                        FilledButton.icon(
                          key: const Key('saveReflectionButton'),
                          onPressed: busy ? null : _handleSave,
                          icon: const Icon(Icons.check),
                          label: const Text('Save Session'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
