import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _googleInitialized = false;

  Future<void> _initializeGoogle() async {
    if (_googleInitialized) {
      return;
    }

    await _googleSignIn.initialize();

    _googleInitialized = true;
  }

  //----------------------
  //ensureAnonymousUser()
  //-----------------------
  Future<User> ensureAnonymousUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      return currentUser;
    }

    final result = await FirebaseAuth.instance.signInAnonymously();

    final user = result.user;

    if (user == null) {
      throw Exception('Could not create guest account.');
    }

    return user;
  }

  // -----------------------------------------
  // EMAIL SIGN IN
  // -----------------------------------------

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // -----------------------------------------
  // EMAIL SIGN UP
  // -----------------------------------------

  Future<UserCredential> createAccountWithEmail({
    required String email,
    required String password,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Upgrade anonymous user without
    // changing their Firebase UID.
    if (currentUser != null && currentUser.isAnonymous) {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );

      return currentUser.linkWithCredential(credential);
    }

    return FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // -----------------------------------------
  // GOOGLE SIGN IN
  // -----------------------------------------

  Future<UserCredential> signInWithGoogle() async {
    await _initializeGoogle();

    final googleUser = await _googleSignIn.authenticate();

    final googleAuth = googleUser.authentication;

    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Google did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  // -----------------------------------------
  // LINK GOOGLE TO EXISTING GUEST
  // -----------------------------------------

  Future<UserCredential> linkAnonymousWithGoogle() async {
    await _initializeGoogle();

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception('No Firebase user is signed in.');
    }

    final alreadyLinked = currentUser.providerData.any(
      (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
    );

    if (alreadyLinked) {
      throw FirebaseAuthException(
        code: 'provider-already-linked',
        message: 'Google is already linked to this account.',
      );
    }

    final googleUser = await _googleSignIn.authenticate();

    final googleAuth = googleUser.authentication;

    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Google did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    return currentUser.linkWithCredential(credential);
  }

  // -----------------------------------------
  // PASSWORD RESET
  // -----------------------------------------

  Future<void> sendPasswordResetEmail(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  // -----------------------------------------
  // SIGN OUT
  // -----------------------------------------

  Future<void> signOut() async {
    await _initializeGoogle();

    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // User may not have signed in with Google.
    }

    await FirebaseAuth.instance.signOut();
  }
}

final authService = AuthService();
