import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import 'package:images_to_pdf/core/theme/app_colors.dart';
import 'package:images_to_pdf/data/models/pdf_annotation_model.dart';
import 'package:images_to_pdf/providers/pdf_editor_provider.dart';
import 'package:images_to_pdf/presentation/widgets/animated_scale_button.dart';

class PdfEditorScreen extends ConsumerStatefulWidget {
  final String filePath;

  const PdfEditorScreen({super.key, required this.filePath});

  @override
  ConsumerState<PdfEditorScreen> createState() => _PdfEditorScreenState();
}

class _PdfEditorScreenState extends ConsumerState<PdfEditorScreen>
    with SingleTickerProviderStateMixin {
  AnnotationTool? _currentTool;
  Color _currentColor = AppColors.primary;
  double _strokeWidth = 3.0;
  double _textSize = 16.0;
  bool _isSaving = false;
  int _currentPage = 0;

  // For freehand drawing — normalized points (0..1)
  List<Offset> _activeStrokePoints = [];

  // For highlight — normalized rect
  Offset? _highlightStart;
  Rect? _activeHighlightRect;

  // For text — we store a pending tap location

  late AnimationController _toolbarController;
  late Animation<Offset> _toolbarSlide;

  @override
  void initState() {
    super.initState();
    _toolbarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _toolbarSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _toolbarController,
            curve: Curves.easeOutCubic,
          ),
        );
    _toolbarController.forward();

    // Clear annotations from any previous session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pdfAnnotationsProvider.notifier).clearAll();
    });
  }

  @override
  void dispose() {
    _toolbarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final annotations = ref.watch(pdfAnnotationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? AppColors.scaffoldDark : AppColors.surfaceLight,
      appBar: _buildAppBar(context, isDark),
      body: Stack(
        children: [
          // ── PDF Viewer ──
          PdfViewer.file(
            widget.filePath,
            params: PdfViewerParams(
              enableTextSelection: _currentTool == null,
              pageOverlaysBuilder: (context, pageRect, page) {
                final pageIndex = page.pageNumber - 1;
                return [
                  // Annotation paint layer
                  Positioned.fill(
                    child: _AnnotationPaintLayer(
                      annotations: annotations[pageIndex] ?? [],
                      activeStrokePoints: pageIndex == _currentPage
                          ? _activeStrokePoints
                          : [],
                      activeStrokeColor: _currentColor,
                      activeStrokeWidth: _strokeWidth / pageRect.size.width,
                      activeHighlightRect: pageIndex == _currentPage
                          ? _activeHighlightRect
                          : null,
                      activeHighlightColor: _currentColor,
                    ),
                  ),
                  // Gesture layer for annotations
                  if (_currentTool != null)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanStart: (d) =>
                            _onPanStart(d, pageIndex, pageRect.size),
                        onPanUpdate: (d) =>
                            _onPanUpdate(d, pageIndex, pageRect.size),
                        onPanEnd: (d) => _onPanEnd(pageIndex, pageRect.size),
                        onTapUp: (d) => _onTapUp(d, pageIndex, pageRect.size),
                      ),
                    ),
                ];
              },
              onPageChanged: (pageNumber) {
                setState(() => _currentPage = (pageNumber ?? 1) - 1);
              },
            ),
          ),
          // ── Bottom Toolbar ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _toolbarSlide,
              child: _buildToolbar(context, isDark),
            ),
          ),
          // ── Saving overlay ──
          if (_isSaving) _buildSavingOverlay(),
        ],
      ),
    );
  }

  // ──────────────────────── APP BAR ────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(IconsaxPlusLinear.arrow_left),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: const Icon(
              IconsaxPlusBold.edit_2,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Edit PDF',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        // Undo button
        IconButton(
          icon: const Icon(IconsaxPlusLinear.undo),
          tooltip: 'Undo',
          onPressed: () {
            HapticFeedback.lightImpact();
            ref
                .read(pdfAnnotationsProvider.notifier)
                .undoLastAnnotation(_currentPage);
          },
        ),
        // Save button
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(
              IconsaxPlusBold.document_download,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'Save PDF',
            onPressed: _isSaving ? null : () => _savePdf(context),
          ),
        ),
      ],
    );
  }

  // ──────────────────────── TOOLBAR ────────────────────────
  Widget _buildToolbar(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.scaffoldDark : Colors.white).withValues(
          alpha: 0.95,
        ),
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.subtleBorderDark
                : AppColors.subtleBorderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Tool Buttons ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolButton(
                icon: IconsaxPlusLinear.pen_tool,
                label: 'Draw',
                isActive: _currentTool == AnnotationTool.draw,
                onTap: () => _selectTool(AnnotationTool.draw),
              ),
              _ToolButton(
                icon: IconsaxPlusLinear.text,
                label: 'Text',
                isActive: _currentTool == AnnotationTool.text,
                onTap: () => _selectTool(AnnotationTool.text),
              ),
              _ToolButton(
                icon: IconsaxPlusLinear.brush_1,
                label: 'Highlight',
                isActive: _currentTool == AnnotationTool.highlight,
                onTap: () => _selectTool(AnnotationTool.highlight),
              ),
              _ToolButton(
                icon: IconsaxPlusLinear.close_circle,
                label: 'None',
                isActive: _currentTool == null,
                onTap: () => _selectTool(null),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ─── Color & Stroke Settings ───
          if (_currentTool != null) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._colorOptions.map(
                    (c) => AnimatedScaleButton(
                      onTap: () => setState(() => _currentColor = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _currentColor == c
                                ? (isDark ? Colors.white : Colors.black)
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: _currentColor == c
                              ? [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_currentTool == AnnotationTool.draw)
                    SizedBox(
                      width: 120,
                      child: Slider(
                        value: _strokeWidth,
                        min: 1,
                        max: 12,
                        divisions: 11,
                        label: '${_strokeWidth.round()}',
                        onChanged: (v) => setState(() => _strokeWidth = v),
                      ),
                    ),
                  if (_currentTool == AnnotationTool.text)
                    SizedBox(
                      width: 120,
                      child: Slider(
                        value: _textSize,
                        min: 10,
                        max: 40,
                        divisions: 6,
                        label: '${_textSize.round()}',
                        onChanged: (v) => setState(() => _textSize = v),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const List<Color> _colorOptions = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFFEF4444), // Red
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFF3B82F6), // Blue
    Color(0xFFEC4899), // Pink
    Color(0xFF000000), // Black
    Color(0xFFFFFFFF), // White
  ];

  // ──────────────────────── DRAWING GESTURES ────────────────────────
  void _selectTool(AnnotationTool? tool) {
    HapticFeedback.selectionClick();
    setState(() => _currentTool = tool);
  }

  void _onPanStart(DragStartDetails d, int pageIndex, Size pageSize) {
    setState(() => _currentPage = pageIndex);
    final normalized = _normalize(d.localPosition, pageSize);

    switch (_currentTool) {
      case AnnotationTool.draw:
        setState(() {
          _activeStrokePoints = [normalized];
        });
        break;
      case AnnotationTool.highlight:
        setState(() {
          _highlightStart = normalized;
          _activeHighlightRect = null;
        });
        break;
      default:
        break;
    }
  }

  void _onPanUpdate(DragUpdateDetails d, int pageIndex, Size pageSize) {
    final normalized = _normalize(d.localPosition, pageSize);

    switch (_currentTool) {
      case AnnotationTool.draw:
        setState(() {
          _activeStrokePoints = [..._activeStrokePoints, normalized];
        });
        break;
      case AnnotationTool.highlight:
        if (_highlightStart != null) {
          setState(() {
            _activeHighlightRect = Rect.fromPoints(
              _highlightStart!,
              normalized,
            );
          });
        }
        break;
      default:
        break;
    }
  }

  void _onPanEnd(int pageIndex, Size pageSize) {
    switch (_currentTool) {
      case AnnotationTool.draw:
        if (_activeStrokePoints.length > 1) {
          ref
              .read(pdfAnnotationsProvider.notifier)
              .addAnnotation(
                pageIndex,
                DrawingAnnotation(
                  pageIndex: pageIndex,
                  color: _currentColor,
                  points: List.from(_activeStrokePoints),
                  strokeWidth: _strokeWidth / pageSize.width,
                ),
              );
        }
        setState(() => _activeStrokePoints = []);
        break;
      case AnnotationTool.highlight:
        if (_activeHighlightRect != null) {
          ref
              .read(pdfAnnotationsProvider.notifier)
              .addAnnotation(
                pageIndex,
                HighlightAnnotation(
                  pageIndex: pageIndex,
                  color: _currentColor,
                  rect: _activeHighlightRect!,
                ),
              );
        }
        setState(() {
          _highlightStart = null;
          _activeHighlightRect = null;
        });
        break;
      default:
        break;
    }
  }

  void _onTapUp(TapUpDetails d, int pageIndex, Size pageSize) {
    if (_currentTool == AnnotationTool.text) {
      final normalized = _normalize(d.localPosition, pageSize);
      _showTextInputDialog(pageIndex, normalized, pageSize);
    }
  }

  Offset _normalize(Offset position, Size pageSize) {
    return Offset(
      (position.dx / pageSize.width).clamp(0.0, 1.0),
      (position.dy / pageSize.height).clamp(0.0, 1.0),
    );
  }

  // ──────────────────────── TEXT INPUT DIALOG ────────────────────────
  void _showTextInputDialog(
    int pageIndex,
    Offset normalizedPos,
    Size pageSize,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: const Icon(
                IconsaxPlusBold.text,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Add Text'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Type your text here…',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                ref
                    .read(pdfAnnotationsProvider.notifier)
                    .addAnnotation(
                      pageIndex,
                      TextAnnotation(
                        pageIndex: pageIndex,
                        color: _currentColor,
                        position: normalizedPos,
                        text: text,
                        fontSize: _textSize / pageSize.width,
                      ),
                    );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── SAVE PDF ────────────────────────
  Future<void> _savePdf(BuildContext ctx) async {
    final annotations = ref.read(pdfAnnotationsProvider);
    final messenger = ScaffoldMessenger.of(ctx);
    if (annotations.isEmpty ||
        annotations.values.every((list) => list.isEmpty)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No annotations to save.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final service = ref.read(pdfEditorServiceProvider);
      final file = await service.saveAnnotatedPdf(widget.filePath, annotations);

      if (!mounted) return;
      setState(() => _isSaving = false);

      _showSaveSuccessSheet(context, file);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  void _showSaveSuccessSheet(BuildContext context, File file) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                IconsaxPlusBold.tick_circle,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'PDF Saved Successfully!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Your annotated PDF has been saved.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      SharePlus.instance.share(
                        ShareParams(files: [XFile(file.path)]),
                      );
                    },
                    icon: const Icon(IconsaxPlusLinear.share, size: 18),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(IconsaxPlusLinear.tick_circle, size: 18),
                    label: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Saving annotations…',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ANNOTATION PAINT LAYER — renders annotations via CustomPaint
// ═══════════════════════════════════════════════════════════

class _AnnotationPaintLayer extends StatelessWidget {
  final List<PdfAnnotation> annotations;
  final List<Offset> activeStrokePoints;
  final Color activeStrokeColor;
  final double activeStrokeWidth;
  final Rect? activeHighlightRect;
  final Color activeHighlightColor;

  const _AnnotationPaintLayer({
    required this.annotations,
    required this.activeStrokePoints,
    required this.activeStrokeColor,
    required this.activeStrokeWidth,
    this.activeHighlightRect,
    required this.activeHighlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AnnotationPainter(
        annotations: annotations,
        activeStrokePoints: activeStrokePoints,
        activeStrokeColor: activeStrokeColor,
        activeStrokeWidth: activeStrokeWidth,
        activeHighlightRect: activeHighlightRect,
        activeHighlightColor: activeHighlightColor,
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  final List<PdfAnnotation> annotations;
  final List<Offset> activeStrokePoints;
  final Color activeStrokeColor;
  final double activeStrokeWidth;
  final Rect? activeHighlightRect;
  final Color activeHighlightColor;

  _AnnotationPainter({
    required this.annotations,
    required this.activeStrokePoints,
    required this.activeStrokeColor,
    required this.activeStrokeWidth,
    this.activeHighlightRect,
    required this.activeHighlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw saved annotations
    for (final annotation in annotations) {
      switch (annotation) {
        case DrawingAnnotation draw:
          _paintStroke(canvas, size, draw.points, draw.color, draw.strokeWidth);
        case TextAnnotation text:
          _paintText(canvas, size, text);
        case HighlightAnnotation highlight:
          _paintHighlight(
            canvas,
            size,
            highlight.rect,
            highlight.color,
            highlight.opacity,
          );
      }
    }

    // Draw active (in-progress) stroke
    if (activeStrokePoints.length > 1) {
      _paintStroke(
        canvas,
        size,
        activeStrokePoints,
        activeStrokeColor,
        activeStrokeWidth,
      );
    }

    // Draw active (in-progress) highlight
    if (activeHighlightRect != null) {
      _paintHighlight(
        canvas,
        size,
        activeHighlightRect!,
        activeHighlightColor,
        0.35,
      );
    }
  }

  void _paintStroke(
    Canvas canvas,
    Size size,
    List<Offset> points,
    Color color,
    double strokeW,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeW * size.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final p = Offset(points[i].dx * size.width, points[i].dy * size.height);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _paintText(Canvas canvas, Size size, TextAnnotation text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text.text,
        style: TextStyle(
          color: text.color,
          fontSize: text.fontSize * size.width,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: size.width * 0.8);
    tp.paint(
      canvas,
      Offset(text.position.dx * size.width, text.position.dy * size.height),
    );
  }

  void _paintHighlight(
    Canvas canvas,
    Size size,
    Rect rect,
    Color color,
    double opacity,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(
        rect.left * size.width,
        rect.top * size.height,
        rect.right * size.width,
        rect.bottom * size.height,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_AnnotationPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════
//  TOOL BUTTON
// ═══════════════════════════════════════════════════════════

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryGradient : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
