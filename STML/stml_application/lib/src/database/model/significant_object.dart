import 'package:memoryminder/src/database/repository/significant_object_repository.dart';

class SignificantObject {
  final int? id;
  final String? objectLabel;
  final String? customLabel;
  final int timestamp;
  final String imageFileName;
  final double left;
  final double top;
  final double width;
  final double height;

  SignificantObject({
    this.id,
    this.objectLabel,
    this.customLabel,
    required this.timestamp,
    required this.imageFileName,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  SignificantObject copy({
    int? id,
    String? objectLabel,
    String? customLabel,
    int? timestamp,
    String? imageFileName,
    double? left,
    double? top,
    double? width,
    double? height,
  }) =>
      SignificantObject(
        id: id ?? this.id,
        objectLabel: objectLabel ?? this.objectLabel,
        customLabel: customLabel ?? this.customLabel,
        timestamp: timestamp ?? this.timestamp,
        imageFileName: imageFileName ?? this.imageFileName,
        left: left ?? this.left,
        top: top ?? this.top,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  Map<String, Object?> toJson() {
    return {
      SignificantObjectFields.id: id,
      SignificantObjectFields.objectLabel: objectLabel,
      SignificantObjectFields.customLabel: customLabel,
      SignificantObjectFields.timestamp: timestamp,
      SignificantObjectFields.imageFileName: imageFileName,
      SignificantObjectFields.left: left,
      SignificantObjectFields.top: top,
      SignificantObjectFields.width: width,
      SignificantObjectFields.height: height,
    };
  }

  static SignificantObject fromJson(Map<String, Object?> json) {
    try {
      return SignificantObject(
        id: json[SignificantObjectFields.id] as int?,
        objectLabel: json[SignificantObjectFields.objectLabel] as String?,
        customLabel: json[SignificantObjectFields.customLabel] as String?,
        timestamp: json[SignificantObjectFields.timestamp] as int,
        imageFileName: json[SignificantObjectFields.imageFileName] as String,
        left: json[SignificantObjectFields.left] as double,
        top: json[SignificantObjectFields.top] as double,
        width: json[SignificantObjectFields.width] as double,
        height: json[SignificantObjectFields.height] as double,
      );
    } catch (e) {
      throw FormatException('Error parsing JSON for SignificantObject: $e');
    }
  }
}
