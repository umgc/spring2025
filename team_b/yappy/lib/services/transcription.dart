import 'dart:collection';
import 'dart:convert';

import 'models.dart';

/// Converts a stream of [TranscriptEvent]s into a single [String].
final class TranscriptEventStreamDecoder
    extends Converter<TranscriptEvent, String> {
  /// Creates a [TranscriptEventStreamDecoder] with a given
  /// [TranscriptionBuildingStrategy].
  const TranscriptEventStreamDecoder(this.transcriptionBuildingStrategy);

  /// The strategy to use for building a transcription from a list of [Result]s.
  final TranscriptionBuildingStrategy transcriptionBuildingStrategy;

  @override
  String convert(TranscriptEvent input) {
    return transcriptionBuildingStrategy
        .buildTranscription(input.transcript?.results ?? []);
  }

  @override
  Sink<TranscriptEvent> startChunkedConversion(Sink<String> sink) =>
      _TranscriptEventStreamConversionSink(sink, transcriptionBuildingStrategy);
}

final class _TranscriptEventStreamConversionSink
    implements ChunkedConversionSink<TranscriptEvent> {
  _TranscriptEventStreamConversionSink(
      this.sink, this.transcriptionBuildingStrategy);

  final Sink<String> sink;
  final TranscriptionBuildingStrategy transcriptionBuildingStrategy;

  final LinkedHashMap<String, Result> _results =
      LinkedHashMap<String, Result>();

  @override
  void add(TranscriptEvent chunk) {
    for (final Result result in chunk.transcript?.results ?? []) {
      _results[result.resultId!] = result;
    }

    sink.add(transcriptionBuildingStrategy.buildTranscription(_results.values));
  }

  @override
  void close() {
    _results.clear();

    sink.close();
  }
}

/// A strategy for building a transcription from a list of [Result]s.
abstract interface class TranscriptionBuildingStrategy {
  /// Creates a [TranscriptionBuildingStrategy].
  const TranscriptionBuildingStrategy();

  /// Builds a transcription from a list of [Result]s.
  String buildTranscription(Iterable<Result> results);
}

/// A transcription strategy that simply concatenates the transcripts into
/// a plain text.
final class PlainTextTranscriptionStrategy
    implements TranscriptionBuildingStrategy {
  /// Creates a [PlainTextTranscriptionStrategy].
  const PlainTextTranscriptionStrategy();

  @override
  String buildTranscription(Iterable<Result> results) {
    final buffer = StringBuffer();

    for (final result in results) {
      if (result.alternatives == null) continue;

      for (final alternative in result.alternatives!) {
        buffer.write(alternative.transcript);
        buffer.write(' ');
      }
    }

    return buffer.toString().trimRight();
  }
}
