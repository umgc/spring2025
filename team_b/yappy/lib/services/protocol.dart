import 'dart:convert';
import 'dart:typed_data';

import 'package:http2/http2.dart';

import 'event_stream/header.dart';
import 'event_stream/message.dart';
import 'event_stream/message_signer.dart';
import 'event_stream/stream_codec.dart';

/// Encodes [EventStreamMessage]s into [Uint8List]s.
final class EventStreamEncoder
    extends Converter<EventStreamMessage, Uint8List> {
  const EventStreamEncoder();

  @override
  Uint8List convert(EventStreamMessage input) => EventStreamCodec.encode(input);

  @override
  Sink<EventStreamMessage> startChunkedConversion(Sink<Uint8List> sink) =>
      _PacketConversionSink(sink, this);
}

/// Encodes [Uint8List]s into [DataStreamMessage]s.
final class DataStreamMessageEncoder
    extends Converter<Uint8List, DataStreamMessage> {
  const DataStreamMessageEncoder();

  @override
  DataStreamMessage convert(Uint8List input) => DataStreamMessage(input);

  @override
  Sink<Uint8List> startChunkedConversion(Sink<DataStreamMessage> sink) =>
      _PacketConversionSink(sink, this);
}

/// Encodes [Uint8List]s into [EventStreamMessage]s.
final class AudioEventEncoder extends Converter<Uint8List, EventStreamMessage> {
  const AudioEventEncoder();

  @override
  EventStreamMessage convert(Uint8List input) => EventStreamMessage(
        headers: [
          const EventStreamStringHeader(
            ':content-type',
            'application/octet-stream',
          ),
          const EventStreamStringHeader(':event-type', 'AudioEvent'),
          const EventStreamStringHeader(':message-type', 'event'),
        ],
        payload: input,
      );

  @override
  Sink<Uint8List> startChunkedConversion(Sink<EventStreamMessage> sink) =>
      _PacketConversionSink(sink, this);
}

/// Signs [Uint8List]s into [EventStreamMessage]s.
final class AudioMessageSigner
    extends Converter<Uint8List, EventStreamMessage> {
  const AudioMessageSigner(this._messageSigner);

  final EventStreamMessageSigner _messageSigner;

  @override
  EventStreamMessage convert(Uint8List input) => _messageSigner.sign(input);

  @override
  Sink<Uint8List> startChunkedConversion(Sink<EventStreamMessage> sink) =>
      _PacketConversionSink(sink, this);
}

/// Joins/splits [Uint8List]s into [Uint8List]s of a fixed size.
final class AudioDataChunker extends Converter<Uint8List, Uint8List> {
  const AudioDataChunker(this.chunkSize) : assert(chunkSize >= 0);

  /// The size of the chunks to split the audio data into.
  /// Zero value disables chunking.
  final int chunkSize;

  @override
  Uint8List convert(Uint8List input) {
    return input;
  }

  @override
  Sink<Uint8List> startChunkedConversion(Sink<Uint8List> sink) =>
      _AudioDataChunkedConversionSink(sink, chunkSize);
}

final class _AudioDataChunkedConversionSink
    implements ChunkedConversionSink<Uint8List> {
  _AudioDataChunkedConversionSink(this.sink, this._chunkSize)
      : assert(_chunkSize > 0),
        _buffer = Uint8List(_chunkSize);

  final Sink<Uint8List> sink;
  final int _chunkSize;
  final Uint8List _buffer;

  int _bufferSize = 0;
  int _totalSize = 0;

  @override
  void add(Uint8List chunk) {
    final chunkLength = chunk.length;

    if (_chunkSize == 0) {
      sink.add(chunk);
      _totalSize += chunkLength;
      return;
    }

    int offset = 0;

    while (offset < chunkLength) {
      final remaining = chunkLength - offset;
      final remainingBuffer = _chunkSize - _bufferSize;
      final copyLength =
          remaining < remainingBuffer ? remaining : remainingBuffer;
      _buffer.setRange(_bufferSize, _bufferSize + copyLength, chunk, offset);
      _bufferSize += copyLength;
      offset += copyLength;

      if (_bufferSize == _chunkSize) {
        sink.add(_buffer);
        _totalSize += _bufferSize;
        _bufferSize = 0;
      }
    }
  }

  @override
  void close() {
    if (_bufferSize > 0) {
      sink.add(_buffer.sublist(0, _bufferSize));
      _totalSize += _bufferSize;
    }

    if (_totalSize > 0) {
      // Send an empty chunk to signal the end of the audio stream.
      sink.add(Uint8List(0));
    }

    sink.close();
  }
}

final class _PacketConversionSink<S, T> implements ChunkedConversionSink<S> {
  const _PacketConversionSink(this.sink, this.converter);

  final Sink<T> sink;
  final Converter<S, T> converter;

  @override
  void add(S chunk) {
    sink.add(converter.convert(chunk));
  }

  @override
  void close() {
    sink.close();
  }
}
