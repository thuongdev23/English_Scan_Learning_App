import 'package:flutter/material.dart';

import '../services/user_profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final int initialDailyGoal;

  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialDailyGoal,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;

  late int _dailyGoal;

  bool _isSaving = false;

  final List<int> _goalOptions = [5, 10, 15, 20];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);

    _dailyGoal = widget.initialDailyGoal;
  }

  Future<void> _saveChanges() async {
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

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save changes: $e')));
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
      appBar: AppBar(title: const Text('Edit Profile')),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your name',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Daily learning goal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              const Text(
                'How many new things would you like to learn each day?',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 18),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _goalOptions.map((goal) {
                  return ChoiceChip(
                    label: Text('$goal words'),
                    selected: _dailyGoal == goal,
                    onSelected: (_) {
                      setState(() {
                        _dailyGoal = goal;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
