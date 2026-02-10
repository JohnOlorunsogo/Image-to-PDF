import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:images_to_pdf/data/services/ocr_service.dart';
import 'package:images_to_pdf/data/services/pdf_service.dart';

final pdfServiceProvider = Provider<PdfService>((ref) {
  final ocrService = ref.read(ocrServiceProvider);
  return PdfService(ocrService);
});
