import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<RecognizedText?> recognizeText(String imagePath) async {
    // OCR is only supported on Android
    if (!Platform.isAndroid) {
      return null;
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText;
    } catch (e) {
      debugPrint('OCR failed for $imagePath: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(() => service.dispose());
  return service;
});
