import 'dart:typed_data';

import 'header.dart';

/// An Event Stream message.
final class EventStreamMessage {
  /// Creates an [EventStreamMessage] with a given headers and payload.
  const EventStreamMessage({
    required this.headers,
    required this.payload,
  });

  /// The message headers.
  final List<EventStreamHeader> headers;

  /// The message payload.
  final Uint8List payload;

  /// Returns the value of the header with the specified [name] or `null`
  /// if there is no such header.
  dynamic getHeaderValue(String name) {
    try {
      return headers.firstWhere((header) => header.name == name).value;
    } catch (_) {
      return null;
    }
  }

  /// A string representation of this object.
  @override
  String toString() =>
      'EventStreamMessage(headers: $headers, payload: $payload)';
}
