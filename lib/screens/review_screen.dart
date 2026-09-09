import 'dart:math';

import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import '../services/review_service.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _isLoading = true;

  List<ReviewWord> _dueWords = [];
  List<ReviewWord> _allWords = [];

  int _currentIndex = 0;

  List<String> _answers = [];

  bool _answered = false;
  String? _selectedAnswer;

  int? _resultMasteryLevel;

  @override
  void initState() {
    super.initState();

    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final dueWords = await getDueReviewWords();

      final allWords = await getAllSavedWords();

      dueWords.shuffle();

      if (!mounted) return;

      setState(() {
        _dueWords = dueWords;
        _allWords = allWords;
        _isLoading = false;
      });

      if (_dueWords.isNotEmpty) {
        _prepareAnswers();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not load reviews: $e')));
    }
  }

  void _prepareAnswers() {
    if (_currentIndex >= _dueWords.length) {
      return;
    }

    final current = _dueWords[_currentIndex];

    final incorrectOptions = _allWords
        .where((item) => item.id != current.id)
        .map((item) => item.word)
        .toSet()
        .toList();

    incorrectOptions.shuffle();

    final answers = <String>[current.word, ...incorrectOptions.take(3)];

    answers.shuffle(Random());

    setState(() {
      _answers = answers;
      _answered = false;
      _selectedAnswer = null;
      _resultMasteryLevel = null;
    });
  }

  Future<void> _selectAnswer(String answer) async {
    if (_answered) {
      return;
    }

    final current = _dueWords[_currentIndex];

    final isCorrect = answer.toLowerCase() == current.word.toLowerCase();

    final newMasteryLevel = isCorrect
        ? (current.masteryLevel + 1).clamp(0, 5)
        : (current.masteryLevel - 1).clamp(0, 5);

    setState(() {
      _answered = true;
      _selectedAnswer = answer;
      _resultMasteryLevel = newMasteryLevel;
    });

    await submitReviewResult(reviewWord: current, isCorrect: isCorrect);

    await addXpForReview(isCorrect: isCorrect);
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= _dueWords.length) {
      setState(() {
        _currentIndex++;
      });

      return;
    }

    setState(() {
      _currentIndex++;
    });

    _prepareAnswers();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    if (_dueWords.isEmpty) {
      return const SafeArea(child: _NoReviewsView());
    }

    if (_currentIndex >= _dueWords.length) {
      return SafeArea(
        child: _ReviewCompleteView(
          reviewCount: _dueWords.length,
          onReviewAgain: _loadReviews,
        ),
      );
    }

    final current = _dueWords[_currentIndex];

    final progress = (_currentIndex + 1) / _dueWords.length;

    final selectedCorrect =
        _selectedAnswer != null &&
        _selectedAnswer!.toLowerCase() == current.word.toLowerCase();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Review 🧠',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              '${_currentIndex + 1} of ${_dueWords.length}',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 16),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),

            const SizedBox(height: 36),

            const Text(
              'What is this in English?',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),

            const SizedBox(height: 16),

            Center(
              child: Text(
                current.vietnamese,
                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),

            const SizedBox(height: 36),

            Expanded(
              child: ListView.separated(
                itemCount: _answers.length,

                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),

                itemBuilder: (context, index) {
                  final answer = _answers[index];

                  Color? backgroundColor;

                  Color? foregroundColor;

                  if (_answered) {
                    if (answer.toLowerCase() == current.word.toLowerCase()) {
                      backgroundColor = Colors.green.shade100;

                      foregroundColor = Colors.green.shade800;
                    } else if (answer == _selectedAnswer) {
                      backgroundColor = Colors.red.shade100;

                      foregroundColor = Colors.red.shade800;
                    }
                  }

                  return SizedBox(
                    width: double.infinity,

                    child: OutlinedButton(
                      onPressed: () {
                        _selectAnswer(answer);
                      },

                      style: OutlinedButton.styleFrom(
                        backgroundColor: backgroundColor,

                        foregroundColor: foregroundColor,

                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 16,
                        ),
                      ),

                      child: Text(answer, style: const TextStyle(fontSize: 18)),
                    ),
                  );
                },
              ),
            ),

            if (_answered) ...[
              const SizedBox(height: 12),

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: selectedCorrect
                      ? Colors.green.shade50
                      : Colors.orange.shade50,

                  borderRadius: BorderRadius.circular(16),
                ),

                child: Column(
                  children: [
                    Text(
                      selectedCorrect
                          ? 'Correct! 🎉 +5 XP'
                          : 'Not quite — the answer is ${current.word}. +1 XP',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    if (_resultMasteryLevel != null) ...[
                      const SizedBox(height: 8),

                      Text(
                        'Mastery: $_resultMasteryLevel/5 • '
                        '${getMasteryLabel(_resultMasteryLevel!)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Text(current.example, textAlign: TextAlign.center),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,

                child: FilledButton(
                  onPressed: _nextQuestion,

                  child: Text(
                    _currentIndex + 1 == _dueWords.length
                        ? 'Finish Review'
                        : 'Next Word',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoReviewsView extends StatelessWidget {
  const _NoReviewsView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),

      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Text('🎉', style: TextStyle(fontSize: 70)),

            SizedBox(height: 20),

            Text(
              'You are all caught up!',
              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            Text(
              'No words are due for review right now.',
              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCompleteView extends StatelessWidget {
  final int reviewCount;

  final Future<void> Function() onReviewAgain;

  const _ReviewCompleteView({
    required this.reviewCount,
    required this.onReviewAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),

      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Text('🏆', style: TextStyle(fontSize: 70)),

            const SizedBox(height: 20),

            const Text(
              'Review complete!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              'You reviewed $reviewCount words.',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: () {
                onReviewAgain();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }
}
