import 'dart:ui';

/// The type of annotation tool.
enum AnnotationTool { draw, text, highlight }

/// Base class for all PDF annotations.
sealed class PdfAnnotation {
  final int pageIndex;
  final Color color;

  const PdfAnnotation({required this.pageIndex, required this.color});
}

/// Freehand drawing annotation — a list of points forming a stroke.
class DrawingAnnotation extends PdfAnnotation {
  final List<Offset> points;
  final double strokeWidth;

  const DrawingAnnotation({
    required super.pageIndex,
    required super.color,
    required this.points,
    this.strokeWidth = 3.0,
  });
}

/// Text annotation placed at a specific position on the page.
class TextAnnotation extends PdfAnnotation {
  final Offset position;
  final String text;
  final double fontSize;

  const TextAnnotation({
    required super.pageIndex,
    required super.color,
    required this.position,
    required this.text,
    this.fontSize = 16.0,
  });
}

/// Highlight rectangle annotation.
class HighlightAnnotation extends PdfAnnotation {
  final Rect rect;
  final double opacity;

  const HighlightAnnotation({
    required super.pageIndex,
    required super.color,
    required this.rect,
    this.opacity = 0.35,
  });
}
