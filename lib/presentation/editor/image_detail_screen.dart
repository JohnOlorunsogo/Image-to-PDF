import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart' as ic;
import 'package:image_editor_plus/image_editor_plus.dart';

import 'package:images_to_pdf/core/theme/app_colors.dart';
import 'package:images_to_pdf/data/models/image_model.dart';
import 'package:images_to_pdf/providers/image_provider.dart';

class ImageDetailScreen extends ConsumerStatefulWidget {
  final String imageId;

  const ImageDetailScreen({super.key, required this.imageId});

  @override
  ConsumerState<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends ConsumerState<ImageDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _barController;
  late final Animation<Offset> _barSlide;
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _barSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _barController, curve: Curves.easeOutCubic),
        );
    _barController.forward();
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
    if (_showOverlay) {
      _barController.forward();
    } else {
      _barController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(imageListProvider);
    final imageIndex = images.indexWhere((img) => img.id == widget.imageId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (imageIndex == -1) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Image not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final image = images[imageIndex];

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : Colors.black,
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: _toggleOverlay,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image viewer with pinch zoom
            Center(
              child: Hero(
                tag: 'image_${image.id}',
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(image.path),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 64,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Top app bar overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_showOverlay,
                child: AnimatedOpacity(
                  opacity: _showOverlay ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text(
                          'Page ${imageIndex + 1} of ${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48), // balance the back button
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom action bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _barSlide,
                child: _buildActionBar(context, image, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, ImageModel image, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.9),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.crop_rounded,
            label: 'Crop',
            onTap: () => _cropImage(context, image),
          ),
          _ActionButton(
            icon: Icons.tune_rounded,
            label: 'Edit',
            onTap: () => _editImage(context, image),
          ),
          _ActionButton(
            icon: Icons.rotate_right_rounded,
            label: 'Rotate',
            onTap: () {
              // Rotate opens the cropper with rotation
              _cropImage(context, image);
            },
          ),
          _ActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: AppColors.error,
            onTap: () => _confirmDelete(context, image),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ImageModel image) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('This image will be removed from your PDF.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(imageListProvider.notifier).removeImage(image.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _cropImage(BuildContext context, ImageModel image) async {
    final croppedFile = await ic.ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        ic.AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: ic.CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        ic.IOSUiSettings(title: 'Crop Image'),
      ],
    );

    if (croppedFile != null) {
      _updateImage(image, croppedFile.path);
    }
  }

  Future<void> _editImage(BuildContext context, ImageModel image) async {
    final imageData = await File(image.path).readAsBytes();
    if (!context.mounted) return;
    final editedImage = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ImageEditor(image: imageData)),
    );

    if (editedImage != null) {
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File(
        '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(editedImage);
      _updateImage(image, tempFile.path);
    }
  }

  void _updateImage(ImageModel oldImage, String newPath) {
    ref.read(imageListProvider.notifier).updateImage(oldImage.id, newPath);
  }
}

// ═══════════════════════════════════════════════════════════
//  ACTION BUTTON
// ═══════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: c, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
