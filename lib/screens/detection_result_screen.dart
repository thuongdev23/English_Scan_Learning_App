import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../data/starter_vocabulary.dart';
import '../models/vocabulary_entry.dart';
import '../services/fallback_vocabulary_service.dart';
import 'word_result_screen.dart';

class DetectionResultScreen extends StatefulWidget {
  final String imagePath;

  const DetectionResultScreen({super.key, required this.imagePath});

  @override
  State<DetectionResultScreen> createState() => _DetectionResultScreenState();
}

class _DetectionResultScreenState extends State<DetectionResultScreen> {
  bool _isLoading = true;

  String? _errorMessage;

  List<_VocabularySuggestion> _suggestions = [];
  List<ImageLabel> _rawLabels = [];

  @override
  void initState() {
    super.initState();
    _detectObjects();
  }

  // ===================================================
  // DETECT OBJECTS
  // ===================================================

  Future<void> _detectObjects() async {
    final imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.40),
    );

    try {
      final inputImage = InputImage.fromFilePath(widget.imagePath);

      final labels = await imageLabeler.processImage(inputImage);

      labels.sort((a, b) => b.confidence.compareTo(a.confidence));

      final Map<String, _VocabularySuggestion> uniqueSuggestions = {};

      for (final label in labels) {
        final vocabulary = findVocabulary(label.label);

        if (vocabulary == null) {
          continue;
        }

        final key = vocabulary.word.trim().toLowerCase();

        final existing = uniqueSuggestions[key];

        if (existing == null || label.confidence > existing.confidence) {
          uniqueSuggestions[key] = _VocabularySuggestion(
            vocabulary: vocabulary,
            confidence: label.confidence,
            originalLabel: label.label,
          );
        }
      }

      final suggestions = uniqueSuggestions.values.toList();

      suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));

      if (!mounted) return;

      setState(() {
        _rawLabels = labels;
        _suggestions = suggestions.take(4).toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not analyze this photo.';
      });
    } finally {
      await imageLabeler.close();
    }
  }

  // ===================================================
  // OPEN WORD RESULT
  // ===================================================

  void _openWord(VocabularyEntry vocabulary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordResultScreen(
          imagePath: widget.imagePath,
          detectedWord: vocabulary.word,
          vietnamese: vocabulary.vietnamese,
          exampleSentence: vocabulary.example,
        ),
      ),
    );
  }

  // ===================================================
  // MANUAL WORD
  // ===================================================

  Future<void> _showManualWordDialog() async {
    final controller = TextEditingController();

    final typedVietnamese = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cái này là gì?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nhập tên đồ vật bằng tiếng Việt.'),

              const SizedBox(height: 6),

              Text(
                'WordAround sẽ tìm tên tiếng Anh cho bạn.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Tên bằng tiếng Việt',
                  hintText: 'Ví dụ: máy nướng bánh mì',
                  prefixIcon: Icon(Icons.translate),
                ),
                onSubmitted: (value) {
                  final clean = value.trim();

                  if (clean.isEmpty) {
                    return;
                  }

                  Navigator.pop(dialogContext, clean);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Hủy'),
            ),

            FilledButton(
              onPressed: () {
                final clean = controller.text.trim();

                if (clean.isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext, clean);
              },
              child: const Text('Tiếp tục'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (typedVietnamese == null || typedVietnamese.trim().isEmpty || !mounted) {
      return;
    }

    // ==================================================
    // FIRST CHECK CURATED 575-WORD DATABASE
    // ==================================================

    final existingVocabulary = findVocabularyByVietnamese(typedVietnamese);

    if (existingVocabulary != null) {
      _openWord(existingVocabulary);

      return;
    }

    // ==================================================
    // NOT IN DATABASE → VIETNAMESE → ENGLISH
    // ==================================================

    final rootNavigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),

              SizedBox(width: 20),

              Expanded(child: Text('Đang tìm từ tiếng Anh...')),
            ],
          ),
        );
      },
    );

    try {
      final generated = await generateFallbackFromVietnamese(typedVietnamese);

      if (!mounted) {
        return;
      }

      rootNavigator.pop();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WordResultScreen(
            imagePath: widget.imagePath,
            detectedWord: generated.word,
            vietnamese: generated.vietnamese,
            exampleSentence: generated.example,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      rootNavigator.pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tìm từ tiếng Anh: $e')));
    }
  }

  // ===================================================
  // BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: AppBar(title: const Text('What did you find?')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PHOTO
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(
                    File(widget.imagePath),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              if (_isLoading) _buildLoading(),

              if (!_isLoading && _errorMessage != null) _buildError(),

              if (!_isLoading && _errorMessage == null) _buildResults(),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================
  // LOADING
  // ===================================================

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            CircularProgressIndicator(),

            SizedBox(height: 18),

            Text(
              'Looking at your photo...',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            SizedBox(height: 6),

            Text(
              'Finding English words you can learn',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // RESULTS
  // ===================================================

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_suggestions.isNotEmpty) ...[
          const Text(
            'We found these 👀',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          const Text(
            'Choose the word that matches your photo.',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),

          const SizedBox(height: 18),

          ..._suggestions.map(_buildSuggestionCard),
        ] else ...[
          _buildNoSuggestions(),
        ],

        const SizedBox(height: 10),

        // MANUAL ENTRY
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showManualWordDialog,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('None of these — enter it in Vietnamese'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // SCAN AGAIN
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Scan Again'),
          ),
        ),
      ],
    );
  }

  // ===================================================
  // SUGGESTION CARD
  // ===================================================

  Widget _buildSuggestionCard(_VocabularySuggestion suggestion) {
    final vocabulary = suggestion.vocabulary;

    final confidence = (suggestion.confidence * 100).round();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.translate_outlined,
              color: Colors.deepPurple,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vocabulary.word,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  vocabulary.vietnamese,
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),

                const SizedBox(height: 5),

                Text(
                  '$confidence% match',
                  style: TextStyle(
                    fontSize: 12,
                    color: confidence >= 80
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          FilledButton(
            onPressed: () {
              _openWord(vocabulary);
            },
            child: const Text('Choose'),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // NO SUGGESTIONS
  // ===================================================

  Widget _buildNoSuggestions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('🤔', style: TextStyle(fontSize: 46)),

          const SizedBox(height: 12),

          const Text(
            "We're not sure what this is",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          const Text(
            'Try typing the object name or scan it again from a clearer angle.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),

          if (_rawLabels.isNotEmpty) ...[
            const SizedBox(height: 16),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: _rawLabels
                  .take(4)
                  .map((label) => Chip(label: Text(label.label)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ===================================================
  // ERROR
  // ===================================================

  Widget _buildError() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.orange),

          const SizedBox(height: 14),

          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 18),

          FilledButton(
            onPressed: _detectObjects,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// INTERNAL SUGGESTION MODEL
// =====================================================

class _VocabularySuggestion {
  final VocabularyEntry vocabulary;
  final double confidence;
  final String originalLabel;

  const _VocabularySuggestion({
    required this.vocabulary,
    required this.confidence,
    required this.originalLabel,
  });
}
