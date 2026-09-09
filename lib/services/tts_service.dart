import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> speakEnglish(String text) async {
    await _flutterTts.stop();

    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.42);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

final ttsService = TtsService();
