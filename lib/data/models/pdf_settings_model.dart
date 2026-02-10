import 'package:pdf/pdf.dart';

class PdfSettings {
  final PdfPageFormat pageFormat;
  final double margin;
  final bool passwordProtected;
  final String? password;
  final bool enableOcr;
  final String? watermarkText;

  const PdfSettings({
    this.pageFormat = PdfPageFormat.a4,
    this.margin = 10.0,
    this.passwordProtected = false,
    this.password,
    this.enableOcr = false,
    this.watermarkText,
  });

  PdfSettings copyWith({
    PdfPageFormat? pageFormat,
    double? margin,
    bool? passwordProtected,
    String? password,
    bool? enableOcr,
    String? watermarkText,
  }) {
    return PdfSettings(
      pageFormat: pageFormat ?? this.pageFormat,
      margin: margin ?? this.margin,
      passwordProtected: passwordProtected ?? this.passwordProtected,
      password: password ?? this.password,
      enableOcr: enableOcr ?? this.enableOcr,
      watermarkText: watermarkText ?? this.watermarkText,
    );
  }
}
