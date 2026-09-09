import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/starter_vocabulary.dart';
import '../services/firestore_service.dart';
import '../services/tts_service.dart';
import '../services/speech_service.dart';
import '../services/audio_recording_service.dart';
import '../services/local_image_service.dart';
import '../services/progress_service.dart';

class WordResultScreen extends StatefulWidget {
  final String? imagePath;
  final String? detectedWord;
  final String? vietnamese;
  final String? exampleSentence;

  const WordResultScreen({
    super.key,
    this.imagePath,
    this.detectedWord,
    this.vietnamese,
    this.exampleSentence,
  });

  @override
  State<WordResultScreen> createState() => _WordResultScreenState();
}

class _WordResultScreenState extends State<WordResultScreen> {
  bool _isListening = false;
  String _heardText = '';

  bool _isRecordingPronunciation = false;
  String? _recordedAudioPath;

  Future<void> _recordPronunciation(String targetWord) async {
    try {
      if (_isRecordingPronunciation) {
        final path = await audioRecordingService.stopRecording();

        if (!mounted) return;

        setState(() {
          _isRecordingPronunciation = false;
          _recordedAudioPath = path;
        });

        if (path == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No recording was created.')),
          );

          return;
        }

        await _showRecordingReadyDialog(targetWord, path);

        return;
      }

      await audioRecordingService.startRecording();

      if (!mounted) return;

      setState(() {
        _recordedAudioPath = null;
        _isRecordingPronunciation = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRecordingPronunciation = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Recording failed: $e')));
    }
  }

  Future<void> _showRecordingReadyDialog(String targetWord, String path) async {
    final file = File(path);

    final fileSize = await file.length();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recording ready 🎙️'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Target word: $targetWord'),

              const SizedBox(height: 8),

              Text('Audio size: ${(fileSize / 1024).toStringAsFixed(1)} KB'),

              const SizedBox(height: 16),

              const Text(
                'Next, this recording will be sent for pronunciation assessment.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _practicePronunciation(String targetWord) async {
    try {
      if (_isListening) {
        await speechService.stop();

        setState(() {
          _isListening = false;
        });

        return;
      }

      setState(() {
        _heardText = '';
        _isListening = true;
      });

      await speechService.listen(
        onResult: (text) {
          if (!mounted) return;

          setState(() {
            _heardText = text;
          });
        },
      );

      await Future.delayed(const Duration(seconds: 4));

      await speechService.stop();

      if (!mounted) return;

      setState(() {
        _isListening = false;
      });

      _showPronunciationResult(targetWord);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isListening = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not use microphone: $e')));
    }
  }

  void _showPronunciationResult(String targetWord) {
    final target = targetWord.trim().toLowerCase();

    final heard = _heardText.trim().toLowerCase();

    final isCorrect = heard == target || heard.split(' ').contains(target);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isCorrect ? 'Great job! 🎉' : 'Try again'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCorrect
                    ? 'I heard "$_heardText".'
                    : 'I heard "$_heardText".\n\nTry saying "$targetWord" again.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              Icon(
                isCorrect ? Icons.check_circle : Icons.mic,
                size: 60,
                color: isCorrect ? Colors.green : Colors.orange,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.detectedWord ?? 'Bottle';
    final vocabulary = findVocabulary(word);

    final displayedVietnamese =
        widget.vietnamese ??
        vocabulary?.vietnamese ??
        'Not in our vocabulary yet';

    final displayedExample =
        widget.exampleSentence ??
        vocabulary?.example ??
        'This is a ${word.toLowerCase()}.';

    return Scaffold(
      appBar: AppBar(title: const Text('New Word')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),

              child: SizedBox(
                height: 260,
                width: double.infinity,

                child: widget.imagePath != null
                    ? Image.file(File(widget.imagePath!), fit: BoxFit.cover)
                    : Container(
                        color: Colors.deepPurple.shade50,
                        child: const Icon(
                          Icons.image_outlined,
                          size: 100,
                          color: Colors.deepPurple,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              word.toUpperCase(),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              displayedVietnamese,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, color: Colors.deepPurple),
            ),

            const SizedBox(height: 28),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Example',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    displayedExample,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await ttsService.speakEnglish(word);
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not play pronunciation: $e'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.volume_up),
                label: const Text('Listen'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _recordPronunciation(word);
                },
                icon: Icon(
                  _isRecordingPronunciation ? Icons.stop_circle : Icons.mic,
                ),
                label: Text(
                  _isRecordingPronunciation
                      ? 'Stop Recording'
                      : 'Practice Pronunciation',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    final documentId = createWordDocumentId(word);

                    final document = getUserWordsCollection().doc(documentId);

                    final existingWord = await document.get();

                    if (existingWord.exists) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$word is already in My Words.'),
                        ),
                      );

                      return;
                    }
                    final permanentImagePath = await localImageService
                        .saveImage(widget.imagePath, word);

                    await document.set({
                      'word': word,
                      'vietnamese': displayedVietnamese,
                      'example': displayedExample,
                      'localImagePath': permanentImagePath,
                      'createdAt': FieldValue.serverTimestamp(),

                      // Spaced repetition data
                      'masteryLevel': 0,
                      'correctReviews': 0,
                      'incorrectReviews': 0,
                      'lastReviewedAt': null,
                      'nextReviewAt': Timestamp.now(),
                    });
                    await addProgressForNewWord();

                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$word saved to My Words! 🎉')),
                    );
                  } catch (e) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not save word: $e')),
                    );
                  }
                },

                icon: const Icon(Icons.bookmark_add),

                label: const Text('Save Word'),

                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
