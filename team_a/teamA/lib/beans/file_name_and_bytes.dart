import 'dart:typed_data';

// Helper bean class for file uploading.
class FileNameAndBytes {
  final String filename;
  final Uint8List bytes;

  FileNameAndBytes(this.filename, this.bytes);

  @override
  String toString() {
    return "$filename: ${bytes.lengthInBytes} bytes";
  }
}