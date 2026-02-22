import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' hide PdfAnnotation;

import 'package:images_to_pdf/data/models/pdf_annotation_model.dart';

/// Convert a Flutter [Color] to a Syncfusion [PdfColor].
PdfColor _toPdfColor(Color c) {
  return PdfColor(
    (c.r * 255.0).round() & 0xff,
    (c.g * 255.0).round() & 0xff,
    (c.b * 255.0).round() & 0xff,
  );
}

class PdfEditorService {
  /// Saves annotations onto a copy of the source PDF and returns the new file.
  Future<File> saveAnnotatedPdf(
    String sourcePath,
    Map<int, List<PdfAnnotation>> annotationsByPage,
  ) async {
    final sourceBytes = await File(sourcePath).readAsBytes();
    final document = PdfDocument(inputBytes: sourceBytes);

    for (final entry in annotationsByPage.entries) {
      final pageIndex = entry.key;
      final annotations = entry.value;

      if (pageIndex >= document.pages.count) continue;
      final page = document.pages[pageIndex];
      final graphics = page.graphics;
      final pageSize = page.getClientSize();

      for (final annotation in annotations) {
        switch (annotation) {
          case DrawingAnnotation draw:
            _drawStroke(graphics, draw, pageSize);
          case TextAnnotation text:
            _drawText(graphics, text, pageSize);
          case HighlightAnnotation highlight:
            _drawHighlight(graphics, highlight, pageSize);
        }
      }
    }

    final output = Directory.systemTemp;
    final file = File(
      '${output.path}/edited_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    final bytes = await document.save();
    document.dispose();
    await file.writeAsBytes(bytes);
    return file;
  }

  void _drawStroke(
    PdfGraphics graphics,
    DrawingAnnotation draw,
    Size pageSize,
  ) {
    if (draw.points.length < 2) return;

    final pen = PdfPen(
      _toPdfColor(draw.color),
      width: draw.strokeWidth * pageSize.width,
    );
    pen.lineCap = PdfLineCap.round;
    pen.lineJoin = PdfLineJoin.round;

    // Points are stored in normalized coordinates (0..1).
    for (int i = 0; i < draw.points.length - 1; i++) {
      final p1 = draw.points[i];
      final p2 = draw.points[i + 1];
      // A sentinel Offset(-1, -1) marks a break in the stroke.
      if (p1.dx < 0 || p2.dx < 0) continue;
      graphics.drawLine(
        pen,
        Offset(p1.dx * pageSize.width, p1.dy * pageSize.height),
        Offset(p2.dx * pageSize.width, p2.dy * pageSize.height),
      );
    }
  }

  void _drawText(PdfGraphics graphics, TextAnnotation text, Size pageSize) {
    final font = PdfStandardFont(
      PdfFontFamily.helvetica,
      text.fontSize * pageSize.width,
    );
    final brush = PdfSolidBrush(_toPdfColor(text.color));
    graphics.drawString(
      text.text,
      font,
      brush: brush,
      bounds: Rect.fromLTWH(
        text.position.dx * pageSize.width,
        text.position.dy * pageSize.height,
        pageSize.width - (text.position.dx * pageSize.width),
        pageSize.height - (text.position.dy * pageSize.height),
      ),
    );
  }

  void _drawHighlight(
    PdfGraphics graphics,
    HighlightAnnotation highlight,
    Size pageSize,
  ) {
    // Save state, draw semi‑transparent rectangle, restore.
    graphics.save();
    graphics.setTransparency(highlight.opacity);
    final brush = PdfSolidBrush(_toPdfColor(highlight.color));
    graphics.drawRectangle(
      bounds: Rect.fromLTRB(
        highlight.rect.left * pageSize.width,
        highlight.rect.top * pageSize.height,
        highlight.rect.right * pageSize.width,
        highlight.rect.bottom * pageSize.height,
      ),
      brush: brush,
    );
    graphics.restore();
  }
}
