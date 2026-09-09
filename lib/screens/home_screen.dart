import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../services/progress_service.dart';
import '../services/review_service.dart';
import '../widgets/progress_card.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onStartScanning;
  final VoidCallback onStartReview;

  final String displayName;
  final int dailyGoal;

  const HomeScreen({
    super.key,
    required this.onStartScanning,
    required this.onStartReview,
    required this.displayName,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: watchTodayProgress(),
      builder: (context, progressSnapshot) {
        final progressData = progressSnapshot.data?.data();

        final wordsToday =
            (progressData?['wordsLearned'] as num?)?.toInt() ?? 0;

        final xpToday = (progressData?['xp'] as num?)?.toInt() ?? 0;

        final completedToday = wordsToday.clamp(0, dailyGoal);

        final progress = dailyGoal == 0 ? 0.0 : completedToday / dailyGoal;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: getUserWordsCollection().snapshots(),
          builder: (context, wordsSnapshot) {
            final wordDocuments = wordsSnapshot.data?.docs ?? [];

            final totalWords = wordDocuments.length;

            final dueReviewCount = countDueReviewWords(wordDocuments);

            final masteredWords = wordDocuments.where((document) {
              final data = document.data();

              final masteryLevel = (data['masteryLevel'] as num?)?.toInt() ?? 0;

              return masteryLevel >= 4;
            }).length;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: watchDailyProgress(),
              builder: (context, streakSnapshot) {
                final streak = calculateCurrentStreak(
                  streakSnapshot.data?.docs ?? [],
                );

                return SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // HEADER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Good morning 👋',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.deepPurple.shade100,
                              child: const Icon(
                                Icons.person,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // STREAK CARD
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF8E86FF)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '🔥',
                                    style: TextStyle(fontSize: 28),
                                  ),

                                  const SizedBox(width: 10),

                                  Text(
                                    streak == 1
                                        ? '1 day streak'
                                        : '$streak day streak',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              Text(
                                streak == 0
                                    ? 'Learn your first word today to start a streak!'
                                    : 'Keep learning every day!',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // REVIEW CARD
                        if (dueReviewCount > 0) ...[
                          const SizedBox(height: 20),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.deepPurple.shade100,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade100,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.psychology,
                                        color: Colors.deepPurple,
                                      ),
                                    ),

                                    const SizedBox(width: 14),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Time to Review 🧠',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          Text(
                                            dueReviewCount == 1
                                                ? '1 word is ready for practice'
                                                : '$dueReviewCount words are ready for practice',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: onStartReview,
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Start Review'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // TODAY'S CHALLENGE
                        const Text(
                          "Today's Challenge",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      wordsToday >= dailyGoal
                                          ? 'Daily goal completed! 🎉'
                                          : 'Learn $dailyGoal things around you',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Text(
                                    '$completedToday / $dailyGoal',
                                    style: const TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 10,
                                ),
                              ),

                              const SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: onStartScanning,
                                  icon: const Icon(Icons.camera_alt),
                                  label: Text(
                                    wordsToday >= dailyGoal
                                        ? 'Keep Learning'
                                        : 'Learn Something',
                                  ),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // PROGRESS
                        const Text(
                          'Your Progress',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: ProgressCard(
                                number: '$totalWords',
                                label: 'Words learned',
                                icon: Icons.menu_book,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: ProgressCard(
                                number: '$masteredWords',
                                label: 'Mastered',
                                icon: Icons.star,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: ProgressCard(
                                number: '$wordsToday',
                                label: 'Learned today',
                                icon: Icons.today,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: ProgressCard(
                                number: '$xpToday',
                                label: 'XP today',
                                icon: Icons.bolt,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: ProgressCard(
                                number: '$completedToday/$dailyGoal',
                                label: 'Daily goal',
                                icon: Icons.flag,
                              ),
                            ),

                            const SizedBox(width: 12),

                            const Expanded(
                              child: ProgressCard(
                                number: 'English',
                                label: 'Learning',
                                icon: Icons.language,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
