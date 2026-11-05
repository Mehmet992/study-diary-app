import '../entities/motivational_prompt.dart';
import '../entities/study_enums.dart';

abstract interface class MotivationRepository {
  List<MotivationalPrompt> getAllPrompts({PromptCategory? category});
  MotivationalPrompt getInitialPrompt();
  MotivationalPrompt getNextPrompt({
    String? currentPromptId,
    PromptCategory? category,
  });
}
