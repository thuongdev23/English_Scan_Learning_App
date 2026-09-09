import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/vocabulary_entry.dart';

List<VocabularyEntry> starterVocabulary = [];

final Map<String, VocabularyEntry> _wordLookup = {};
final Map<String, VocabularyEntry> _aliasLookup = {};
final Map<String, VocabularyEntry> _vietnameseLookup = {};

bool _vocabularyInitialized = false;

Future<void> initializeVocabulary() async {
  if (_vocabularyInitialized) {
    return;
  }

  final rawJson = await rootBundle.loadString(
    'assets/vocabulary/en_vi_vocabulary.json',
  );

  final decoded = jsonDecode(rawJson);

  if (decoded is! List) {
    throw Exception('Vocabulary JSON must contain a list.');
  }
  final Map<String, VocabularyEntry> _vietnameseLookup = {};

  final entries = decoded
      .whereType<Map<String, dynamic>>()
      .map(VocabularyEntry.fromJson)
      .where((entry) => entry.word.isNotEmpty)
      .toList();

  starterVocabulary = entries;

  _wordLookup.clear();
  _aliasLookup.clear();
  _vietnameseLookup.clear();

  // First register all exact vocabulary words.
  for (final entry in entries) {
    final wordKey = _normalizeVocabularyText(entry.word);

    if (wordKey.isNotEmpty) {
      _wordLookup[wordKey] = entry;
    }
    final vietnameseKey = _normalizeVietnameseText(entry.vietnamese);

    if (vietnameseKey.isNotEmpty) {
      _vietnameseLookup.putIfAbsent(vietnameseKey, () => entry);
    }
  }

  // Then register aliases. Exact words always win.
  for (final entry in entries) {
    for (final alias in entry.aliases) {
      final aliasKey = _normalizeVocabularyText(alias);

      if (aliasKey.isEmpty) {
        continue;
      }

      if (_wordLookup.containsKey(aliasKey)) {
        continue;
      }

      _aliasLookup.putIfAbsent(aliasKey, () => entry);
    }
  }

  _vocabularyInitialized = true;
}

VocabularyEntry? findVocabulary(String label) {
  final normalized = _normalizeVocabularyText(label);

  if (normalized.isEmpty) {
    return null;
  }

  return _wordLookup[normalized] ?? _aliasLookup[normalized];
}

String _normalizeVocabularyText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _normalizeVietnameseText(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

VocabularyEntry? findVocabularyByVietnamese(String vietnamese) {
  final normalized = _normalizeVietnameseText(vietnamese);

  if (normalized.isEmpty) {
    return null;
  }

  return _vietnameseLookup[normalized];
}
