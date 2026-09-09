import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

DocumentReference<Map<String, dynamic>> getUserProfileDocument() {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('No Firebase user is signed in.');
  }

  return FirebaseFirestore.instance.collection('users').doc(user.uid);
}

Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserProfile() {
  return getUserProfileDocument().snapshots();
}

Future<void> saveUserProfile({
  required String displayName,
  required int dailyGoal,
}) async {
  await getUserProfileDocument().set({
    'displayName': displayName.trim(),
    'dailyGoal': dailyGoal,
    'onboardingComplete': true,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
