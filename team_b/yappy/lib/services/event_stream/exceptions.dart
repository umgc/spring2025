import '../exceptions.dart';

/// The event stream message coding/decoding exception.
abstract class EventStreamException extends TranscribeStreamingException {
  /// Creates a [EventStreamException] with a given message.
  const EventStreamException(super.message);
}

/// The event stream message cannot be decoded.
final class EventStreamDecodeException extends EventStreamException {
  /// Creates a [EventStreamDecodeException] with a given message.
  const EventStreamDecodeException(super.message);
}

/// The event stream message header cannot be decoded.
final class EventStreamHeaderDecodeException extends EventStreamException {
  /// Creates a [EventStreamHeaderDecodeException] with a given message.
  const EventStreamHeaderDecodeException(super.message);
}
