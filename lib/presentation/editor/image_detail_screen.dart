import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart' as ic;
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:images_to_pdf/data/models/image_model.dart';
import 'package:images_to_pdf/providers/image_provider.dart';

class ImageDetailScreen extends ConsumerStatefulWidget {
  final String imageId;

  const ImageDetailScreen({super.key, required this.imageId});

  @override
  ConsumerState<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends ConsumerState<ImageDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final images = ref.watch(imageListProvider);
    final imageIndex = images.indexWhere((img) => img.id == widget.imageId);

    if (imageIndex == -1) {
      return const Scaffold(body: Center(child: Text('Image not found')));
    }

    final image = images[imageIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.crop),
            onPressed: () => _cropImage(context, image),
            tooltip: 'Crop & Rotate',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editImage(context, image),
            tooltip: 'Filters & Adjustments',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              ref.read(imageListProvider.notifier).removeImage(image.id);
              Navigator.pop(context);
            },
            tooltip: 'Delete',
          ),
        ],
      ),
      body: Center(child: Image.file(File(image.path), fit: BoxFit.contain)),
    );
  }

  Future<void> _cropImage(BuildContext context, ImageModel image) async {
    final croppedFile = await ic.ImageCropper().cropImage(
      sourcePath: image.path,
      // aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Optional: enforce aspect ratio
      uiSettings: [
        ic.AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Theme.of(context).primaryColor,
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
      // ImageEditor returns Uint8List
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File(
        '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(editedImage);
      _updateImage(image, tempFile.path);
    }
  }

  void _updateImage(ImageModel oldImage, String newPath) {
    // We need to update the image in the provider.
    // Since ImageListNotifier doesn't have an update method yet, let's just remove and re-insert or add a generic update.
    // Better: Add updateImage to ImageListNotifier.
    // For now, I'll assume I can add it.
    ref.read(imageListProvider.notifier).updateImage(oldImage.id, newPath);
  }
}
