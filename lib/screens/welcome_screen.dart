//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_screen.dart';
import '../services/auth_service.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // =====================================================
  // CONTINUE AS GUEST
  // =====================================================

  Future<void> _continueAsGuest(BuildContext context) async {
    try {
      await authService.ensureAnonymousUser();

      if (!context.mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start guest mode: $e')));
    }
  }
  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF2),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),

          child: Column(
            children: [
              const SizedBox(height: 35),

              // =========================================
              // APP NAME
              // =========================================
 Transform.rotate(
  angle: -0.025,
  child: Stack(
    alignment: Alignment.center,
    children: [
      Text(
        'BaoBao',
        style: GoogleFonts.fredoka(
          fontSize: 44,
          fontWeight: FontWeight.w700,
          height: 0.95,
          letterSpacing: -2,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..color = const Color(0xFFFFF8E8),
        ),
      ),
      Text(
        'BaoBao',
        style: GoogleFonts.fredoka(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF287D4F),
          height: 0.95,
          letterSpacing: -2,
          shadows: const [
            Shadow(
              offset: Offset(0, 3),
              blurRadius: 0,
              color: Color(0xFF1F6841),
            ),
            Shadow(
              offset: Offset(0, 5),
              blurRadius: 8,
              color: Color(0x18000000),
            ),
          ],
        ),
      ),
    ],
  ),
),

           const SizedBox(height: 6),

Text(
  'Welcome!',
  textAlign: TextAlign.center,
  style: GoogleFonts.fredoka(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF174E4A),
    height: 1.0,
    letterSpacing: -1.6,
    shadows: const [
      Shadow(
        offset: Offset(0, 2),
        blurRadius: 0,
        color: Color(0x1A174E4A),
      ),
    ],
  ),
),

const SizedBox(height: 10),

Text(
  "Let's learn from the world\naround you!",
  textAlign: TextAlign.center,
  style: GoogleFonts.fredoka(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF5F6F66),
    height: 1.25,
    letterSpacing: -0.2,
  ),
),

const SizedBox(height: 26),
              // =========================================
              // LANGUAGE
              // =========================================
              const Text(
                'Choose your languages',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 18),

              const _LanguageCard(
                flag: '🇬🇧',
                label: 'I want to learn',
                language: 'English',
              ),

              const SizedBox(height: 14),

              const _LanguageCard(
                flag: '🇻🇳',
                label: 'I speak',
                language: 'Tiếng Việt',
              ),

              const SizedBox(height: 35),

              // =========================================
              // ILLUSTRATION
              // =========================================
          SizedBox(
  width: double.infinity,
  height: 185,
  child: Stack(
    alignment: Alignment.center,
    clipBehavior: Clip.none,
    children: [
      // left soft leaf
      Positioned(
        left: 8,
        bottom: 22,
        child: Transform.rotate(
          angle: -0.35,
          child: const Text(
            '🌿',
            style: TextStyle(fontSize: 44),
          ),
        ),
      ),

      // yellow light rays
      Positioned(
        left: 75,
        top: 30,
        child: Transform.rotate(
          angle: -0.55,
          child: Container(
            width: 10,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE27A),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),

      Positioned(
        left: 98,
        top: 22,
        child: Transform.rotate(
          angle: -0.12,
          child: Container(
            width: 10,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE27A),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),

      // right heart
      const Positioned(
        right: 42,
        top: 34,
        child: Text(
          '♥',
          style: TextStyle(
            fontSize: 28,
            color: Color(0xFFF56C78),
          ),
        ),
      ),

      // right small green leaf
      Positioned(
        right: 22,
        bottom: 76,
        child: Transform.rotate(
          angle: 0.55,
          child: Container(
            width: 16,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFA8CF77),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ),

      // mascot
     Positioned(
  bottom: -2,
  left: 0,
  right: 0,
  child: LayoutBuilder(
    builder: (context, constraints) {
      final mascotWidth =
          (constraints.maxWidth * 0.68)
              .clamp(180.0, 260.0);

      return Center(
        child: SizedBox(
          width: mascotWidth,
          child: Image.asset(
            'assets/images/baobao_mascot_trans.png',
            fit: BoxFit.contain,
          ),
        ),
      );
    },
  ),
),
    ],
  ),
),
              // =========================================
              // CONTINUE
              // =========================================
              SizedBox(
                width: double.infinity,
                height: 56,

                child: FilledButton(
                  onPressed: () {
                    _continueAsGuest(context);
                  },

                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF56A944),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // =========================================
              // SIGN IN
              // =========================================
              SizedBox(
                width: double.infinity,
                height: 54,

                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                    );
                  },

                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF174E4A),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: const Text(
                    'Sign in',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // =========================================
              // SIGN UP
              // =========================================
              SizedBox(
                width: double.infinity,
                height: 54,

                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },

                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF287D4F),
                    backgroundColor: const Color(0xFFF3F1E9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: const Text(
                    'Create an account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =========================================
              // GUEST
              // =========================================
              TextButton(
                onPressed: () {
                  _continueAsGuest(context);
                },

                child: Text(
                  'Continue as guest',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =========================================
              // PAGE INDICATORS
              // =========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF56A944),
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// LANGUAGE CARD
// =====================================================

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String label;
  final String language;

  const _LanguageCard({
    required this.flag,
    required this.label,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 32)),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 2),

                Text(
                  language,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF174E4A)),
        ],
      ),
    );
  }
}
