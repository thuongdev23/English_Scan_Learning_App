import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/progress_service.dart';
import '../services/stats_service.dart';
import '../services/user_profile_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: getUserWordsCollection().snapshots(),
      builder: (context, wordsSnapshot) {
        final wordDocuments = wordsSnapshot.data?.docs ?? [];

        final totalWords = wordDocuments.length;

        final masteredWords = calculateMasteredWords(wordDocuments);

        final learningWords = calculateLearningWords(wordDocuments);

        final totalReviews = calculateTotalReviews(wordDocuments);

        final correctReviews = calculateCorrectReviews(wordDocuments);

        final reviewAccuracy = calculateReviewAccuracy(wordDocuments);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: watchAllDailyProgress(),
          builder: (context, progressSnapshot) {
            final progressDocuments = progressSnapshot.data?.docs ?? [];

            final lifetimeXp = calculateLifetimeXp(progressDocuments);

            final streak = calculateCurrentStreak(progressDocuments);

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // ---------------------------------
                    // PROFILE HEADER
                    // ---------------------------------
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: watchUserProfile(),
                      builder: (context, profileSnapshot) {
                        final profile = profileSnapshot.data?.data();

                        final displayName =
                            profile?['displayName'] as String? ?? 'Learner';

                        final dailyGoal =
                            (profile?['dailyGoal'] as num?)?.toInt() ?? 10;

                        return Column(
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 46,
                                    backgroundColor: Colors.deepPurple.shade100,
                                    child: const Icon(
                                      Icons.person,
                                      size: 46,
                                      color: Colors.deepPurple,
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    '$dailyGoal words per day',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProfileScreen(
                                        initialName: displayName,
                                        initialDailyGoal: dailyGoal,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit Profile'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // ---------------------------------
                    // ACCOUNT / AUTH
                    // ---------------------------------
                    const _AccountSecurityCard(),

                    const SizedBox(height: 32),

                    // ---------------------------------
                    // LEARNING PROGRESS
                    // ---------------------------------
                    const Text(
                      'Learning Progress',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _ProfileStatCard(
                      icon: Icons.local_fire_department,
                      title: 'Current streak',
                      value: '$streak ${streak == 1 ? 'day' : 'days'}',
                    ),

                    const SizedBox(height: 12),

                    _ProfileStatCard(
                      icon: Icons.star,
                      title: 'Mastered',
                      value: '$masteredWords',
                    ),

                    const SizedBox(height: 12),

                    _ProfileStatCard(
                      icon: Icons.menu_book,
                      title: 'Total words',
                      value: '$totalWords',
                    ),

                    const SizedBox(height: 12),

                    _ProfileStatCard(
                      icon: Icons.bolt,
                      title: 'Lifetime XP',
                      value: '$lifetimeXp',
                    ),

                    const SizedBox(height: 32),

                    // ---------------------------------
                    // REVIEW STATISTICS
                    // ---------------------------------
                    const Text(
                      'Review Statistics',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _StatRow(
                            label: 'Reviews completed',
                            value: '$totalReviews',
                          ),

                          const Divider(height: 28),

                          _StatRow(
                            label: 'Correct answers',
                            value: '$correctReviews',
                          ),

                          const Divider(height: 28),

                          _StatRow(
                            label: 'Accuracy',
                            value: '$reviewAccuracy%',
                          ),

                          const Divider(height: 28),

                          _StatRow(
                            label: 'Learning words',
                            value: '$learningWords',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ---------------------------------
                    // SETTINGS
                    // ---------------------------------
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // DAILY GOAL
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: watchUserProfile(),
                            builder: (context, snapshot) {
                              final data = snapshot.data?.data();

                              final dailyGoal =
                                  (data?['dailyGoal'] as num?)?.toInt() ?? 10;

                              return ListTile(
                                leading: const Icon(Icons.flag_outlined),
                                title: const Text('Daily goal'),
                                subtitle: Text('$dailyGoal words per day'),
                              );
                            },
                          ),

                          const Divider(height: 1),

                          ListTile(
                            leading: const Icon(Icons.language),
                            title: const Text('Learning language'),
                            subtitle: const Text('English'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {},
                          ),

                          const Divider(height: 1),

                          ListTile(
                            leading: const Icon(Icons.translate),
                            title: const Text('Native language'),
                            subtitle: const Text('Vietnamese'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {},
                          ),
                        ],
                      ),
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
  }
}

// =====================================================
// PROFILE STAT CARD
// =====================================================

class _ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileStatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.deepPurple),
          ),

          const SizedBox(width: 16),

          Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),

          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// ACCOUNT SECURITY CARD
// =====================================================

class _AccountSecurityCard extends StatefulWidget {
  const _AccountSecurityCard();

  @override
  State<_AccountSecurityCard> createState() => _AccountSecurityCardState();
}

class _AccountSecurityCardState extends State<_AccountSecurityCard> {
  bool _isLinking = false;

  // ---------------------------------------------------
  // LINK ANONYMOUS ACCOUNT WITH GOOGLE
  // ---------------------------------------------------

  Future<void> _linkGoogle() async {
    final beforeUser = FirebaseAuth.instance.currentUser;

    if (beforeUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Firebase user is signed in.')),
      );

      return;
    }

    final beforeUid = beforeUser.uid;

    debugPrint('UID before Google link: $beforeUid');

    try {
      setState(() {
        _isLinking = true;
      });

      await authService.linkAnonymousWithGoogle();

      await FirebaseAuth.instance.currentUser?.reload();

      final afterUser = FirebaseAuth.instance.currentUser;

      final afterUid = afterUser?.uid;

      debugPrint('UID after Google link: $afterUid');

      if (!mounted) return;

      if (beforeUid == afterUid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress secured with Google! ✅')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google was connected, but the account ID changed unexpectedly.',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'provider-already-linked':
          message = 'Google is already connected to this account.';
          break;

        case 'credential-already-in-use':
          message = 'This Google account is already connected to another WordAround account.';
          break;

        case 'invalid-credential':
          message = 'Google sign-in could not be verified.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection and try again.';
          break;

        default:
          message = e.message ?? 'Could not connect Google.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Google sign-in failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLinking = false;
        });
      }
    }
  }

  // ---------------------------------------------------
  // SIGN OUT DIALOG
  // ---------------------------------------------------

  Future<void> _showSignOutDialog(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'You can sign back in anytime to continue your progress.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true) {
      return;
    }

    try {
      await authService.signOut();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not sign out: $e')));
    }
  }

  // ---------------------------------------------------
  // BUILD
  // ---------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;

        final isAnonymous = user?.isAnonymous ?? true;

        final hasGoogle =
            user?.providerData.any(
              (provider) =>
                  provider.providerId == GoogleAuthProvider.PROVIDER_ID,
            ) ??
            false;

        // ---------------------------------------------
        // SIGNED-IN / SECURED USER
        // ---------------------------------------------

        if (user != null && !isAnonymous) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.verified_user_outlined,
                        color: Colors.green.shade700,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Progress secured ✅',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            user.email ?? 'Account connected',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            hasGoogle
                                ? 'Connected with Google'
                                : 'Connected with email',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showSignOutDialog(context);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // ---------------------------------------------
        // ANONYMOUS / GUEST USER
        // ---------------------------------------------

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_done_outlined, color: Colors.deepPurple),

                  SizedBox(width: 10),

                  Text(
                    'Secure your progress',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                'Connect a Google account so you can keep your words and progress if you change devices.',
                style: TextStyle(color: Colors.grey.shade700),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLinking ? null : _linkGoogle,
                  icon: _isLinking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(
                    _isLinking ? 'Connecting...' : 'Continue with Google',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =====================================================
// REVIEW STAT ROW
// =====================================================

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
