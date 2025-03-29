import 'package:memoryminder/src/features/common/model/media.dart';

class PhotoFields extends MediaFields {
  static final List<String> values = [
    ...MediaFields.values,
    photoFileName,
  ];

  static const String photoFileName = 'photo_file_name';
}