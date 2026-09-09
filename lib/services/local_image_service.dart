import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalImageService {
  Future<String?> saveImage(String? temporaryPath, String word) async {
    if (temporaryPath == null) {
      return null;
    }

    final originalFile = File(temporaryPath);

    if (!await originalFile.exists()) {
      return null;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();

    final imageDirectory = Directory('${documentsDirectory.path}/word_images');

    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }

    final safeWord = word.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );

    final extension = temporaryPath.toLowerCase().endsWith('.png')
        ? 'png'
        : 'jpg';

    final newPath =
        '${imageDirectory.path}/${safeWord}_${DateTime.now().millisecondsSinceEpoch}.$extension';

    final savedFile = await originalFile.copy(newPath);

    return savedFile.path;
  }
}

final localImageService = LocalImageService();
