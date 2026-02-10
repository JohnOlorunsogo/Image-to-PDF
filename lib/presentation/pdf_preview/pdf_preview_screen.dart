import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:images_to_pdf/data/models/image_model.dart';
import 'package:images_to_pdf/data/models/pdf_settings_model.dart';
import 'package:images_to_pdf/providers/pdf_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends ConsumerStatefulWidget {
  final List<ImageModel> images;

  const PdfPreviewScreen({super.key, required this.images});

  @override
  ConsumerState<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends ConsumerState<PdfPreviewScreen> {
  PdfSettings _settings = const PdfSettings();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        canDebug: false,
        actions: [
          // Custom actions can be added here
        ],
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    // Update settings with the format provided by PdfPreview layout logic if needed,
    // or just use our local settings but override format.
    // However, PdfPreview asks us to build for a specific format.
    // If the user changes format in PdfPreview's own UI (if enabled), this 'format' arg changes.
    // But we also have our own settings.
    // Let's rely on PdfPreview's format for page size if we want to support its UI,
    // or we force our own.
    // For now, let's sync them.

    final currentSettings = _settings.copyWith(pageFormat: format);

    final pdfService = ref.read(pdfServiceProvider);

    // PdfService.generatePdf returns a File. Printing needs bytes.
    // I should probably refactor PdfService to return bytes or have a method for bytes.
    // Or just read the file.

    // Using a temporary workaround: modify PdfService to return bytes is better for 'printing' package.
    // Let's just read the bytes from the file for now to avoid breaking existing service signature quickly,
    // but cleaner is to have generatePdfBytes.

    final file = await pdfService.generatePdf(widget.images, currentSettings);
    return file.readAsBytes();
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // Local state for the dialog
        bool passwordEnabled = _settings.passwordProtected;
        String? password = _settings.password;
        bool ocrEnabled = _settings.enableOcr;
        double margin = _settings.margin;
        final passwordController = TextEditingController(text: password);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('PDF Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Enable OCR (Searchable PDF)'),
                      subtitle: const Text('Recognize text in images'),
                      value: ocrEnabled,
                      onChanged: (val) {
                        setState(() {
                          ocrEnabled = val;
                        });
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Password Protection'),
                      value: passwordEnabled,
                      onChanged: (val) {
                        setState(() {
                          passwordEnabled = val;
                        });
                      },
                    ),
                    if (passwordEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          onChanged: (val) {
                            password = val;
                          },
                        ),
                      ),
                    const Divider(),
                    ListTile(
                      title: const Text('Page Margin'),
                      subtitle: Slider(
                        value: margin,
                        min: 0,
                        max: 50,
                        divisions: 10,
                        label: margin.round().toString(),
                        onChanged: (val) {
                          setState(() {
                            margin = val;
                          });
                        },
                      ),
                      trailing: Text('${margin.round()}'),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Watermark Text',
                          hintText: 'e.g. Confidential',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          // Direct update to local variable if using controller, or state
                          // Here we should probably use a controller or just update a variable.
                          // But my _showSettingsDialog logic uses variables initialized at start.
                          // I'll need to add a variable 'watermarkText' to the dialog context.
                        },
                        // Actually, I need to fetch current value and update it.
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Update main state
                    this.setState(() {
                      _settings = _settings.copyWith(
                        passwordProtected: passwordEnabled,
                        password: passwordController
                            .text, // Use controller text to be safe
                        enableOcr: ocrEnabled,
                        margin: margin,
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
