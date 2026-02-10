import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:images_to_pdf/data/models/image_model.dart';
import 'package:images_to_pdf/data/models/pdf_settings_model.dart';
import 'package:images_to_pdf/data/services/ocr_service.dart';

class PdfService {
  final OcrService _ocrService;

  PdfService(this._ocrService);

  Future<File> generatePdf(
    List<ImageModel> images,
    PdfSettings settings,
  ) async {
    final pdf = pw.Document();

    for (final image in images) {
      final imageFile = File(image.path);
      final imageBytes = await imageFile.readAsBytes();
      final pdfImage = pw.MemoryImage(imageBytes);

      RecognizedText? recognizedText;
      if (settings.enableOcr) {
        try {
          recognizedText = await _ocrService.recognizeText(image.path);
        } catch (e) {
          // Ignore OCR errors, proceed with image only
          debugPrint('OCR failed for ${image.path}: $e');
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: settings.pageFormat,
          margin: pw.EdgeInsets.all(settings.margin),
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain)),
                if (recognizedText != null)
                  pw.Opacity(
                    opacity: 0.0,
                    child: pw.Text(
                      recognizedText.text,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                if (settings.watermarkText != null &&
                    settings.watermarkText!.isNotEmpty)
                  pw.Center(
                    child: pw.Transform.rotate(
                      angle: -0.5,
                      child: pw.Opacity(
                        opacity: 0.2,
                        child: pw.Text(
                          settings.watermarkText!,
                          style: pw.TextStyle(
                            fontSize: 40,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/generated_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
