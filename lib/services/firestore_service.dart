import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

CollectionReference<Map<String, dynamic>> getUserWordsCollection() {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('No Firebase user is signed in.');
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('words');
}

String createWordDocumentId(String word) {
  return word.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

Future<void> updateSavedWord({
  required String documentId,
  required String word,
  required String vietnamese,
  required String example,
}) async {
  final cleanWord = word.trim();

  if (cleanWord.isEmpty) {
    throw Exception('The English word cannot be empty.');
  }

  final collection = getUserWordsCollection();

  final oldDocument = collection.doc(documentId);

  final newDocumentId = createWordDocumentId(cleanWord);

  final newDocument = collection.doc(newDocumentId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final oldSnapshot = await transaction.get(oldDocument);

    if (!oldSnapshot.exists) {
      throw Exception('This word no longer exists.');
    }

    final oldData = oldSnapshot.data()!;

    // The English word did not change
    // enough to change its document ID.
    if (newDocumentId == documentId) {
      transaction.update(oldDocument, {
        'word': cleanWord,
        'vietnamese': vietnamese.trim(),
        'example': example.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return;
    }

    // English word changed.
    // Make sure the new word isn't
    // already saved.
    final existingNewWord = await transaction.get(newDocument);

    if (existingNewWord.exists) {
      throw Exception('You already have "$cleanWord" in My Words.');
    }

    final updatedData = <String, dynamic>{
      ...oldData,
      'word': cleanWord,
      'vietnamese': vietnamese.trim(),
      'example': example.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    transaction.set(newDocument, updatedData);

    transaction.delete(oldDocument);
  });
}

Future<void> deleteSavedWord(String documentId) async {
  await getUserWordsCollection().doc(documentId).delete();
}
