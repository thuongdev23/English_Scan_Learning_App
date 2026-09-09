import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

class ReviewWord {
  final String id;
  final String word;
  final String vietnamese;
  final String example;
  final String? imagePath;
  final int masteryLevel;

  ReviewWord({
    required this.id,
    required this.word,
    required this.vietnamese,
    required this.example,
    required this.masteryLevel,
    this.imagePath,
  });

  factory ReviewWord.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return ReviewWord(
      id: document.id,
      word: data['word'] as String? ?? 'Unknown',
      vietnamese: data['vietnamese'] as String? ?? '',
      example: data['example'] as String? ?? '',
      imagePath: data['localImagePath'] as String?,
      masteryLevel: (data['masteryLevel'] as num?)?.toInt() ?? 0,
    );
  }
}

Future<List<ReviewWord>> getAllSavedWords() async {
  final snapshot = await getUserWordsCollection().get();

  return snapshot.docs.map(ReviewWord.fromDocument).toList();
}

Future<List<ReviewWord>> getDueReviewWords() async {
  final snapshot = await getUserWordsCollection().get();

  final now = DateTime.now();

  return snapshot.docs
      .where((document) {
        final data = document.data();

        final nextReview = data['nextReviewAt'];

        // Old words created before our review system
        // should also become reviewable.
        if (nextReview == null) {
          return true;
        }

        if (nextReview is Timestamp) {
          return !nextReview.toDate().isAfter(now);
        }

        return true;
      })
      .map(ReviewWord.fromDocument)
      .toList();
}

int _daysForMasteryLevel(int level) {
  switch (level) {
    case 1:
      return 1;

    case 2:
      return 3;

    case 3:
      return 7;

    case 4:
      return 14;

    case 5:
      return 30;

    default:
      return 1;
  }
}

Future<void> submitReviewResult({
  required ReviewWord reviewWord,
  required bool isCorrect,
}) async {
  final document = getUserWordsCollection().doc(reviewWord.id);

  int newLevel;

  if (isCorrect) {
    newLevel = (reviewWord.masteryLevel + 1).clamp(0, 5);
  } else {
    newLevel = (reviewWord.masteryLevel - 1).clamp(0, 5);
  }

  final days = _daysForMasteryLevel(newLevel);

  final nextReview = DateTime.now().add(Duration(days: days));

  await document.update({
    'masteryLevel': newLevel,

    'lastReviewedAt': FieldValue.serverTimestamp(),

    'nextReviewAt': Timestamp.fromDate(nextReview),

    if (isCorrect) 'correctReviews': FieldValue.increment(1),

    if (!isCorrect) 'incorrectReviews': FieldValue.increment(1),
  });
}

String getMasteryLabel(int masteryLevel) {
  if (masteryLevel >= 4) {
    return 'Mastered';
  }

  if (masteryLevel >= 1) {
    return 'Learning';
  }

  return 'New';
}

double getMasteryProgress(int masteryLevel) {
  final safeLevel = masteryLevel.clamp(0, 5);

  return safeLevel / 5.0;
}

bool isMastered(int masteryLevel) {
  return masteryLevel >= 4;
}

int countDueReviewWords(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
) {
  final now = DateTime.now();

  return documents.where((document) {
    final data = document.data();

    final nextReviewAt = data['nextReviewAt'];

    // Older words without review data
    // should be reviewed immediately.
    if (nextReviewAt == null) {
      return true;
    }

    if (nextReviewAt is Timestamp) {
      return !nextReviewAt.toDate().isAfter(now);
    }

    return true;
  }).length;
}
