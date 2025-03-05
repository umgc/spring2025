import 'package:memoryminder/src/database/model/media.dart';
import 'package:memoryminder/src/database/model/media_type.dart';
import 'package:memoryminder/src/database/repository/photo_repository.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/file_manager.dart';
import 'package:flutter/widgets.dart';

class Photo extends Media {
  final String photoFileName;

  late Image? photo;

  Photo({
    int? id,
    String? title,
    String? description,
    List<String>? tags,
    required DateTime timestamp,
    String? physicalAddress,
    required int storageSize,
    required bool isFavorited,
    required this.photoFileName,
  }) : super(
          id: id,
          mediaType: MediaType.photo,
          title: title ?? photoFileName,
          description: description,
          tags: tags,
          timestamp: timestamp,
          physicalAddress: physicalAddress,
          storageSize: storageSize,
          isFavorited: isFavorited,
        ) {
    _loadPhoto();
  }

  @override
  Photo copy({
    int? id,
    String? title,
    String? description,
    List<String>? tags,
    DateTime? timestamp,
    String? physicalAddress,
    int? storageSize,
    bool? isFavorited,
    String? photoFileName,
  }) =>
      Photo(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        tags: tags ?? this.tags,
        timestamp: timestamp ?? this.timestamp,
        physicalAddress: physicalAddress ?? this.physicalAddress,
        storageSize: storageSize ?? this.storageSize,
        isFavorited: isFavorited ?? this.isFavorited,
        photoFileName: photoFileName ?? this.photoFileName,
      );

  @override
  Map<String, Object?> toJson() {
    return {
      ...super.toJson(),
      PhotoFields.photoFileName: photoFileName,
    };
  }

  static Photo fromJson(Map<String, Object?> json) {
    try {
      return Photo(
        id: json[MediaFields.id] as int?,
        title: json[MediaFields.title] as String?,
        description: json[MediaFields.description] as String?,
        tags: (json[MediaFields.tags] as String?)?.split(','),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (json[MediaFields.timestamp] as int),
          isUtc: true,
        ),
        physicalAddress: json[MediaFields.physicalAddress] as String,
        storageSize: json[MediaFields.storageSize] as int,
        isFavorited: json[MediaFields.isFavorited] == 1,
        photoFileName: json[PhotoFields.photoFileName] as String,
      );
    } catch (e) {
      throw FormatException('Error parsing JSON for Photo: $e');
    }
  }

  Future<void> _loadPhoto() async {
    photo = FileManager.loadImage(
      DirectoryManager.instance.photosDirectory.path,
      photoFileName,
    );
  }
}
