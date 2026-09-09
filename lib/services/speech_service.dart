import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }

    _initialized = await _speech.initialize();

    return _initialized;
  }

  Future<void> listen({required void Function(String text) onResult}) async {
    final available = await initialize();

    if (!available) {
      throw Exception('Speech recognition is not available.');
    }

    await _speech.listen(
      localeId: 'en_US',
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}

final speechService = SpeechService();
