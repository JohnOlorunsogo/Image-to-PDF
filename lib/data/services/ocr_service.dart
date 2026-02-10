import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<RecognizedText> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText;
    } catch (e) {
      rethrow;
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
