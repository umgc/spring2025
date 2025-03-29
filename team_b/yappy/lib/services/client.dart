import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:http2/http2.dart';

import 'event_stream/message.dart';
import 'event_stream/message_signer.dart';
import 'event_stream/stream_codec.dart';
import 'exceptions.dart';
import 'models.dart';
import 'protocol.dart';

/// A client for the Amazon Transcribe Streaming API.
final class TranscribeStreamingClient {
  /// Creates a [TranscribeStreamingClient] with a given [region] and
  /// [credentialsProvider].
  const TranscribeStreamingClient({
    required this.region,
    required this.credentialsProvider,
  });

  /// Specifies the AWS region to use.
  final String region;

  /// Specifies the credentials provider to use.
  final AWSCredentialsProvider credentialsProvider;

  /// Starts a HTTP/2 stream where audio is streamed to Amazon Transcribe
  /// and the [TranscriptEvent]s are streamed to your application.
  Future<
      (
        StartStreamTranscriptionResponse,
        StreamSink<Uint8List>,
        Stream<TranscriptEvent>,
      )> startStreamTranscription(
    StartStreamTranscriptionRequest request,
  ) async {
    final (response, audioStreamSink, eventStreamMessages) =
        await send(request);

    return (
      StartStreamTranscriptionResponse.fromHeaders(response.headers),
      audioStreamSink,
      eventStreamMessages.transform(StreamTransformer.fromHandlers(
        handleData:
            (EventStreamMessage event, EventSink<TranscriptEvent> sink) {
          sink.add(TranscriptEvent.fromJson(utf8.decode(event.payload)));
        },
      )),
    );
  }

  /// Starts a HTTP/2 stream where audio is streamed to Amazon Transcribe
  /// and the raw [EventStreamMessage]s are streamed to your application.
  Future<
      (
        AWSHttpResponse,
        StreamSink<Uint8List>,
        Stream<EventStreamMessage>,
      )> send(
    TranscribeStreamingRequest request,
  ) async {
    final uri =
        Uri.https('transcribestreaming.$region.amazonaws.com', request.path);

    final socket = await SecureSocket.connect(
      uri.host,
      443,
      supportedProtocols: ['h2'],
    );

    final connection = ClientTransportConnection.viaSocket(socket);

    final awsHttpRequest = AWSHttpRequest(
      method: AWSHttpMethod.post,
      uri: uri,
      headers: {
        AWSHeaders.target: request.target,
        AWSHeaders.contentType: 'application/vnd.amazon.eventstream',
      },
      body: null,
    );

    final credentialScope = AWSCredentialScope(
      region: region,
      service: AWSService.transcribeStreaming,
    );

    final signer = AWSSigV4Signer(
      credentialsProvider: credentialsProvider,
    );

    final signedRequest = await signer.sign(
      awsHttpRequest,
      credentialScope: credentialScope,
    );

    final messageSigner = await EventStreamMessageSigner.create(
      region: region,
      signer: signer,
      priorSignature: signedRequest.signature,
    );

    final headers = signedRequest.headers..addAll(request.toHeaders());

    final clientTransportStream = connection.makeRequest([
      Header.ascii(':method', 'POST'),
      Header.ascii(':path', signedRequest.path),
      Header.ascii(':scheme', 'https'),
      ...headers
          .map((String key, String value) =>
              MapEntry(key, Header.ascii(key, value)))
          .values,
    ]);

    final responseHeadersCompleter = Completer<CaseInsensitiveMap<String>>();
    final responseBodyCompleter = Completer<List<int>>();
    late final bool hasResponseBody;

    final eventStreamMessageController = StreamController<EventStreamMessage>();
    final audioStreamController = StreamController<Uint8List>();
    StreamSubscription<DataStreamMessage>? audioStreamSubscription;

    final incomingMessagesSubscription =
        clientTransportStream.incomingMessages.listen(
      (event) {
        try {
          if (event is HeadersStreamMessage) {
            if (responseHeadersCompleter.isCompleted) {
              throw const ProtocolException(
                'HeadersStreamMessage received after response headers were already completed.',
              );
            }

            final headers = CaseInsensitiveMap<String>({});
            headers.addEntries(event.headers.map((header) =>
                MapEntry(utf8.decode(header.name), utf8.decode(header.value))));
            hasResponseBody = int.parse(headers['content-length'] ?? '0') > 0;
            responseHeadersCompleter.complete(headers);
          } else if (event is DataStreamMessage) {
            if (!responseHeadersCompleter.isCompleted) {
              throw const ProtocolException(
                'DataStreamMessage received before response headers were completed.',
              );
            }

            if (hasResponseBody && !responseBodyCompleter.isCompleted) {
              responseBodyCompleter.complete(event.bytes);
              return;
            }

            final eventStreamMessage =
                EventStreamCodec.decode(Uint8List.fromList(event.bytes));

            final messageType =
                eventStreamMessage.getHeaderValue(':message-type');

            if (messageType == 'event') {
              eventStreamMessageController.sink.add(eventStreamMessage);
            } else if (messageType == 'exception') {
              throw TranscribeStreamingServiceException.createFromResponse(
                eventStreamMessage.getHeaderValue(':exception-type') ?? '',
                eventStreamMessage.getHeaderValue(':content-type') ?? '',
                eventStreamMessage.payload,
              );
            } else {
              throw UnexpectedMessageTypeException(
                messageType,
                eventStreamMessage,
              );
            }
          }
        } catch (e) {
          eventStreamMessageController.sink.addError(e);
        }
      },
      onDone: () async {
        await audioStreamSubscription?.cancel();
        await audioStreamController.close();
        await eventStreamMessageController.close();
        await clientTransportStream.outgoingMessages.close();
        await connection.finish();
      },
    );

    final responseHeaders = await responseHeadersCompleter.future;
    final statusCode = int.parse(responseHeaders[':status']!);
    List<int>? responseBody;

    if (hasResponseBody) {
      responseBody = await responseBodyCompleter.future;
    }

    if (statusCode >= 400) {
      await incomingMessagesSubscription.cancel();
      await clientTransportStream.outgoingMessages.close();
      await connection.finish();

      throw TranscribeStreamingServiceException.createFromResponse(
        (responseHeaders['x-amzn-errortype'] ?? statusCode.toString())
            .split(':')
            .first,
        responseHeaders['content-type'] ?? '',
        responseBody,
      );
    }

    audioStreamSubscription = audioStreamController.stream
        .transform(AudioDataChunker(request.chunkSize))
        .transform(const AudioEventEncoder())
        .transform(const EventStreamEncoder())
        .transform(AudioMessageSigner(messageSigner))
        .transform(const EventStreamEncoder())
        .transform(const DataStreamMessageEncoder())
        .listen(clientTransportStream.outgoingMessages.add);

    return (
      AWSHttpResponse(
        statusCode: statusCode,
        headers: responseHeaders,
        body: responseBody,
      ),
      audioStreamController.sink,
      eventStreamMessageController.stream,
    );
  }
}
