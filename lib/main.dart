import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/starter_vocabulary.dart';
import 'firebase_options.dart';
import 'screens/app_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeVocabulary();

  runApp(const WordAroundApp());
}

class WordAroundApp extends StatelessWidget {
  const WordAroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WordAround',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),

        scaffoldBackgroundColor: const Color(0xFFF8F8FC),
      ),

      home: const AppGate(),
    );
  }
}
