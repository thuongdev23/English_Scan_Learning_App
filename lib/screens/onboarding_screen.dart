import 'package:flutter/material.dart';

import '../services/user_profile_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();

  int _dailyGoal = 10;
  bool _isSaving = false;

  final List<int> _goalOptions = [5, 10, 15, 20];

  Future<void> _finishOnboarding() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name.')));

      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      await saveUserProfile(displayName: name, dailyGoal: _dailyGoal);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save profile: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 40),

              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.deepPurple,
                  size: 34,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Welcome to WordAround 👋',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                'Learn English from the world around you.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),

              const SizedBox(height: 40),

              const Text(
                'What should we call you?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Your name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              const Text(
                'Choose your daily goal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 6),

              const Text(
                'How many new things do you want to learn each day?',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 18),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _goalOptions.map((goal) {
                  final selected = _dailyGoal == goal;

                  return ChoiceChip(
                    label: Text('$goal words'),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _dailyGoal = goal;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  children: [
                    _OnboardingStep(
                      icon: Icons.camera_alt,
                      title: 'Scan',
                      text: 'Point your camera at something around you.',
                    ),

                    SizedBox(height: 16),

                    _OnboardingStep(
                      icon: Icons.school,
                      title: 'Learn',
                      text: 'Discover its English name and pronunciation.',
                    ),

                    SizedBox(height: 16),

                    _OnboardingStep(
                      icon: Icons.psychology,
                      title: 'Review',
                      text: 'Practice again later so you remember it.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _finishOnboarding,

                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),

                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Start Learning'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepPurple),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 3),

              Text(text, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}
