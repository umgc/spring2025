import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

// import 'exceptions.dart';
import 'header.dart';

/// Possible types of [EventStreamHeader].
enum EventStreamHeaderType {
  boolTrue,
  boolFalse,
  byte,
  short,
  integer,
  long,
  byteArray,
  string,
  timestamp,
  uuid,
}

/// Codec for encoding and decoding [EventStreamHeader].
final class EventStreamHeaderCodec {
  /// Decodes [Uint8List] into [EventStreamHeader].
  static List<EventStreamHeader> decode(Uint8List bytes) {
    final out = <EventStreamHeader>[];
    int position = 0;
    final headers = ByteData.view(bytes.buffer);

    while (position < headers.lengthInBytes) {
      final nameLength = headers.getUint8(position++);
      final name = utf8.decode(bytes.sublist(position, position + nameLength));
      position += nameLength;

      final type = EventStreamHeaderType.values[headers.getUint8(position++)];
      late EventStreamHeader header;

      switch (type) {
        case EventStreamHeaderType.boolTrue:
          header = EventStreamBoolHeader(name, true);
          break;
        case EventStreamHeaderType.boolFalse:
          header = EventStreamBoolHeader(name, false);
          break;
        case EventStreamHeaderType.byte:
          header = EventStreamByteHeader(name, headers.getInt8(position));
          position++;
          break;
        case EventStreamHeaderType.short:
          header = EventStreamShortHeader(
            name,
            headers.getInt16(position, Endian.big),
          );
          position += 2;
          break;
        case EventStreamHeaderType.integer:
          header = EventStreamIntegerHeader(
            name,
            headers.getInt32(position, Endian.big),
          );
          position += 4;
          break;
        case EventStreamHeaderType.long:
          header = EventStreamLongHeader(
            name,
            headers.getInt64(position, Endian.big),
          );
          position += 8;
          break;
        case EventStreamHeaderType.byteArray:
          final binaryLength = headers.getUint16(position, Endian.big);
          position += 2;
          header = EventStreamByteArrayHeader(
            name,
            bytes.sublist(position, position + binaryLength),
          );
          position += binaryLength;
          break;
        case EventStreamHeaderType.string:
          final stringLength = headers.getUint16(position, Endian.big);
          position += 2;
          header = EventStreamStringHeader(
            name,
            utf8.decode(bytes.sublist(position, position + stringLength)),
          );
          position += stringLength;
          break;
        case EventStreamHeaderType.timestamp:
          header = EventStreamTimestampHeader(
            name,
            DateTime.fromMillisecondsSinceEpoch(
              headers.getInt64(position, Endian.big),
            ),
          );
          position += 8;
          break;
        case EventStreamHeaderType.uuid:
          header = EventStreamUuidHeader(
            name,
            Uuid.unparse(bytes.sublist(position, position + 16)),
          );
          position += 16;
          break;
        // default:
        //   throw const EventStreamHeaderDecodeException(
        //     'Unrecognized header type',
        //   );
      }

      out.add(header);
    }

    return out;
  }

  /// Encodes a list of [EventStreamHeader]s into [Uint8List].
  static Uint8List encodeHeaders(List<EventStreamHeader> headers) {
    final bytes = <int>[];

    for (final header in headers) {
      bytes.addAll(EventStreamHeaderCodec.encodeHeader(header));
    }

    return Uint8List.fromList(bytes);
  }

  /// Encodes a single [EventStreamHeader] into [Uint8List].
  static Uint8List encodeHeader(EventStreamHeader header) {
    final bytes = <int>[];

    final nameBytes = utf8.encode(header.name);
    bytes.add(nameBytes.length);
    bytes.addAll(nameBytes);

    switch (header) {
      case EventStreamBoolHeader(:var value):
        bytes.add(
          value
              ? EventStreamHeaderType.boolTrue.index
              : EventStreamHeaderType.boolFalse.index,
        );
        break;
      case EventStreamByteHeader(:var value):
        bytes.add(EventStreamHeaderType.byte.index);
        bytes.add(value);
        break;
      case EventStreamShortHeader(:var value):
        bytes.add(EventStreamHeaderType.short.index);
        bytes.addAll(_encodeInt16(value));
        break;
      case EventStreamIntegerHeader(:var value):
        bytes.add(EventStreamHeaderType.integer.index);
        bytes.addAll(_encodeInt32(value));
        break;
      case EventStreamLongHeader(:var value):
        bytes.add(EventStreamHeaderType.long.index);
        bytes.addAll(_encodeInt64(value));
        break;
      case EventStreamByteArrayHeader(:var value):
        bytes.add(EventStreamHeaderType.byteArray.index);
        bytes.addAll(_encodeUint16(value.lengthInBytes));
        bytes.addAll(value);
        break;
      case EventStreamStringHeader(:var value):
        bytes.add(EventStreamHeaderType.string.index);
        final valueBytes = utf8.encode(value);
        bytes.addAll(_encodeUint16(valueBytes.length));
        bytes.addAll(valueBytes);
        break;
      case EventStreamTimestampHeader(:var value):
        bytes.add(EventStreamHeaderType.timestamp.index);
        bytes.addAll(_encodeInt64(value.millisecondsSinceEpoch));
        break;
      case EventStreamUuidHeader(:var value):
        bytes.add(EventStreamHeaderType.uuid.index);
        bytes.addAll(Uuid.parse(value));
        break;
    }

    return Uint8List.fromList(bytes);
  }

  static Uint8List _encodeUint16(int value) {
    final bytes = Uint8List(2);
    ByteData.view(bytes.buffer).setUint16(0, value, Endian.big);
    return bytes;
  }

  static Uint8List _encodeInt16(int value) {
    final bytes = Uint8List(2);
    ByteData.view(bytes.buffer).setInt16(0, value, Endian.big);
    return bytes;
  }

  static Uint8List _encodeInt32(int value) {
    final bytes = Uint8List(4);
    ByteData.view(bytes.buffer).setInt32(0, value, Endian.big);
    return bytes;
  }

  static Uint8List _encodeInt64(int value) {
    final bytes = Uint8List(8);
    ByteData.view(bytes.buffer).setInt64(0, value, Endian.big);
    return bytes;
  }
}
