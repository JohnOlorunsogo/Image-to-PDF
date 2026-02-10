import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<List<String>> pickMultiImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        return images.map((image) => image.path).toList();
      }
      return [];
    } catch (e) {
      // Handle error or throw
      rethrow;
    }
  }

  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      return image?.path;
    } catch (e) {
      rethrow;
    }
  }
}
