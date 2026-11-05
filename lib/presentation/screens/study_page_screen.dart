import 'package:flutter/material.dart';

import '../../domain/entities/study_enums.dart';
import '../notifiers/active_timer_notifier.dart';
import '../notifiers/study_diary_notifier.dart';
import '../widgets/companion_mascot_card.dart';
import '../widgets/post_session_reflection_sheet.dart';

class StudyPageScreen extends StatelessWidget {
  final ActiveTimerNotifier timerNotifier;
  final StudyDiaryNotifier diaryNotifier;

  const StudyPageScreen({
    super.key,
    required this.timerNotifier,
    required this.diaryNotifier,
  });

  static IconData _modeIcon(SessionType type) => switch (type) {
    SessionType.pomodoro => Icons.timelapse_rounded,
    SessionType.freeStudy => Icons.all_inclusive_rounded,
    SessionType.oneHour => Icons.hourglass_bottom_rounded,
  };

  static String _phaseLabel(ActiveTimerNotifier n) {
    if (n.isIdle) return 'Ready';
    if (n.isOnBreak) return n.isPaused ? 'Break Paused' : '5m Break';
    if (n.isStudying) return n.isPaused ? 'Paused' : 'Studying';
    return 'Session Complete';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[timerNotifier, diaryNotifier]),
      builder: (BuildContext context, Widget? _) {
        final ThemeData theme = Theme.of(context);
        final ColorScheme cs = theme.colorScheme;
        final ActiveTimerNotifier n = timerNotifier;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: cs.inversePrimary,
            title: const Text('Focus Study'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (n.errorMessage != null)
                  Card(
                    key: const Key('studyPageErrorBanner'),
                    color: cs.errorContainer,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              n.errorMessage!,
                              style: TextStyle(color: cs.onErrorContainer),
                            ),
                          ),
                          TextButton(
                            onPressed: n.clearError,
                            child: const Text('Dismiss'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (n.isAwaitingReflection)
                  PostSessionReflectionCard(
                    diaryNotifier: diaryNotifier,
                    activeTimerNotifier: timerNotifier,
                  )
                else ...<Widget>[
                  CompanionMascotCard(
                    mood: n.companionMood,
                    message: n.companionMessage,
                    subtitle: n.selectedSessionType == SessionType.pomodoro &&
                            !n.isIdle
                        ? 'Completed sets: ${n.completedPomodoroSets} / ${n.targetPomodoroSets}'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    key: const Key('activeTimerCard'),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 6,
                            children: <Widget>[
                              Chip(
                                label: Text(
                                  _phaseLabel(n),
                                  key: const Key('timerPhaseText'),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              if (!n.isIdle)
                                Text(
                                  'Pauses: ${n.pauseCount}',
                                  key: const Key('pauseCountText'),
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            n.formattedTimerDisplay,
                            key: const Key('timerDisplayText'),
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          if (!n.isIdle &&
                              n.selectedSessionType != SessionType.freeStudy) ...<
                            Widget
                          >[
                            const SizedBox(height: 4),
                            Text(
                              'Total Active Study: ${n.formattedTotalStudyTime}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (n.isIdle)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                key: const Key('startTimerButton'),
                                onPressed: () => n.startSession(),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Start Studying Now'),
                              ),
                            )
                          else if (n.isOnBreak)
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 8,
                              children: <Widget>[
                                FilledButton.icon(
                                  key: const Key('skipBreakButton'),
                                  onPressed: n.startNextPomodoroSet,
                                  icon: const Icon(Icons.skip_next_rounded),
                                  label: const Text('Start Next Set Now'),
                                ),
                                if (!n.isPaused)
                                  FilledButton.tonalIcon(
                                    key: const Key('pauseTimerButton'),
                                    onPressed: n.pauseTimer,
                                    icon: const Icon(Icons.pause),
                                    label: const Text('Pause Break'),
                                  )
                                else
                                  FilledButton.tonalIcon(
                                    key: const Key('resumeTimerButton'),
                                    onPressed: n.resumeTimer,
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Resume Break'),
                                  ),
                                OutlinedButton.icon(
                                  key: const Key('finishStudyButton'),
                                  onPressed: n.finishStudyForReflection,
                                  icon: const Icon(Icons.flag_outlined),
                                  label: const Text('Finish Early'),
                                ),
                              ],
                            )
                          else
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 8,
                              children: <Widget>[
                                if (!n.isPaused)
                                  FilledButton.tonalIcon(
                                    key: const Key('pauseTimerButton'),
                                    onPressed: n.pauseTimer,
                                    icon: const Icon(Icons.pause),
                                    label: const Text('Pause'),
                                  )
                                else
                                  FilledButton.icon(
                                    key: const Key('resumeTimerButton'),
                                    onPressed: n.resumeTimer,
                                    icon: const Icon(
                                      Icons.play_circle_outline,
                                    ),
                                    label: const Text('Resume'),
                                  ),
                                FilledButton.icon(
                                  key: const Key('finishStudyButton'),
                                  onPressed: n.finishStudyForReflection,
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Finish & Take Notes'),
                                ),
                                OutlinedButton.icon(
                                  key: const Key('resetTimerButton'),
                                  onPressed: n.resetToIdle,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reset'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (n.isIdle) ...<Widget>[
                    Text(
                      'Choose Study Mode',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final SessionType mode in SessionType.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ModeOptionCard(
                          mode: mode,
                          selected: n.selectedSessionType == mode,
                          icon: _modeIcon(mode),
                          onTap: () => n.setSelectedSessionType(mode),
                        ),
                      ),
                    if (n.selectedSessionType == SessionType.pomodoro)
                      Card(
                        key: const Key('pomodoroSetsConfigurator'),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: <Widget>[
                              Text(
                                'Target Pomodoro Sets',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    key: const Key('decreaseSetsButton'),
                                    onPressed: n.targetPomodoroSets > 1
                                        ? () => n.setTargetPomodoroSets(
                                            n.targetPomodoroSets - 1,
                                          )
                                        : null,
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                  Text(
                                    '${n.targetPomodoroSets} sets',
                                    key: const Key('pomodoroSetsCountText'),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  IconButton(
                                    key: const Key('increaseSetsButton'),
                                    onPressed: n.targetPomodoroSets < 8
                                        ? () => n.setTargetPomodoroSets(
                                            n.targetPomodoroSets + 1,
                                          )
                                        : null,
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  final SessionType mode;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _ModeOptionCard({
    required this.mode,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Card(
      key: ValueKey<String>('modeCard_${mode.name}'),
      margin: EdgeInsets.zero,
      color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? cs.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        onTap: onTap,
        leading: Icon(
          icon,
          color: selected ? cs.onPrimaryContainer : cs.primary,
        ),
        title: Text(
          mode.displayLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? cs.onPrimaryContainer : cs.onSurface,
          ),
        ),
        subtitle: Text(
          mode.subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected
                ? cs.onPrimaryContainer.withValues(alpha: 0.85)
                : cs.onSurfaceVariant,
          ),
        ),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: cs.primary)
            : const Icon(Icons.radio_button_unchecked),
      ),
    );
  }
}
