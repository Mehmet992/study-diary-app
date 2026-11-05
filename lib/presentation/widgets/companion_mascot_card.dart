import 'package:flutter/material.dart';

import '../../domain/entities/study_enums.dart';

class CompanionMascotCard extends StatelessWidget {
  final CompanionMood mood;
  final String message;
  final String? subtitle;

  const CompanionMascotCard({
    super.key,
    required this.mood,
    required this.message,
    this.subtitle,
  });

  static IconData _iconForMood(CompanionMood mood) => switch (mood) {
    CompanionMood.idle => Icons.menu_book_rounded,
    CompanionMood.studying => Icons.local_fire_department_rounded,
    CompanionMood.breakRest => Icons.coffee_rounded,
    CompanionMood.finalSetCheer => Icons.bolt_rounded,
    CompanionMood.proudCelebration => Icons.emoji_events_rounded,
  };

  static String _badgeForMood(CompanionMood mood) => switch (mood) {
    CompanionMood.idle => 'Study Companion',
    CompanionMood.studying => 'Deep Focus',
    CompanionMood.breakRest => 'Rest & Recharge',
    CompanionMood.finalSetCheer => 'Final Set Ahead!',
    CompanionMood.proudCelebration => 'Proud of You!',
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final (Color bgColor, Color fgColor, Color avatarBg) = switch (mood) {
      CompanionMood.idle => (
        cs.surfaceContainerHighest,
        cs.onSurface,
        cs.primaryContainer,
      ),
      CompanionMood.studying => (
        cs.primaryContainer.withValues(alpha: 0.55),
        cs.onSurface,
        cs.primaryContainer,
      ),
      CompanionMood.breakRest => (
        cs.tertiaryContainer,
        cs.onTertiaryContainer,
        cs.surface,
      ),
      CompanionMood.finalSetCheer => (
        cs.secondaryContainer,
        cs.onSecondaryContainer,
        cs.surface,
      ),
      CompanionMood.proudCelebration => (
        cs.primaryContainer,
        cs.onPrimaryContainer,
        cs.surface,
      ),
    };

    return Card(
      key: const Key('companionMascotCard'),
      color: bgColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Dedicated Mascot Slot (ready for custom animated brand character)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey<CompanionMood>(mood),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: avatarBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  _iconForMood(mood),
                  size: 32,
                  color: cs.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    _badgeForMood(mood),
                    key: const Key('companionMoodBadge'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: fgColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    key: const Key('companionMessageText'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: fgColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
