import 'package:uuid/uuid.dart';

class ImageModel {
  final String id;
  final String path;
  final DateTime addedAt;

  ImageModel({String? id, required this.path, DateTime? addedAt})
    : id = id ?? const Uuid().v4(),
      addedAt = addedAt ?? DateTime.now();

  ImageModel copyWith({String? id, String? path, DateTime? addedAt}) {
    return ImageModel(
      id: id ?? this.id,
      path: path ?? this.path,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
