import '../../domain/entities/motivational_prompt.dart';
import '../../domain/entities/study_enums.dart';
import '../../domain/repositories/motivation_repository.dart';

class LocalMotivationRepository implements MotivationRepository {
  static const List<MotivationalPrompt> defaultPrompts = <MotivationalPrompt>[
    MotivationalPrompt(id: 'enc-1', text: 'Focused effort compounds quietly. Every study block builds mastery.', authorOrOrigin: 'Study Diary Coach', category: PromptCategory.encouragement),
    MotivationalPrompt(id: 'idiom-1', text: 'Hit the books — dedicate full, distraction-free attention today.', authorOrOrigin: 'English Study Idiom', category: PromptCategory.idiom),
    MotivationalPrompt(id: 'quote-1', text: 'It does not matter how slowly you go as long as you do not stop.', authorOrOrigin: 'Confucius', category: PromptCategory.quote),
    MotivationalPrompt(id: 'enc-2', text: 'Progress over perfection: twenty focused minutes move you forward.', authorOrOrigin: 'Study Diary Coach', category: PromptCategory.encouragement),
    MotivationalPrompt(id: 'idiom-2', text: 'Rome was not built in a day — understanding grows one session at a time.', authorOrOrigin: 'Classic Proverb', category: PromptCategory.idiom),
    MotivationalPrompt(id: 'quote-2', text: 'Well begun is half done.', authorOrOrigin: 'Aristotle', category: PromptCategory.quote),
    MotivationalPrompt(id: 'enc-3', text: 'Take a deep breath, pick a single topic, and trust your preparation.', authorOrOrigin: 'Study Diary Coach', category: PromptCategory.encouragement),
    MotivationalPrompt(id: 'idiom-3', text: 'Learn the ropes — master the fundamentals first.', authorOrOrigin: 'Maritime Idiom', category: PromptCategory.idiom),
    MotivationalPrompt(id: 'quote-3', text: 'The secret of getting ahead is getting started.', authorOrOrigin: 'Mark Twain', category: PromptCategory.quote),
  ];

  final List<MotivationalPrompt> _prompts;

  LocalMotivationRepository({List<MotivationalPrompt>? prompts})
    : _prompts = List<MotivationalPrompt>.unmodifiable(prompts ?? defaultPrompts) {
    if (_prompts.isEmpty) {
      throw ArgumentError.value(prompts, 'prompts', 'Prompts must not be empty.');
    }
  }

  @override
  List<MotivationalPrompt> getAllPrompts({PromptCategory? category}) =>
      category == null
      ? _prompts
      : List<MotivationalPrompt>.unmodifiable(
          _prompts.where((MotivationalPrompt p) => p.category == category),
        );

  @override
  MotivationalPrompt getInitialPrompt() => _prompts.first;

  @override
  MotivationalPrompt getNextPrompt({String? currentPromptId, PromptCategory? category}) {
    final List<MotivationalPrompt> filtered = getAllPrompts(category: category);
    final List<MotivationalPrompt> pool = filtered.isEmpty ? _prompts : filtered;
    if (currentPromptId == null) return pool.first;
    final int idx = pool.indexWhere((MotivationalPrompt p) => p.id == currentPromptId);
    return idx < 0 ? pool.first : pool[(idx + 1) % pool.length];
  }
}
