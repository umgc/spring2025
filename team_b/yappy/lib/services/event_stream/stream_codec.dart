import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'exceptions.dart';
import 'header_codec.dart';
import 'message.dart';

/// Codec for encoding and decoding [EventStreamMessage].
final class EventStreamCodec {
  static const preludeMemberLength = 4;
  static const preludeLength = preludeMemberLength * 2;
  static const checksumLength = 4;
  static const minimumMessageLength = preludeLength + checksumLength * 2;

  /// Decodes [Uint8List] into [EventStreamMessage].
  static EventStreamMessage decode(Uint8List message) {
    final byteLength = message.lengthInBytes;

    if (byteLength < minimumMessageLength) {
      throw const EventStreamDecodeException(
        'Provided message is too short to accommodate event stream '
        'message overhead',
      );
    }

    final view = ByteData.view(message.buffer);

    final messageLength = view.getUint32(0, Endian.big);

    if (byteLength != messageLength) {
      throw const EventStreamDecodeException(
        'Reported message length does not match received message length',
      );
    }

    final headerLength = view.getUint32(preludeMemberLength, Endian.big);
    final expectedPreludeChecksum = view.getUint32(preludeLength, Endian.big);
    final expectedMessageChecksum =
        view.getUint32(byteLength - checksumLength, Endian.big);

    final preludeChecksum = getCrc32(message.sublist(0, preludeLength));
    if (expectedPreludeChecksum != preludeChecksum) {
      throw EventStreamDecodeException(
        'The prelude checksum specified in the message '
        '($expectedPreludeChecksum) does not match the calculated CRC32 '
        'checksum ($preludeChecksum)',
      );
    }

    final messageChecksum =
        getCrc32(message.sublist(0, byteLength - checksumLength));
    if (expectedMessageChecksum != messageChecksum) {
      throw EventStreamDecodeException(
        'The message checksum ($messageChecksum) did not match '
        'the expected value of $expectedMessageChecksum',
      );
    }

    final encodedHeaders = message.sublist(preludeLength + checksumLength,
        preludeLength + checksumLength + headerLength);
    final payload = message.sublist(
      preludeLength + checksumLength + headerLength,
      byteLength - checksumLength,
    );

    return EventStreamMessage(
      headers: EventStreamHeaderCodec.decode(encodedHeaders),
      payload: payload,
    );
  }

  /// Encodes [EventStreamMessage] into [Uint8List].
  static Uint8List encode(EventStreamMessage message) {
    final headers = EventStreamHeaderCodec.encodeHeaders(message.headers);
    final length = headers.lengthInBytes +
        message.payload.lengthInBytes +
        minimumMessageLength;

    final out = Uint8List(length);
    final view =
        ByteData.view(out.buffer, out.offsetInBytes, out.lengthInBytes);

    view.setUint32(0, length, Endian.big);
    view.setUint32(preludeMemberLength, headers.lengthInBytes, Endian.big);
    view.setUint32(
      preludeLength,
      getCrc32(out.sublist(0, preludeLength)),
      Endian.big,
    );
    out.setRange(
      preludeLength + checksumLength,
      preludeLength + checksumLength + headers.lengthInBytes,
      headers,
    );
    out.setRange(
      preludeLength + checksumLength + headers.lengthInBytes,
      length - checksumLength,
      message.payload,
    );

    view.setUint32(
      length - checksumLength,
      getCrc32(out.sublist(0, length - checksumLength)),
      Endian.big,
    );

    return out;
  }
}
