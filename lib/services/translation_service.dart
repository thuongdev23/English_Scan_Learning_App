import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  Future<void> _ensureModel(TranslateLanguage language) async {
    final code = language.bcpCode;

    final alreadyDownloaded = await _modelManager.isModelDownloaded(code);

    if (alreadyDownloaded) {
      return;
    }

    final downloaded = await _modelManager.downloadModel(
      code,
      isWifiRequired: false,
    );

    if (!downloaded) {
      throw Exception('Could not download translation model for $code.');
    }
  }

  // ===================================================
  // ENGLISH → VIETNAMESE
  // ===================================================

  Future<String> englishToVietnamese(String text) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw Exception('Nothing to translate.');
    }

    await _ensureModel(TranslateLanguage.english);

    await _ensureModel(TranslateLanguage.vietnamese);

    final translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: TranslateLanguage.vietnamese,
    );

    try {
      final translated = await translator.translateText(cleanText);

      return translated.trim();
    } finally {
      await translator.close();
    }
  }

  // ===================================================
  // VIETNAMESE → ENGLISH
  // ===================================================

  Future<String> vietnameseToEnglish(String text) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw Exception('Nothing to translate.');
    }

    await _ensureModel(TranslateLanguage.vietnamese);

    await _ensureModel(TranslateLanguage.english);

    final translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.vietnamese,
      targetLanguage: TranslateLanguage.english,
    );

    try {
      final translated = await translator.translateText(cleanText);

      return translated.trim();
    } finally {
      await translator.close();
    }
  }
}

final translationService = TranslationService();
