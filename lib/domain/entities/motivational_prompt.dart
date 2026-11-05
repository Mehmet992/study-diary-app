import 'study_enums.dart';

class MotivationalPrompt {
  final String id;
  final String text;
  final String authorOrOrigin;
  final PromptCategory category;

  String get categoryLabel => category.displayLabel;

  const MotivationalPrompt({
    required this.id,
    required this.text,
    required this.authorOrOrigin,
    required this.category,
  });

  factory MotivationalPrompt.validated({
    required String id,
    required String text,
    required String authorOrOrigin,
    required PromptCategory category,
  }) {
    final String cleanId = id.trim();
    final String cleanText = text.trim();
    final String cleanAuthor = authorOrOrigin.trim();
    if (cleanId.isEmpty) throw ArgumentError.value(id, 'id');
    if (cleanText.isEmpty) throw ArgumentError.value(text, 'text');
    if (cleanAuthor.isEmpty) {
      throw ArgumentError.value(authorOrOrigin, 'authorOrOrigin');
    }
    return MotivationalPrompt(
      id: cleanId,
      text: cleanText,
      authorOrOrigin: cleanAuthor,
      category: category,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MotivationalPrompt &&
          other.id == id &&
          other.text == text &&
          other.authorOrOrigin == authorOrOrigin &&
          other.category == category);

  @override
  int get hashCode => Object.hash(id, text, authorOrOrigin, category);
}
