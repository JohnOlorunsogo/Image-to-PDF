import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:images_to_pdf/core/theme/app_colors.dart';
import 'package:images_to_pdf/data/models/image_model.dart';
import 'package:images_to_pdf/data/models/pdf_settings_model.dart';
import 'package:images_to_pdf/providers/pdf_provider.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: const Icon(
                IconsaxPlusBold.document_text,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Preview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          // Settings
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(IconsaxPlusLinear.setting_4, size: 20),
              onPressed: () => _showSettingsSheet(context, isDark),
              tooltip: 'PDF Settings',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        canDebug: false,
        canChangeOrientation: false,
        pdfPreviewPageDecoration: BoxDecoration(
          color: isDark ? AppColors.scaffoldDark : AppColors.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final currentSettings = _settings.copyWith(pageFormat: format);
    final pdfService = ref.read(pdfServiceProvider);
    final file = await pdfService.generatePdf(widget.images, currentSettings);
    return file.readAsBytes();
  }

  // ──────────────────────── SETTINGS BOTTOM SHEET ────────────────────────
  void _showSettingsSheet(BuildContext context, bool isDark) {
    bool ocrEnabled = _settings.enableOcr;
    bool passwordEnabled = _settings.passwordProtected;
    String? password = _settings.password;
    double margin = _settings.margin;
    String? watermarkText = _settings.watermarkText;
    final passwordController = TextEditingController(text: password);
    final watermarkController = TextEditingController(text: watermarkText);

    final bool isAndroid = Platform.isAndroid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Header
                      Center(
                        child: Text(
                          'PDF Settings',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── OCR Toggle (Android only) ───
                      if (isAndroid) ...[
                        _SettingTile(
                          icon: IconsaxPlusLinear.text_block,
                          title: 'OCR — Searchable PDF',
                          subtitle: 'Recognize and embed text from images',
                          trailing: Switch.adaptive(
                            value: ocrEnabled,
                            onChanged: (v) =>
                                setSheetState(() => ocrEnabled = v),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // ─── Password ───
                      _SettingTile(
                        icon: IconsaxPlusLinear.lock,
                        title: 'Password Protection',
                        subtitle: 'Encrypt PDF with a password',
                        trailing: Switch.adaptive(
                          value: passwordEnabled,
                          onChanged: (v) =>
                              setSheetState(() => passwordEnabled = v),
                        ),
                      ),
                      if (passwordEnabled) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 44),
                          child: TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Enter password',
                              prefixIcon: Icon(IconsaxPlusLinear.key, size: 18),
                            ),
                            onChanged: (v) => password = v,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),

                      // ─── Margin ───
                      _SettingTile(
                        icon: IconsaxPlusLinear.slider_horizontal,
                        title: 'Page Margin',
                        subtitle: '${margin.round()} pt',
                        trailing: SizedBox(
                          width: 140,
                          child: Slider(
                            value: margin,
                            min: 0,
                            max: 50,
                            divisions: 10,
                            label: '${margin.round()}',
                            onChanged: (v) => setSheetState(() => margin = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ─── Watermark ───
                      _SettingTile(
                        icon: IconsaxPlusLinear.text_bold,
                        title: 'Watermark',
                        subtitle: 'Overlay text on every page',
                        trailing: const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 44),
                        child: TextField(
                          controller: watermarkController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Confidential',
                            prefixIcon: Icon(
                              IconsaxPlusLinear.text_block,
                              size: 18,
                            ),
                          ),
                          onChanged: (v) => watermarkText = v,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ─── Apply ───
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _settings = _settings.copyWith(
                                enableOcr: isAndroid ? ocrEnabled : false,
                                passwordProtected: passwordEnabled,
                                password: passwordController.text,
                                margin: margin,
                                watermarkText: watermarkController.text,
                              );
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Text('Apply Settings'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SETTING TILE
// ═══════════════════════════════════════════════════════════

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
