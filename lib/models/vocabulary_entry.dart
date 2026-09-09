class VocabularyEntry {
  final String word;
  final String vietnamese;
  final String example;
  final List<String> aliases;

  const VocabularyEntry({
    required this.word,
    required this.vietnamese,
    required this.example,
    this.aliases = const [],
  });

  factory VocabularyEntry.fromJson(Map<String, dynamic> json) {
    return VocabularyEntry(
      word: (json['word'] as String? ?? '').trim(),
      vietnamese: (json['vietnamese'] as String? ?? '').trim(),
      example: (json['example'] as String? ?? '').trim(),
      aliases: (json['aliases'] as List<dynamic>? ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(),
    );
  }
}
