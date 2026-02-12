import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/image_model.dart';

final imageListProvider = NotifierProvider<ImageListNotifier, List<ImageModel>>(
  () {
    return ImageListNotifier();
  },
);

class ImageListNotifier extends Notifier<List<ImageModel>> {
  @override
  List<ImageModel> build() {
    return [];
  }

  void addImages(List<String> paths) {
    final newImages = paths.map((path) => ImageModel(path: path)).toList();
    state = [...state, ...newImages];
  }

  void removeImage(String id) {
    state = state.where((img) => img.id != id).toList();
  }

  void reorderImages(int oldIndex, int newIndex) {
    final items = [...state];
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
  }

  void updateImage(String id, String newPath) {
    state = [
      for (final img in state)
        if (img.id == id) img.copyWith(path: newPath) else img,
    ];
  }

  void clearImages() {
    state = [];
  }
}
