import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'my_words_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';
import 'review_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/user_profile_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  void _goToScan() {
    setState(() {
      currentIndex = 1;
    });
  }

  void _goToReview() {
    setState(() {
      currentIndex = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: watchUserProfile(),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data?.data();

        final displayName = profile?['displayName'] as String? ?? 'Learner';

        final dailyGoal = (profile?['dailyGoal'] as num?)?.toInt() ?? 10;

        final pages = [
          HomeScreen(
            onStartScanning: _goToScan,
            onStartReview: _goToReview,
            displayName: displayName,
            dailyGoal: dailyGoal,
          ),

          const ScanScreen(),
          const MyWordsScreen(),
          const ReviewScreen(),
          const ProfileScreen(),
        ];
        return Scaffold(
          body: pages[currentIndex],

          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,

            onDestinationSelected: (index) {
              setState(() {
                currentIndex = index;
              });
            },

            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),

              NavigationDestination(
                icon: Icon(Icons.camera_alt_outlined),
                selectedIcon: Icon(Icons.camera_alt),
                label: 'Scan',
              ),

              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'My Words',
              ),
              NavigationDestination(
                icon: Icon(Icons.psychology_outlined),
                selectedIcon: Icon(Icons.psychology),
                label: 'Review',
              ),

              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
