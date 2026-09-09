import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main_navigation.dart';
import 'welcome_screen.dart';

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        // ============================================
        // NOT SIGNED IN
        // ============================================

        if (user == null) {
          return const WelcomeScreen();
        }

        // ============================================
        // USER EXISTS → CHECK PROFILE
        // ============================================

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text(
                    'Could not load profile:\n'
                    '${profileSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final profile = profileSnapshot.data?.data();

            final onboardingComplete = profile?['onboardingComplete'] == true;

            // ============================================
            // COMPLETED USER → HOME
            // ============================================

            if (onboardingComplete) {
              return const MainNavigation();
            }

            // ============================================
            // ANY UNFINISHED USER → WELCOME
            //
            // Anonymous OR email OR Google.
            // Onboarding only opens after the user
            // deliberately presses Continue/Create Account.
            // ============================================

            return const WelcomeScreen();
          },
        );
      },
    );
  }
}
