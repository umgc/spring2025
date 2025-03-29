import 'dart:typed_data';

/// Base class for all Event Stream message headers.
sealed class EventStreamHeader<T> {
  /// Creates an [EventStreamHeader] with a given name and a value.
  const EventStreamHeader(this.name, this.value);

  /// The header name.
  final String name;

  /// The header value.
  final T value;

  /// A string representation of this object.
  @override
  String toString() => '$runtimeType(name: $name, value: $value)';
}

/// [EventStreamHeader] with a boolean value.
final class EventStreamBoolHeader extends EventStreamHeader<bool> {
  /// Creates an [EventStreamBoolHeader] with a given name and a boolean value.
  const EventStreamBoolHeader(super.name, super.value);
}

/// [EventStreamHeader] with a byte value.
final class EventStreamByteHeader extends EventStreamHeader<int> {
  /// Creates an [EventStreamByteHeader] with a given name and a byte value.
  const EventStreamByteHeader(super.name, super.value);
}

/// [EventStreamHeader] with a short value.
final class EventStreamShortHeader extends EventStreamHeader<int> {
  /// Creates an [EventStreamShortHeader] with a given name and a short value.
  const EventStreamShortHeader(super.name, super.value);
}

/// [EventStreamHeader] with an integer value.
final class EventStreamIntegerHeader extends EventStreamHeader<int> {
  /// Creates an [EventStreamIntegerHeader] with a given name and an integer
  const EventStreamIntegerHeader(super.name, super.value);
}

/// [EventStreamHeader] with a long value.
final class EventStreamLongHeader extends EventStreamHeader<int> {
  /// Creates an [EventStreamLongHeader] with a given name and a long value.
  const EventStreamLongHeader(super.name, super.value);
}

/// [EventStreamHeader] with a byte array value.
final class EventStreamByteArrayHeader extends EventStreamHeader<Uint8List> {
  /// Creates an [EventStreamByteArrayHeader] with a given name and a byte array
  /// value.
  const EventStreamByteArrayHeader(super.name, super.value);
}

/// [EventStreamHeader] with a string value.
final class EventStreamStringHeader extends EventStreamHeader<String> {
  /// Creates an [EventStreamStringHeader] with a given name and a string value.
  const EventStreamStringHeader(super.name, super.value);
}

/// [EventStreamHeader] with a timestamp value.
final class EventStreamTimestampHeader extends EventStreamHeader<DateTime> {
  /// Creates an [EventStreamTimestampHeader] with a given name and a timestamp
  /// value.
  const EventStreamTimestampHeader(super.name, super.value);
}

/// [EventStreamHeader] with a UUID value.
final class EventStreamUuidHeader extends EventStreamHeader<String> {
  /// Creates an [EventStreamUuidHeader] with a given name and a UUID value.
  const EventStreamUuidHeader(super.name, super.value);
}
