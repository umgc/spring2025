import 'package:memoryminder/src/features/common/model/media.dart';
import 'package:memoryminder/src/features/common/model/media_type.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/file_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:memoryminder/src/features/common/model/VideoFields.dart';


class Video extends Media {
  final String videoFileName;
  final String? thumbnailFileName;
  final String duration;

  late Image? thumbnail;

  Video({
    int? id,
    String? title,
    String? description,
    List<String>? tags,
    required DateTime timestamp,
    String? physicalAddress,
    required int storageSize,
    required bool isFavorited,
    required this.videoFileName,
    this.thumbnailFileName,
    required this.duration,
  }) : super(
          id: id,
          mediaType: MediaType.video,
          title: title ?? videoFileName,
          description: description,
          tags: tags,
          timestamp: timestamp,
          physicalAddress: physicalAddress,
          storageSize: storageSize,
          isFavorited: isFavorited,
        ) {
    _loadThumbnail();
  }

  @override
  Video copy({
    int? id,
    String? title,
    String? description,
    List<String>? tags,
    DateTime? timestamp,
    String? physicalAddress,
    int? storageSize,
    bool? isFavorited,
    String? videoFileName,
    String? thumbnailFileName,
    String? duration,
  }) =>
      Video(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        tags: tags ?? this.tags,
        timestamp: timestamp ?? this.timestamp,
        physicalAddress: physicalAddress ?? this.physicalAddress,
        storageSize: storageSize ?? this.storageSize,
        isFavorited: isFavorited ?? this.isFavorited,
        videoFileName: videoFileName ?? this.videoFileName,
        thumbnailFileName: thumbnailFileName ?? this.thumbnailFileName,
        duration: duration ?? this.duration,
      );

  @override
  Map<String, Object?> toJson() {
    return {
      ...super.toJson(),
      VideoFields.videoFileName: videoFileName,
      VideoFields.thumbnailFileName: thumbnailFileName,
      VideoFields.duration: duration,
    };
  }

  static Video fromJson(Map<String, Object?> json) {
    try {
      return Video(
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
        videoFileName: json[VideoFields.videoFileName] as String,
        thumbnailFileName: json[VideoFields.thumbnailFileName] as String?,
        duration: json[VideoFields.duration] as String,
      );
    } catch (e) {
      throw FormatException('Error parsing JSON for Video: $e');
    }
  }

  Future<void> _loadThumbnail() async {
    if (thumbnailFileName != null && thumbnailFileName!.isNotEmpty) {
      thumbnail = FileManager.loadImage(
        DirectoryManager.instance.videoThumbnailsDirectory.path,
        thumbnailFileName!,
      );
    }
  }
}
