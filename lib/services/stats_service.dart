import 'package:cloud_firestore/cloud_firestore.dart';

int calculateLifetimeXp(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
) {
  int total = 0;

  for (final document in documents) {
    final data = document.data();

    total += (data['xp'] as num?)?.toInt() ?? 0;
  }

  return total;
}

int calculateMasteredWords(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
) {
  return documents.where((document) {
    final data = document.data();

    final masteryLevel = (data['masteryLevel'] as num?)?.toInt() ?? 0;

    return masteryLevel >= 4;
  }).length;
}

int calculateLearningWords(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
) {
  return documents.where((document) {
    final data = document.data();

    final masteryLevel = (data['masteryLevel'] as num?)?.toInt() ?? 0;

    return masteryLevel >= 1 && masteryLevel < 4;
  }).length;
}

int calculateTotalReviews(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
) {
  int total = 0;

  for (final document in documents) {
    final data = document.data();

    final correct = (data['correctReviews'] as num?)?.toInt() ?? 0;

    final incorrect = (data['incorrectReviews'] as num?)?.toInt() ?? 0;

    total += correct + incorrect;
  }

  return total;
}

int calculateCorrectReviews(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
) {
  int total = 0;

  for (final document in documents) {
    final data = document.data();

    total += (data['correctReviews'] as num?)?.toInt() ?? 0;
  }

  return total;
}

int calculateReviewAccuracy(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
) {
  final totalReviews = calculateTotalReviews(documents);

  if (totalReviews == 0) {
    return 0;
  }

  final correctReviews = calculateCorrectReviews(documents);

  return ((correctReviews / totalReviews) * 100).round();
}
