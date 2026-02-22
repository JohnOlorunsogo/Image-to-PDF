import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:images_to_pdf/data/models/pdf_annotation_model.dart';
import 'package:images_to_pdf/data/services/pdf_editor_service.dart';

/// Provides a singleton [PdfEditorService].
final pdfEditorServiceProvider = Provider<PdfEditorService>((ref) {
  return PdfEditorService();
});

/// Manages annotations per page index.
final pdfAnnotationsProvider =
    NotifierProvider<PdfAnnotationsNotifier, Map<int, List<PdfAnnotation>>>(
      () => PdfAnnotationsNotifier(),
    );

class PdfAnnotationsNotifier extends Notifier<Map<int, List<PdfAnnotation>>> {
  @override
  Map<int, List<PdfAnnotation>> build() => {};

  void addAnnotation(int pageIndex, PdfAnnotation annotation) {
    final current = {...state};
    current[pageIndex] = [...(current[pageIndex] ?? []), annotation];
    state = current;
  }

  void undoLastAnnotation(int pageIndex) {
    final current = {...state};
    final list = current[pageIndex];
    if (list != null && list.isNotEmpty) {
      current[pageIndex] = list.sublist(0, list.length - 1);
      state = current;
    }
  }

  void clearPage(int pageIndex) {
    final current = {...state};
    current[pageIndex] = [];
    state = current;
  }

  void clearAll() {
    state = {};
  }
}
