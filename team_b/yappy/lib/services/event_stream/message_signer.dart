import 'dart:typed_data';

import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import 'header.dart';
import 'header_codec.dart';
import 'message.dart';

/// Signs [Uint8List] payload into [EventStreamMessage].
final class EventStreamMessageSigner {
  EventStreamMessageSigner._create(
    this._region,
    this._signer,
    this._credentials,
    this._priorSignature,
  );

  final String _region;
  final AWSSigV4Signer _signer;
  final AWSCredentials _credentials;

  String _priorSignature;

  /// Creates a new [EventStreamMessageSigner].
  static Future<EventStreamMessageSigner> create({
    required String region,
    required AWSSigV4Signer signer,
    required String priorSignature,
  }) async {
    final credentials = await signer.credentialsProvider.retrieve();

    return EventStreamMessageSigner._create(
      region,
      signer,
      credentials,
      priorSignature,
    );
  }

  /// Signs [Uint8List] payload into [EventStreamMessage].
  EventStreamMessage sign(Uint8List payload) {
    final credentialScope = AWSCredentialScope(
      region: _region,
      service: AWSService.transcribeStreaming,
    );

    final signingKey = _signer.algorithm.deriveSigningKey(
      _credentials,
      credentialScope,
    );

    final List<EventStreamHeader> messageHeaders = [
      EventStreamTimestampHeader(':date', credentialScope.dateTime.dateTime),
    ];

    final nonSignatureHeaders =
        EventStreamHeaderCodec.encodeHeaders(messageHeaders);

    final sb = StringBuffer()
      ..writeln('${_signer.algorithm}-PAYLOAD')
      ..writeln(credentialScope.dateTime)
      ..writeln(credentialScope)
      ..writeln(_priorSignature)
      ..writeln(_hexHash(nonSignatureHeaders))
      ..write(_hexHash(payload));
    final stringToSign = sb.toString();

    final signature = _signer.algorithm.sign(stringToSign, signingKey);

    messageHeaders.add(
      EventStreamByteArrayHeader(
        ':chunk-signature',
        Uint8List.fromList(hex.decode(signature)),
      ),
    );

    _priorSignature = signature;

    return EventStreamMessage(headers: messageHeaders, payload: payload);
  }

  String _hexHash(Uint8List payload) =>
      hex.encode(sha256.convert(payload).bytes);
}
