import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:images_to_pdf/data/services/image_picker_service.dart';
import 'package:images_to_pdf/providers/image_provider.dart';
import 'package:images_to_pdf/presentation/editor/image_detail_screen.dart';
import 'package:images_to_pdf/presentation/pdf_preview/pdf_preview_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(imageListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Images to PDF'),
        actions: [
          if (images.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                ref.read(imageListProvider.notifier).clearImages();
              },
              tooltip: 'Clear All',
            ),
          // ... (omitted middle parts)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfPreviewScreen(images: images),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Convert to PDF'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: images.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_search,
                    size: 80,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No images selected',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add images to create a PDF',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final paths = await ref
                          .read(imagePickerServiceProvider)
                          .pickMultiImages();
                      if (paths.isNotEmpty) {
                        ref.read(imageListProvider.notifier).addImages(paths);
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Select Images'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                  child: ReorderableGridView.builder(
                    itemCount: images.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(imageListProvider.notifier)
                          .reorderImages(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final image = images[index];
                      return Card(
                        key: ValueKey(image.id),
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(image.path), fit: BoxFit.cover),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ImageDetailScreen(imageId: image.id),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            // Create separate widget for index indicator to ensure it updates correctly
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PdfPreviewScreen(images: images),
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Convert to PDF'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final path = await ref
              .read(imagePickerServiceProvider)
              .pickImageFromCamera();
          if (path != null) {
            ref.read(imageListProvider.notifier).addImages([path]);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
