import 'translation_service.dart';

class GeneratedVocabulary {
  final String word;
  final String vietnamese;
  final String example;

  const GeneratedVocabulary({
    required this.word,
    required this.vietnamese,
    required this.example,
  });
}

// =====================================================
// VIETNAMESE INPUT → ENGLISH LEARNING CARD
// =====================================================

Future<GeneratedVocabulary> generateFallbackFromVietnamese(
  String vietnameseInput,
) async {
  final cleanVietnamese = vietnameseInput.trim();

  if (cleanVietnamese.isEmpty) {
    throw Exception('Please enter a Vietnamese word.');
  }

  final translatedEnglish = await translationService.vietnameseToEnglish(
    cleanVietnamese,
  );

  final cleanEnglish = _formatEnglish(translatedEnglish);

  final example = _buildSimpleExample(cleanEnglish);

  return GeneratedVocabulary(
    word: cleanEnglish,
    vietnamese: cleanVietnamese,
    example: example,
  );
}

String _formatEnglish(String value) {
  final clean = value.trim();

  if (clean.isEmpty) {
    return clean;
  }

  return clean[0].toUpperCase() + clean.substring(1);
}

String _buildSimpleExample(String word) {
  final lower = word.toLowerCase();

  if (lower.isEmpty) {
    return '';
  }

  const pluralWords = {
    'scissors',
    'glasses',
    'pants',
    'shorts',
    'headphones',
    'jeans',
  };

  if (pluralWords.contains(lower)) {
    return 'I can see $lower.';
  }

  const noArticleWords = {
    'water',
    'milk',
    'coffee',
    'tea',
    'rice',
    'bread',
    'sugar',
    'salt',
  };

  if (noArticleWords.contains(lower)) {
    return 'I can see $lower.';
  }

  final firstLetter = lower[0];

  final useAn = 'aeiou'.contains(firstLetter);

  final article = useAn ? 'an' : 'a';

  return 'I can see $article $lower.';
}
