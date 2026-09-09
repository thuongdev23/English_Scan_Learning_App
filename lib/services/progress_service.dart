import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String getDateId(DateTime date) {
  final year = date.year.toString();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}

String getTodayDateId() {
  return getDateId(DateTime.now());
}

CollectionReference<Map<String, dynamic>> getDailyProgressCollection() {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('No Firebase user is signed in.');
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('daily_progress');
}

DocumentReference<Map<String, dynamic>> getTodayProgressDocument() {
  return getDailyProgressCollection().doc(getTodayDateId());
}

Stream<DocumentSnapshot<Map<String, dynamic>>> watchTodayProgress() {
  return getTodayProgressDocument().snapshots();
}

Stream<QuerySnapshot<Map<String, dynamic>>> watchDailyProgress() {
  return getDailyProgressCollection()
      .orderBy('date', descending: true)
      .limit(60)
      .snapshots();
}

Stream<QuerySnapshot<Map<String, dynamic>>> watchAllDailyProgress() {
  return getDailyProgressCollection().snapshots();
}

Future<void> addProgressForNewWord() async {
  final document = getTodayProgressDocument();

  await document.set({
    'date': getTodayDateId(),
    'wordsLearned': FieldValue.increment(1),
    'xp': FieldValue.increment(10),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

int calculateCurrentStreak(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
) {
  if (documents.isEmpty) {
    return 0;
  }

  final activeDates = <String>{};

  for (final document in documents) {
    final data = document.data();

    final wordsLearned = (data['wordsLearned'] as num?)?.toInt() ?? 0;

    if (wordsLearned > 0) {
      activeDates.add(document.id);
    }
  }

  if (activeDates.isEmpty) {
    return 0;
  }

  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  final yesterday = today.subtract(const Duration(days: 1));

  DateTime currentDate;

  // If the learner has already studied today,
  // begin counting from today.
  if (activeDates.contains(getDateId(today))) {
    currentDate = today;
  }
  // If they haven't studied today yet,
  // preserve the streak from yesterday.
  else if (activeDates.contains(getDateId(yesterday))) {
    currentDate = yesterday;
  }
  // Neither today nor yesterday contains
  // activity, so the streak is broken.
  else {
    return 0;
  }

  int streak = 0;

  while (activeDates.contains(getDateId(currentDate))) {
    streak++;

    currentDate = currentDate.subtract(const Duration(days: 1));
  }

  return streak;
}

Future<void> addXpForReview({required bool isCorrect}) async {
  final document = getTodayProgressDocument();

  final xpAmount = isCorrect ? 5 : 1;

  await document.set({
    'date': getTodayDateId(),

    'xp': FieldValue.increment(xpAmount),

    'reviewsCompleted': FieldValue.increment(1),

    if (isCorrect) 'correctReviews': FieldValue.increment(1),

    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
