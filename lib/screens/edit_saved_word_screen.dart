import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class EditSavedWordScreen extends StatefulWidget {
  final String documentId;

  final String word;
  final String vietnamese;
  final String example;

  const EditSavedWordScreen({
    super.key,
    required this.documentId,
    required this.word,
    required this.vietnamese,
    required this.example,
  });

  @override
  State<EditSavedWordScreen> createState() => _EditSavedWordScreenState();
}

class _EditSavedWordScreenState extends State<EditSavedWordScreen> {
  late final TextEditingController _wordController;

  late final TextEditingController _vietnameseController;

  late final TextEditingController _exampleController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _wordController = TextEditingController(text: widget.word);

    _vietnameseController = TextEditingController(text: widget.vietnamese);

    _exampleController = TextEditingController(text: widget.example);
  }

  Future<void> _save() async {
    if (_wordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an English word.')),
      );

      return;
    }

    try {
      setState(() {
        _saving = true;
      });

      await updateSavedWord(
        documentId: widget.documentId,
        word: _wordController.text,
        vietnamese: _vietnameseController.text,
        example: _exampleController.text,
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not update word: $e')));
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _vietnameseController.dispose();
    _exampleController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Word')),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                'English',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _wordController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 22),

              const Text(
                'Vietnamese',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _vietnameseController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 22),

              const Text(
                'Example sentence',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _exampleController,
                maxLines: 3,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
