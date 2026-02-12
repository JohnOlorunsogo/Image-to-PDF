import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import 'package:images_to_pdf/core/theme/app_colors.dart';
import 'package:images_to_pdf/data/services/image_picker_service.dart';
import 'package:images_to_pdf/providers/image_provider.dart';
import 'package:images_to_pdf/presentation/editor/image_detail_screen.dart';
import 'package:images_to_pdf/presentation/pdf_preview/pdf_preview_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _fabExpanded = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(imageListProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, images.length, colorScheme, isDark),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: images.isEmpty
            ? _buildEmptyState(context, isDark)
            : _buildImageGrid(context, images, isDark),
      ),
      floatingActionButton: _buildFab(context, isDark),
    );
  }

  // ──────────────────────── APP BAR ────────────────────────
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    int imageCount,
    ColorScheme cs,
    bool isDark,
  ) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: const Icon(
              IconsaxPlusBold.document_text,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Images to PDF',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        if (imageCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _CountChip(count: imageCount),
          ),
        if (imageCount > 0)
          IconButton(
            icon: const Icon(IconsaxPlusLinear.trash),
            onPressed: () => _showClearDialog(context),
            tooltip: 'Clear All',
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ──────────────────────── EMPTY STATE ────────────────────────
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Center(
          key: const ValueKey('empty'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon container
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [AppColors.surfaceDark, AppColors.cardDark]
                            : [AppColors.surfaceLight, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: isDark ? 0.2 : 0.1,
                          ),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: const Icon(
                        IconsaxPlusLinear.gallery_add,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'No images yet',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add photos from your gallery or camera\nto start creating your PDF',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 36),
                // Primary action button
                _GradientButton(
                  onPressed: () => _pickImages(),
                  icon: IconsaxPlusLinear.gallery,
                  label: 'Select Images',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _captureFromCamera(),
                  icon: const Icon(IconsaxPlusLinear.camera, size: 20),
                  label: const Text('Take Photo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────── IMAGE GRID ────────────────────────
  Widget _buildImageGrid(BuildContext context, List images, bool isDark) {
    return Stack(
      key: const ValueKey('grid'),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            12,
            100,
          ),
          child: ReorderableGridView.builder(
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            onReorder: (oldIndex, newIndex) {
              HapticFeedback.lightImpact();
              ref
                  .read(imageListProvider.notifier)
                  .reorderImages(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final image = images[index];
              return _ImageTile(
                key: ValueKey(image.id),
                image: image,
                index: index,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageDetailScreen(imageId: image.id),
                    ),
                  );
                },
                onRemove: () {
                  HapticFeedback.mediumImpact();
                  ref.read(imageListProvider.notifier).removeImage(image.id);
                },
              );
            },
          ),
        ),
        // Bottom convert bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomBar(context, images, isDark),
        ),
      ],
    );
  }

  // ──────────────────────── BOTTOM BAR ────────────────────────
  Widget _buildBottomBar(BuildContext context, List images, bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.scaffoldDark : Colors.white).withValues(
              alpha: 0.85,
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
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Image count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconsaxPlusBold.image,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${images.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Add more button
                GestureDetector(
                  onTap: () => _pickImages(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark
                            ? AppColors.subtleBorderDark
                            : AppColors.subtleBorderLight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconsaxPlusLinear.add,
                          size: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Convert button
                _GradientButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfPreviewScreen(images: images.cast()),
                      ),
                    );
                  },
                  icon: IconsaxPlusBold.document_text,
                  label: 'Convert',
                  compact: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────── FAB ────────────────────────
  Widget _buildFab(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded options
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _fabExpanded
              ? Column(
                  key: const ValueKey('expanded'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MiniFabOption(
                      icon: IconsaxPlusLinear.gallery,
                      label: 'Gallery',
                      onTap: () {
                        setState(() => _fabExpanded = false);
                        _pickImages();
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _MiniFabOption(
                      icon: IconsaxPlusLinear.camera,
                      label: 'Camera',
                      onTap: () {
                        setState(() => _fabExpanded = false);
                        _captureFromCamera();
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                  ],
                )
              : const SizedBox.shrink(key: ValueKey('collapsed')),
        ),
        FloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() => _fabExpanded = !_fabExpanded);
          },
          child: AnimatedRotation(
            turns: _fabExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(IconsaxPlusLinear.add, size: 28),
          ),
        ),
      ],
    );
  }

  // ──────────────────────── HELPERS ────────────────────────
  Future<void> _pickImages() async {
    final paths = await ref.read(imagePickerServiceProvider).pickMultiImages();
    if (paths.isNotEmpty) {
      ref.read(imageListProvider.notifier).addImages(paths);
    }
  }

  Future<void> _captureFromCamera() async {
    final path = await ref
        .read(imagePickerServiceProvider)
        .pickImageFromCamera();
    if (path != null) {
      ref.read(imageListProvider.notifier).addImages([path]);
    }
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Images?'),
        content: const Text(
          'This will remove all images from the list. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(imageListProvider.notifier).clearImages();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SUBWIDGETS
// ═══════════════════════════════════════════════════════════

class _CountChip extends StatelessWidget {
  final int count;
  const _CountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final dynamic image;
  final int index;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ImageTile({
    super.key,
    required this.image,
    required this.index,
    required this.isDark,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Hero(
                tag: 'image_${image.id}',
                child: Image.file(
                  File(image.path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                    child: const Icon(
                      IconsaxPlusLinear.gallery_slash,
                      size: 32,
                    ),
                  ),
                ),
              ),
              // Gradient overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              // Index badge
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Remove button
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      IconsaxPlusLinear.close_circle,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool compact;

  const _GradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 28,
            vertical: compact ? 12 : 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 18 : 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniFabOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _MiniFabOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
