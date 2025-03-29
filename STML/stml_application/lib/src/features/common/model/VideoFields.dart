import 'package:memoryminder/src/features/common/model/media.dart';

class VideoFields extends MediaFields {
  static final List<String> values = [
    ...MediaFields.values,
    videoFileName,
    thumbnailFileName,
    duration,
  ];

  static const String videoFileName = 'video_file_name';
  static const String thumbnailFileName = 'thumbnail_file_name';
  static const String duration = 'duration';
}
