import 'dart:convert';

/// A base class for a request to the Amazon Transcribe Streaming API.
abstract class TranscribeStreamingRequest {
  /// Creates a [TranscribeStreamingRequest].
  const TranscribeStreamingRequest();

  /// The path for the request, for example `/stream-transcription`
  String get path;

  /// The target for the request,
  /// for example `com.amazonaws.transcribe.Transcribe.StartStreamTranscription`
  String get target;

  /// The duration of each audio chunk in milliseconds.
  int get chunkDurationMs;

  /// The chunk size for the audio stream. Zero value disables chunking.
  int get chunkSize;

  /// Returns the headers for the request.
  Map<String, String> toHeaders();
}

/// Starts a HTTP/2 stream where audio is streamed to Amazon Transcribe
/// and the transcription results are streamed to your application.
class StartStreamTranscriptionRequest extends TranscribeStreamingRequest {
  /// Specifies the language code that represents the language spoken
  /// in your audio.
  ///
  /// If you're unsure of the language spoken in your audio, consider using
  /// [identifyLanguage] to enable automatic language identification.
  ///
  /// For a list of languages supported with Amazon Transcribe streaming, refer
  /// to the [Supported languages](https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html) table.
  final LanguageCode? languageCode;

  /// The sample rate of the input audio (in hertz).
  ///
  /// Low-quality audio, such as telephone audio, is typically around 8,000 Hz.
  ///
  /// High-quality audio typically ranges from 16,000 Hz to 48,000 Hz.
  ///
  /// Note that the sample rate you specify must match that of your audio.
  final int mediaSampleRateHertz;

  /// Specifies the encoding of your input audio.
  ///
  /// Supported formats are:
  /// * FLAC
  /// * OPUS-encoded audio in an Ogg container
  /// * PCM (only signed 16-bit little-endian audio formats, which does not include WAV)
  ///
  /// For more information, see
  /// [Media formats](https://docs.aws.amazon.com/transcribe/latest/dg/how-input.html#how-input-audio).
  final MediaEncoding mediaEncoding;

  /// Specifies the name of the custom vocabulary that you want to use
  /// when processing your transcription.
  ///
  /// Note that vocabulary names are case sensitive.
  ///
  /// If the language of the specified custom vocabulary doesn't match
  /// the language identified in your media, the custom vocabulary
  /// is not applied to your transcription.
  ///
  /// This parameter is **not** intended for use with the [identifyLanguage]
  /// parameter If you're including [identifyLanguage] in your request and
  /// want to use one or more custom vocabularies with your transcription,
  /// use the [vocabularyNames] parameter instead.
  ///
  /// For more information, see [Custom vocabularies](https://docs.aws.amazon.com/transcribe/latest/dg/custom-vocabulary.html).
  final String? vocabularyName;

  /// Specifies a name for your transcription session.
  ///
  /// If you don't include this parameter in your request, Amazon Transcribe
  /// generates an ID and returns it in the response.
  ///
  /// You can use a session ID to retry a streaming session.
  final String? sessionId;

  /// Specifies the name of the custom vocabulary filter that you want to use
  /// when processing your transcription.
  ///
  /// Note that vocabulary filter names are case sensitive.
  ///
  /// If the language of the specified custom vocabulary filter doesn't match
  /// the language identified in your media, the vocabulary filter
  /// is not applied to your transcription.
  ///
  /// This parameter is **not** intended for use with the [identifyLanguage]
  /// parameter If you're including [identifyLanguage] in your request and
  /// want to use one or more vocabulary filters with your transcription,
  /// use the [vocabularyFilterNames] parameter instead.
  ///
  /// For more information, see [Using vocabulary filtering with unwanted words](https://docs.aws.amazon.com/transcribe/latest/dg/vocabulary-filtering.html).
  final String? vocabularyFilterName;

  /// Specifies how you want your vocabulary filter applied to your transcript.
  ///
  /// To replace words with `***`, choose `mask`.
  ///
  /// To delete words, choose `remove`.
  ///
  /// To flag words without changing them, choose `tag`.
  final VocabularyFilterMethod? vocabularyFilterMethod;

  /// Enables speaker partitioning (diarization) in your transcription output.
  ///
  /// Speaker partitioning labels the speech from individual speakers in your
  /// media file.
  ///
  /// For more information, see [Partitioning speakers (diarization)](https://docs.aws.amazon.com/transcribe/latest/dg/diarization.html).
  final bool? showSpeakerLabel;

  /// Enables channel identification in multi-channel audio.
  ///
  /// Channel identification transcribes the audio on each channel
  /// independently, then appends the output for each channel into
  /// one transcript.
  ///
  /// If you have multi-channel audio and do not enable channel identification,
  /// your audio is transcribed in a continuous manner and your transcript
  /// is not separated by channel.
  ///
  /// For more information, see [Transcribing multi-channel audio](https://docs.aws.amazon.com/transcribe/latest/dg/channel-id.html).
  final bool? enableChannelIdentification;

  /// Specifies the number of channels in your audio stream.
  ///
  /// Up to two channels are supported.
  final int? numberOfChannels;

  /// Enables partial result stabilization for your transcription.
  ///
  /// Partial result stabilization can reduce latency in your output,
  /// but may impact accuracy.
  ///
  /// For more information, see [Partial-result stabilization](https://docs.aws.amazon.com/transcribe/latest/dg/streaming.html#streaming-partial-result-stabilization).
  final bool? enablePartialResultsStabilization;

  /// Specifies the level of stability to use when you enable partial results
  /// stabilization.
  ///
  /// Low stability provides the highest accuracy.
  /// High stability transcribes faster, but with slightly lower accuracy.
  ///
  /// For more information, see [Partial-result stabilization](https://docs.aws.amazon.com/transcribe/latest/dg/streaming.html#streaming-partial-result-stabilization).
  final PartialResultsStability? partialResultsStability;

  /// Labels all personally identifiable information (PII) identified
  /// in your transcript.
  ///
  /// Content identification is performed at the segment level.
  /// PII specified in [piiEntityTypes] is flagged upon complete transcription
  /// of an audio segment.
  ///
  /// You can’t set [contentIdentificationType] and [contentRedactionType]
  /// in the same request. If you set both, your request returns a
  /// `BadRequestException`.
  ///
  /// For more information, see [Redacting or identifying personally identifiable information](https://docs.aws.amazon.com/transcribe/latest/dg/pii-redaction.html).
  final ContentIdentificationType? contentIdentificationType;

  /// Redacts all personally identifiable information (PII) identified
  /// in your transcript.
  ///
  /// Content redaction is performed at the segment level.
  /// PII specified in [piiEntityTypes] is redacted upon complete transcription
  /// of an audio segment.
  ///
  /// You can’t set [contentRedactionType] and [contentIdentificationType]
  /// in the same request. If you set both, your request returns a
  /// `BadRequestException`.
  ///
  /// For more information, see [Redacting or identifying personally identifiable information](https://docs.aws.amazon.com/transcribe/latest/dg/pii-redaction.html).
  final ContentRedactionType? contentRedactionType;

  /// Specifies which types of personally identifiable information (PII)
  /// you want to redact in your transcript.
  ///
  /// You can include as many types as you'd like, or you can select `ALL`.
  ///
  /// To include [piiEntityTypes] in your request, you must also include either
  /// [contentIdentificationType] or [contentRedactionType].
  ///
  /// Values must be comma-separated and can include:
  /// * `BANK_ACCOUNT_NUMBER`
  /// * `BANK_ROUTING`
  /// * `CREDIT_DEBIT_NUMBER`
  /// * `CREDIT_DEBIT_CVV`
  /// * `CREDIT_DEBIT_EXPIRY`
  /// * `PIN`
  /// * `EMAIL`
  /// * `ADDRESS`
  /// * `NAME`
  /// * `PHONE`
  /// * `SSN`
  /// * `ALL`
  final String? piiEntityTypes;

  /// Specifies the name of the custom language model that you want to use
  /// when processing your transcription.
  ///
  /// Note that language model names are case sensitive.
  ///
  /// The language of the specified language model must match the language code
  /// you specify in your transcription request. If the languages don't match,
  /// the custom language model isn't applied. There are no errors or warnings
  /// associated with a language mismatch.
  ///
  /// For more information, see [Custom language models](https://docs.aws.amazon.com/transcribe/latest/dg/custom-language-models.html).
  final String? languageModelName;

  /// Enables automatic language identification for your transcription.
  ///
  /// If you include [identifyLanguage], you can optionally include a list
  /// of language codes, using [languageOptions], that you think may be present
  /// in your audio stream. Including language options can improve
  /// transcription accuracy.
  ///
  /// You can also include a preferred language using [preferredLanguage].
  /// Adding a preferred language can help Amazon Transcribe identify
  /// the language faster than if you omit this parameter.
  ///
  /// If you have multi-channel audio that contains different languages
  /// on each channel, and you've enabled channel identification,
  /// automatic language identification identifies the dominant language
  /// on each audio channel.
  ///
  /// Note that you must include either [languageCode] or [identifyLanguage]
  /// or [identifyMultipleLanguages] in your request. If you include more than
  /// one of these parameters, your transcription job fails.
  ///
  /// Streaming language identification can't be combined with custom language
  /// models or redaction.
  final bool? identifyLanguage;

  /// Specifies two or more language codes that represent the languages
  /// you think may be present in your media.
  ///
  /// Including more than five is not recommended. If you're unsure
  /// what languages are present, do not include this parameter.
  ///
  /// Including language options can improve the accuracy of language
  /// identification.
  ///
  /// If you include [languageOptions] in your request, you must also
  /// include [identifyLanguage].
  ///
  /// For a list of languages supported with Amazon Transcribe streaming,
  /// refer to the [Supported languages](https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html)
  ///
  /// You can only include one language dialect per language per stream.
  /// For example, you cannot include `en-US` and `en-AU` in the same request.
  final String? languageOptions;

  /// Specifies a preferred language from the subset of languages codes
  /// you specified in [languageOptions].
  ///
  /// You can only use this parameter if you've included [identifyLanguage]
  /// and [languageOptions] in your request.
  final String? preferredLanguage;

  /// Enables automatic multi-language identification in your transcription
  /// job request.
  ///
  /// Use this parameter if your stream contains more than one language.
  /// If your stream contains only one language, use IdentifyLanguage instead.
  ///
  /// If you include [identifyMultipleLanguages], you can optionally include
  /// a list of language codes, using [languageOptions], that you think may be
  /// present in your stream.
  /// Including [languageOptions] restricts [identifyMultipleLanguages] to
  /// only the language options that you specify, which can improve
  /// transcription accuracy.
  ///
  /// If you want to apply a custom vocabulary or a custom vocabulary filter
  /// to your automatic multiple language identification request, include
  /// [vocabularyNames] or [vocabularyFilterNames].
  ///
  /// Note that you must include one of [languageCode], [identifyLanguage],
  /// or [identifyMultipleLanguages] in your request. If you include more than
  /// one of these parameters, your transcription job fails.
  final bool? identifyMultipleLanguages;

  /// Specifies the names of the custom vocabularies that you want to use
  /// when processing your transcription.
  ///
  /// Note that vocabulary names are case sensitive.
  ///
  /// If none of the languages of the specified custom vocabularies match
  /// the language identified in your media, your job fails.
  ///
  /// This parameter is only intended for use **with** the [identifyLanguage]
  /// parameter. If you're **not** including [identifyLanguage] in your request
  /// and want to use a custom vocabulary with your transcription,
  /// use the [vocabularyName] parameter instead.
  ///
  /// For more information, see [Custom vocabularies](https://docs.aws.amazon.com/transcribe/latest/dg/custom-vocabulary.html).
  final String? vocabularyNames;

  /// Specifies the names of the custom vocabulary filters that you want to use
  /// when processing your transcription.
  ///
  /// Note that vocabulary filter names are case sensitive.
  ///
  /// If none of the languages of the specified custom vocabulary filters match
  /// the language identified in your media, your job fails.
  ///
  /// This parameter is only intended for use **with** the [identifyLanguage]
  /// parameter. If you're **not** including [identifyLanguage] in your request
  /// and want to use a custom vocabulary filter with your transcription,
  /// use the [vocabularyFilterName] parameter instead.
  ///
  /// For more information, see [Using vocabulary filtering with unwanted words](https://docs.aws.amazon.com/transcribe/latest/dg/vocabulary-filtering.html).
  final String? vocabularyFilterNames;

  /// Creates a [StartStreamTranscriptionRequest] to start a streaming
  /// transcription.
  const StartStreamTranscriptionRequest({
    this.languageCode,
    required this.mediaSampleRateHertz,
    required this.mediaEncoding,
    this.vocabularyName,
    this.sessionId,
    this.vocabularyFilterName,
    this.vocabularyFilterMethod,
    this.showSpeakerLabel,
    this.enableChannelIdentification,
    this.numberOfChannels,
    this.enablePartialResultsStabilization,
    this.partialResultsStability,
    this.contentIdentificationType,
    this.contentRedactionType,
    this.piiEntityTypes,
    this.languageModelName,
    this.identifyLanguage,
    this.languageOptions,
    this.preferredLanguage,
    this.identifyMultipleLanguages,
    this.vocabularyNames,
    this.vocabularyFilterNames,
  })  : assert(languageCode != null ||
            identifyLanguage != null ||
            identifyMultipleLanguages != null),
        assert(mediaSampleRateHertz >= 8000 && mediaSampleRateHertz <= 48000);

  @override
  String get path => '/stream-transcription';

  @override
  String get target =>
      'com.amazonaws.transcribe.Transcribe.StartStreamTranscription';

  @override
  int get chunkDurationMs => 200;

  @override
  int get chunkSize => switch (mediaEncoding) {
        MediaEncoding.pcm => mediaSampleRateHertz * 2 * chunkDurationMs ~/ 1000,
        _ => 0,
      };

  @override
  Map<String, String> toHeaders() => {
        if (languageCode != null)
          'x-amzn-transcribe-language-code': languageCode!.value,
        'x-amzn-transcribe-sample-rate': mediaSampleRateHertz.toString(),
        'x-amzn-transcribe-media-encoding': mediaEncoding.value,
        if (vocabularyName != null)
          'x-amzn-transcribe-vocabulary-name': vocabularyName!,
        if (sessionId != null) 'x-amzn-transcribe-session-id': sessionId!,
        if (vocabularyFilterName != null)
          'x-amzn-transcribe-vocabulary-filter-name': vocabularyFilterName!,
        if (vocabularyFilterMethod != null)
          'x-amzn-transcribe-vocabulary-filter-method':
              vocabularyFilterMethod!.value,
        if (showSpeakerLabel != null)
          'x-amzn-transcribe-show-speaker-label': showSpeakerLabel!.toString(),
        if (enableChannelIdentification != null)
          'x-amzn-transcribe-enable-channel-identification':
              enableChannelIdentification!.toString(),
        if (numberOfChannels != null)
          'x-amzn-transcribe-number-of-channels': numberOfChannels!.toString(),
        if (enablePartialResultsStabilization != null)
          'x-amzn-transcribe-enable-partial-results-stabilization':
              enablePartialResultsStabilization!.toString(),
        if (partialResultsStability != null)
          'x-amzn-transcribe-partial-results-stability':
              partialResultsStability!.value,
        if (contentIdentificationType != null)
          'x-amzn-transcribe-content-identification-type':
              contentIdentificationType!.value,
        if (contentRedactionType != null)
          'x-amzn-transcribe-content-redaction-type':
              contentRedactionType!.value,
        if (piiEntityTypes != null)
          'x-amzn-transcribe-pii-entity-types': piiEntityTypes!,
        if (languageModelName != null)
          'x-amzn-transcribe-language-model-name': languageModelName!,
        if (identifyLanguage != null)
          'x-amzn-transcribe-identify-language': identifyLanguage!.toString(),
        if (languageOptions != null)
          'x-amzn-transcribe-language-options': languageOptions!,
        if (preferredLanguage != null)
          'x-amzn-transcribe-preferred-language': preferredLanguage!,
        if (identifyMultipleLanguages != null)
          'x-amzn-transcribe-identify-multiple-languages':
              identifyMultipleLanguages!.toString(),
        if (vocabularyNames != null)
          'x-amzn-transcribe-vocabulary-names': vocabularyNames!,
        if (vocabularyFilterNames != null)
          'x-amzn-transcribe-vocabulary-filter-names': vocabularyFilterNames!,
      };
}

/// Response for the [StartStreamTranscriptionRequest].
final class StartStreamTranscriptionResponse {
  /// Provides the identifier for your streaming request.
  final String? requestId;

  /// Provides the language code that you specified in your request.
  final LanguageCode? languageCode;

  /// Provides the sample rate that you specified in your request.
  final int? mediaSampleRateHertz;

  /// Provides the media encoding you specified in your request.
  final MediaEncoding? mediaEncoding;

  /// Provides the name of the custom vocabulary that you specified
  /// in your request.
  final String? vocabularyName;

  /// Provides the identifier for your transcription session.
  final String? sessionId;

  /// Provides the name of the custom vocabulary filter that you specified
  /// in your request.
  final String? vocabularyFilterName;

  /// Provides the vocabulary filtering method used in your transcription.
  final VocabularyFilterMethod? vocabularyFilterMethod;

  /// Shows whether speaker partitioning was enabled for your transcription.
  final bool? showSpeakerLabel;

  /// Shows whether  channel identification was enabled for your transcription.
  final bool? enableChannelIdentification;

  /// Provides the number of channels that you specified in your request.
  final int? numberOfChannels;

  /// Shows whether partial results stabilization was enabled
  /// for your transcription.
  final bool? enablePartialResultsStabilization;

  /// Provides the stabilization level used for your transcription.
  final PartialResultsStability? partialResultsStability;

  /// Shows whether content identification was enabled for your transcription.
  final ContentIdentificationType? contentIdentificationType;

  /// Shows whether content redaction was enabled for your transcription.
  final ContentRedactionType? contentRedactionType;

  /// Lists the PII entity types you specified in your request.
  final String? piiEntityTypes;

  /// Provides the name of the custom language model that you specified
  /// in your request.
  final String? languageModelName;

  /// Shows whether automatic language identification was enabled
  /// for your transcription.
  final bool? identifyLanguage;

  /// Provides the language codes that you specified in your request.
  final String? languageOptions;

  /// Provides the preferred language that you specified in your request.
  final LanguageCode? preferredLanguage;

  /// Shows whether automatic multi-language identification was enabled
  /// for your transcription.
  final bool? identifyMultipleLanguages;

  /// Provides the names of the custom vocabularies that you specified
  /// in your request.
  final String? vocabularyNames;

  /// Provides the names of the custom vocabulary filters that you specified
  /// in your request.
  final String? vocabularyFilterNames;

  /// Creates a [StartStreamTranscriptionResponse] from the values of
  /// the headers of a response from the Amazon Transcribe Streaming API.
  const StartStreamTranscriptionResponse({
    this.requestId,
    this.languageCode,
    this.mediaSampleRateHertz,
    this.mediaEncoding,
    this.vocabularyName,
    this.sessionId,
    this.vocabularyFilterName,
    this.vocabularyFilterMethod,
    this.showSpeakerLabel,
    this.enableChannelIdentification,
    this.numberOfChannels,
    this.enablePartialResultsStabilization,
    this.partialResultsStability,
    this.contentIdentificationType,
    this.contentRedactionType,
    this.piiEntityTypes,
    this.languageModelName,
    this.identifyLanguage,
    this.languageOptions,
    this.preferredLanguage,
    this.identifyMultipleLanguages,
    this.vocabularyNames,
    this.vocabularyFilterNames,
  });

  /// Creates a [StartStreamTranscriptionResponse] from the headers of a
  /// response from the Amazon Transcribe Streaming API.
  factory StartStreamTranscriptionResponse.fromHeaders(
      Map<String, String> headers) {
    return StartStreamTranscriptionResponse(
      requestId: headers['x-amzn-request-id'],
      languageCode: headers['x-amzn-transcribe-language-code'] != null
          ? LanguageCode.fromValue(headers['x-amzn-transcribe-language-code']!)
          : null,
      mediaSampleRateHertz: headers['x-amzn-transcribe-sample-rate'] != null
          ? int.parse(headers['x-amzn-transcribe-sample-rate']!)
          : null,
      mediaEncoding: headers['x-amzn-transcribe-media-encoding'] != null
          ? MediaEncoding.fromValue(
              headers['x-amzn-transcribe-media-encoding']!)
          : null,
      vocabularyName: headers['x-amzn-transcribe-vocabulary-name'],
      sessionId: headers['x-amzn-transcribe-session-id'],
      vocabularyFilterName: headers['x-amzn-transcribe-vocabulary-filter-name'],
      vocabularyFilterMethod:
          headers['x-amzn-transcribe-vocabulary-filter-method'] != null
              ? VocabularyFilterMethod.fromValue(
                  headers['x-amzn-transcribe-vocabulary-filter-method']!)
              : null,
      showSpeakerLabel: headers['x-amzn-transcribe-show-speaker-label'] != null
          ? headers['x-amzn-transcribe-show-speaker-label'] == 'true'
          : null,
      enableChannelIdentification:
          headers['x-amzn-transcribe-enable-channel-identification'] != null
              ? headers['x-amzn-transcribe-enable-channel-identification'] ==
                  'true'
              : null,
      numberOfChannels: headers['x-amzn-transcribe-number-of-channels'] != null
          ? int.parse(headers['x-amzn-transcribe-number-of-channels']!)
          : null,
      enablePartialResultsStabilization: headers[
                  'x-amzn-transcribe-enable-partial-results-stabilization'] !=
              null
          ? headers['x-amzn-transcribe-enable-partial-results-stabilization'] ==
              'true'
          : null,
      partialResultsStability:
          headers['x-amzn-transcribe-partial-results-stability'] != null
              ? PartialResultsStability.fromValue(
                  headers['x-amzn-transcribe-partial-results-stability']!)
              : null,
      contentIdentificationType:
          headers['x-amzn-transcribe-content-identification-type'] != null
              ? ContentIdentificationType.fromValue(
                  headers['x-amzn-transcribe-content-identification-type']!)
              : null,
      contentRedactionType:
          headers['x-amzn-transcribe-content-redaction-type'] != null
              ? ContentRedactionType.fromValue(
                  headers['x-amzn-transcribe-content-redaction-type']!)
              : null,
      piiEntityTypes: headers['x-amzn-transcribe-pii-entity-types'],
      languageModelName: headers['x-amzn-transcribe-language-model-name'],
      identifyLanguage: headers['x-amzn-transcribe-identify-language'] != null
          ? headers['x-amzn-transcribe-identify-language'] == 'true'
          : null,
      languageOptions: headers['x-amzn-transcribe-language-options'],
      preferredLanguage: headers['x-amzn-transcribe-preferred-language'] != null
          ? LanguageCode.fromValue(
              headers['x-amzn-transcribe-preferred-language']!)
          : null,
      identifyMultipleLanguages:
          headers['x-amzn-transcribe-identify-multiple-languages'] != null
              ? headers['x-amzn-transcribe-identify-multiple-languages'] ==
                  'true'
              : null,
      vocabularyNames: headers['x-amzn-transcribe-vocabulary-names'],
      vocabularyFilterNames:
          headers['x-amzn-transcribe-vocabulary-filter-names'],
    );
  }

  /// Returns the headers for the response.
  Map<String, dynamic> toHeaders() {
    return <String, dynamic>{
      if (requestId != null) 'x-amzn-request-id': requestId,
      if (languageCode != null)
        'x-amzn-transcribe-language-code': languageCode?.value,
      if (mediaSampleRateHertz != null)
        'x-amzn-transcribe-sample-rate': mediaSampleRateHertz,
      if (mediaEncoding != null)
        'x-amzn-transcribe-media-encoding': mediaEncoding?.value,
      if (vocabularyName != null)
        'x-amzn-transcribe-vocabulary-name': vocabularyName,
      if (sessionId != null) 'x-amzn-transcribe-session-id': sessionId,
      if (vocabularyFilterName != null)
        'x-amzn-transcribe-vocabulary-filter-name': vocabularyFilterName,
      if (vocabularyFilterMethod != null)
        'x-amzn-transcribe-vocabulary-filter-method':
            vocabularyFilterMethod?.value,
      if (showSpeakerLabel != null)
        'x-amzn-transcribe-show-speaker-label': showSpeakerLabel,
      if (enableChannelIdentification != null)
        'x-amzn-transcribe-enable-channel-identification':
            enableChannelIdentification,
      if (numberOfChannels != null)
        'x-amzn-transcribe-number-of-channels': numberOfChannels,
      if (enablePartialResultsStabilization != null)
        'x-amzn-transcribe-enable-partial-results-stabilization':
            enablePartialResultsStabilization,
      if (partialResultsStability != null)
        'x-amzn-transcribe-partial-results-stability':
            partialResultsStability?.value,
      if (contentIdentificationType != null)
        'x-amzn-transcribe-content-identification-type':
            contentIdentificationType?.value,
      if (contentRedactionType != null)
        'x-amzn-transcribe-content-redaction-type': contentRedactionType?.value,
      if (piiEntityTypes != null)
        'x-amzn-transcribe-pii-entity-types': piiEntityTypes,
      if (languageModelName != null)
        'x-amzn-transcribe-language-model-name': languageModelName,
      if (identifyLanguage != null)
        'x-amzn-transcribe-identify-language': identifyLanguage,
      if (languageOptions != null)
        'x-amzn-transcribe-language-options': languageOptions,
      if (preferredLanguage != null)
        'x-amzn-transcribe-preferred-language': preferredLanguage?.value,
      if (identifyMultipleLanguages != null)
        'x-amzn-transcribe-identify-multiple-languages':
            identifyMultipleLanguages,
      if (vocabularyNames != null)
        'x-amzn-transcribe-vocabulary-names': vocabularyNames,
      if (vocabularyFilterNames != null)
        'x-amzn-transcribe-vocabulary-filter-names': vocabularyFilterNames,
    };
  }
}

/// Possible values for the `languageCode` parameter of a
/// [StartStreamTranscriptionRequest].
enum LanguageCode {
  deDe('de-DE'),
  enAu('en-AU'),
  enGb('en-GB'),
  enUs('en-US'),
  esUs('es-US'),
  frCa('fr-CA'),
  frFr('fr-FR'),
  hiIn('hi-IN'),
  itIt('it-IT'),
  jaJp('ja-JP'),
  koKr('ko-KR'),
  ptBr('pt-BR'),
  thTh('th-TH'),
  zhCn('zh-CN');

  /// Creates a [LanguageCode] with the given value.
  const LanguageCode(this.value);

  /// The language code value.
  final String value;

  /// Returns the [LanguageCode] for the given value.
  factory LanguageCode.fromValue(String value) {
    return LanguageCode.values.firstWhere((e) => e.value == value);
  }
}

/// Possible values for the `mediaEncoding` parameter of a
/// [StartStreamTranscriptionRequest].
enum MediaEncoding {
  flac('flac'),
  oggOpus('ogg-opus'),
  pcm('pcm');

  /// Creates a [MediaEncoding] with the given value.
  const MediaEncoding(this.value);

  /// The media encoding value.
  final String value;

  /// Returns the [MediaEncoding] for the given value.
  factory MediaEncoding.fromValue(String value) {
    return MediaEncoding.values.firstWhere((e) => e.value == value);
  }
}

/// Possible values for the `vocabularyFilterMethod` parameter of a
/// [StartStreamTranscriptionRequest].
enum VocabularyFilterMethod {
  mask('mask'),
  remove('remove'),
  tag('tag');

  /// Creates a [VocabularyFilterMethod] with the given value.
  const VocabularyFilterMethod(this.value);

  /// The vocabulary filter method value.
  final String value;

  /// Returns the [VocabularyFilterMethod] for the given value.
  factory VocabularyFilterMethod.fromValue(String value) {
    return VocabularyFilterMethod.values.firstWhere((e) => e.value == value);
  }
}

/// Possible values for the `partialResultsStability` parameter of a
/// [StartStreamTranscriptionRequest].
enum PartialResultsStability {
  high('high'),
  low('low'),
  medium('medium');

  /// Creates a [PartialResultsStability] with the given value.
  const PartialResultsStability(this.value);

  /// The partial results stability value.
  final String value;

  /// Returns the [PartialResultsStability] for the given value.
  factory PartialResultsStability.fromValue(String value) {
    return PartialResultsStability.values.firstWhere((e) => e.value == value);
  }
}

/// Possible values for the `contentIdentificationType` parameter of a
/// [StartStreamTranscriptionRequest].
enum ContentIdentificationType {
  pII('PII');

  /// Creates a [ContentIdentificationType] with the given value.
  const ContentIdentificationType(this.value);

  /// The content identification type value.
  final String value;

  /// Returns the [ContentIdentificationType] for the given value.
  factory ContentIdentificationType.fromValue(String value) {
    return ContentIdentificationType.values.firstWhere((e) => e.value == value);
  }
}

/// Possible values for the `contentRedactionType` parameter of a
/// [StartStreamTranscriptionRequest].
enum ContentRedactionType {
  pII('PII');

  /// Creates a [ContentRedactionType] with the given value.
  const ContentRedactionType(this.value);

  /// The content redaction type value.
  final String value;

  /// Returns the [ContentRedactionType] for the given value.
  factory ContentRedactionType.fromValue(String value) {
    return ContentRedactionType.values.firstWhere((e) => e.value == value);
  }
}

/// The `TranscriptEvent` associated with a `transcriptEventStream`
/// returned from [TranscribeStreamingClient.startStreamTranscription].
///
/// Contains a set of transcription results from one or more audio segments,
/// along with additional information per your request parameters.
final class TranscriptEvent {
  /// Contains `Results`, which contains a set of transcription results from
  /// one or more audio segments, along with additional information per your
  /// request parameters. This can include information relating to alternative
  /// transcriptions, channel identification, partial result stabilization,
  /// language identification, and other transcription-related data.
  final Transcript? transcript;

  /// Creates a [TranscriptEvent] from the given values.
  const TranscriptEvent({
    this.transcript,
  });

  /// Creates a [TranscriptEvent] from the given [Map].
  factory TranscriptEvent.fromMap(Map<String, dynamic> map) {
    return TranscriptEvent(
      transcript: map['Transcript'] != null
          ? Transcript.fromMap(map['Transcript'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Creates a [TranscriptEvent] from the given JSON string.
  factory TranscriptEvent.fromJson(String source) =>
      TranscriptEvent.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Returns the [Map] representation of this [TranscriptEvent].
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Transcript': transcript?.toMap(),
    };
  }

  /// Returns the JSON string representation of this [TranscriptEvent].
  String toJson() => json.encode(toMap());
}

/// The `Transcript` associated with a [TranscriptEvent].
///
/// [Transcript] contains [Result]s, which contains a set of transcription
/// results from one or more audio segments, along with additional information
/// per your request parameters.
final class Transcript {
  /// Contains a set of transcription results from one or more audio segments,
  /// along with additional information per your request parameters. This can
  /// include information relating to alternative transcriptions, channel
  /// identification, partial result stabilization, language identification,
  /// and other transcription-related data.
  final List<Result>? results;

  /// Creates a [Transcript] from the given values.
  const Transcript({
    this.results,
  });

  /// Creates a [Transcript] from the given [Map].
  factory Transcript.fromMap(Map<String, dynamic> map) {
    return Transcript(
      results: map['Results'] != null
          ? List<Result>.from(
              (map['Results'] as List<dynamic>).map<Result?>(
                (x) => Result.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  /// Creates a [Transcript] from the given JSON string.
  factory Transcript.fromJson(String source) =>
      Transcript.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Returns the [Map] representation of this [Transcript].
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Results': results?.map((x) => x.toMap()).toList(),
    };
  }

  /// Returns the JSON string representation of this [Transcript].
  String toJson() => json.encode(toMap());
}

/// The `Result` associated with a [TranscriptEvent].
///
/// Contains a set of transcription results from one or more audio segments,
/// along with additional information per your request parameters. This can
/// include information relating to alternative transcriptions, channel
/// identification, partial result stabilization, language identification,
/// and other transcription-related data.
final class Result {
  /// Provides a unique identifier for the [Result].
  final String? resultId;

  /// The start time, in milliseconds, of the [Result].
  final num? startTime;

  /// The end time, in milliseconds, of the [Result].
  final num? endTime;

  /// Indicates if the segment is complete.
  ///
  /// If [isPartial] is `true`, the segment is not complete.
  /// If [isPartial] is `false`, the segment is complete.
  final bool? isPartial;

  /// A list of possible alternative transcriptions for the input audio.
  ///
  /// Each alternative may contain one or more of [Item], [Entity],
  /// or [Transcript].
  final List<Alternative>? alternatives;

  /// Indicates which audio channel is associated with the [Result].
  final String? channelId;

  /// The language code that represents the language spoken in your stream.
  final LanguageCode? languageCode;

  /// The language code of the dominant language identified in your stream.
  ///
  /// If you enabled channel identification and each channel of your audio
  /// contains a different language, you may have more than one result.
  final List<LanguageWithScore>? languageIdentification;

  /// Creates a [Result] from the given values.
  const Result({
    this.resultId,
    this.startTime,
    this.endTime,
    this.isPartial,
    this.alternatives,
    this.channelId,
    this.languageCode,
    this.languageIdentification,
  });

  /// Creates a [Result] from the given [Map].
  factory Result.fromMap(Map<String, dynamic> map) {
    return Result(
      resultId: map['ResultId'] != null ? map['ResultId'] as String : null,
      startTime: map['StartTime'] != null ? map['StartTime'] as num : null,
      endTime: map['EndTime'] != null ? map['EndTime'] as num : null,
      isPartial: map['IsPartial'] != null ? map['IsPartial'] as bool : null,
      alternatives: map['Alternatives'] != null
          ? List<Alternative>.from(
              (map['Alternatives'] as List<dynamic>).map<Alternative?>(
                (x) => Alternative.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      channelId: map['ChannelId'] != null ? map['ChannelId'] as String : null,
      languageCode: map['LanguageCode'] != null
          ? LanguageCode.fromValue(map['LanguageCode'] as String)
          : null,
      languageIdentification: map['LanguageIdentification'] != null
          ? List<LanguageWithScore>.from(
              (map['LanguageIdentification'] as List<dynamic>)
                  .map<LanguageWithScore?>(
                (x) => LanguageWithScore.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  /// Creates a [Result] from the given JSON string.
  factory Result.fromJson(String source) =>
      Result.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Returns the [Map] representation of this [Result].
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ResultId': resultId,
      'StartTime': startTime,
      'EndTime': endTime,
      'IsPartial': isPartial,
      'Alternatives': alternatives?.map((x) => x.toMap()).toList(),
      'ChannelId': channelId,
      'LanguageCode': languageCode?.value,
      'LanguageIdentification':
          languageIdentification?.map((x) => x.toMap()).toList(),
    };
  }

  /// Returns the JSON string representation of this [Result].
  String toJson() => json.encode(toMap());
}

/// The language code that represents the language identified in your audio,
/// including the associated confidence score.
///
/// If you enabled channel identification in your request and each channel
/// contained a different language, you will have more than one
/// [LanguageWithScore] result.
final class LanguageWithScore {
  /// The language code of the identified language.
  final LanguageCode? languageCode;

  /// The confidence score associated with the identified language code.
  ///
  /// Confidence scores are values between zero and one; larger values indicate
  /// a higher confidence in the identified language.
  final double? score;

  /// Creates a [LanguageWithScore] from the given values.
  const LanguageWithScore({
    this.languageCode,
    this.score,
  });

  /// Creates a [LanguageWithScore] from the given [Map].
  factory LanguageWithScore.fromMap(Map<String, dynamic> map) {
    return LanguageWithScore(
      languageCode: map['LanguageCode'] != null
          ? LanguageCode.fromValue(map['LanguageCode'] as String)
          : null,
      score: map['Score'] != null ? map['Score'] as double : null,
    );
  }

  /// Creates a [LanguageWithScore] from the given JSON string.
  factory LanguageWithScore.fromJson(String source) =>
      LanguageWithScore.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Returns the [Map] representation of this [LanguageWithScore].
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'LanguageCode': languageCode?.value,
      'Score': score,
    };
  }

  /// Returns the JSON string representation of this [LanguageWithScore].
  String toJson() => json.encode(toMap());
}

/// A list of possible alternative transcriptions for the input audio.
///
/// Each alternative may contain one or more of [Item], [Entity],
/// or [Transcript].
final class Alternative {
  /// Contains transcribed text.
  final String? transcript;

  /// Contains words, phrases, or punctuation marks in your transcription
  /// output.
  final List<Item>? items;

  /// Contains entities identified as personally identifiable information (PII)
  /// in your transcription output.
  final List<Entity>? entities;

  /// Creates an [Alternative] from the given values.
  const Alternative({
    this.transcript,
    this.items,
    this.entities,
  });

  /// Creates an [Alternative] from the given [Map].
  factory Alternative.fromMap(Map<String, dynamic> map) {
    return Alternative(
      transcript:
          map['Transcript'] != null ? map['Transcript'] as String : null,
      items: map['Items'] != null
          ? List<Item>.from(
              (map['Items'] as List<dynamic>).map<Item?>(
                (x) => Item.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      entities: map['Entities'] != null
          ? List<Entity>.from(
              (map['Entities'] as List<dynamic>).map<Entity?>(
                (x) => Entity.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  /// Creates an [Alternative] from the given JSON string.
  factory Alternative.fromJson(String source) =>
      Alternative.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Returns the [Map] representation of this [Alternative].
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Transcript': transcript,
      'Items': items?.map((x) => x.toMap()).toList(),
      'Entities': entities?.map((x) => x.toMap()).toList(),
    };
  }

  /// Returns the JSON string representation of this [Alternative].
  String toJson() => json.encode(toMap());
}

/// A word, phrase, or punctuation mark in your transcription output,
/// along with various associated attributes, such as confidence score, type,
/// and start and end times.
final class Item {
  /// The start time, in milliseconds, of the transcribed item.
  final num? startTime;

  /// The end time, in milliseconds, of the transcribed item.
  final num? endTime;

  /// The type of item identified. Options are: `PRONUNCIATION` (spoken words)
  /// and `PUNCTUATION`.
  final ItemType? type;

  /// The word or punctuation that was transcribed.
  final String? content;

  /// Indicates whether the specified item matches a word in the vocabulary
  /// filter included in your request.
  ///
  /// If `true`, there is a vocabulary filter match.
  final bool? vocabularyFilterMatch;

  /// If speaker partitioning is enabled, [speaker] labels the speaker of
  /// the specified item.
  final String? speaker;

  /// The confidence score associated with a word or phrase in your transcript.
  ///
  /// Confidence scores are values between 0 and 1. A larger value indicates
  /// a higher probability that the identified item correctly matches
  /// the item spoken in your media.
  final double? confidence;

  /// If partial result stabilization is enabled, [stable] indicates whether
  /// the specified item is stable (`true`) or if it may change when the segment
  /// is complete (`false`).
  final bool? stable;

  /// Creates an [Item] from the given values.
  const Item({
    this.startTime,
    this.endTime,
    this.type,
    this.content,
    this.vocabularyFilterMatch,
    this.speaker,
    this.confidence,
    this.stable,
  });

  /// Creates an [Item] from the given [Map].
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      startTime: map['StartTime'] != null ? map['StartTime'] as num : null,
      endTime: map['EndTime'] != null ? map['EndTime'] as num : null,
      type: map['Type'] != null
          ? ItemType.fromValue(map['Type'] as String)
          : null,
      content: map['Content'] != null ? map['Content'] as String : null,
      vocabularyFilterMatch: map['VocabularyFilterMatch'] != null
          ? map['VocabularyFilterMatch'] as bool
          : null,
      speaker: map['Speaker'] != null ? map['Speaker'] as String : null,
      confidence:
          map['Confidence'] != null ? map['Confidence'] as double : null,
      stable: map['Stable'] != null ? map['Stable'] as bool : null,
    );
  }

  /// Creates an [Item] from the given JSON string.
  factory Item.fromJson(String source) =>
      Item.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Returns the [Map] representation of this [Item].
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'StartTime': startTime,
      'EndTime': endTime,
      'Type': type?.value,
      'Content': content,
      'VocabularyFilterMatch': vocabularyFilterMatch,
      'Speaker': speaker,
      'Confidence': confidence,
      'Stable': stable,
    };
  }

  /// Returns the JSON string representation of this [Item].
  String toJson() => json.encode(toMap());
}

/// The type of [Item] identified in a transcription.
enum ItemType {
  pronunciation('pronunciation'),
  punctuation('punctuation');

  /// Creates an [ItemType] with the given value.
  const ItemType(this.value);

  /// The item type value.
  final String value;

  /// Returns the [ItemType] for the given value.
  factory ItemType.fromValue(String value) {
    return ItemType.values.firstWhere((e) => e.value == value);
  }
}

/// Contains entities identified as personally identifiable information (PII)
/// in your transcription output, along with various associated attributes.
///
/// Examples include category, confidence score, type, stability score,
/// and start and end times.
final class Entity {
  /// The start time, in milliseconds, of the utterance that was identified
  /// as PII.
  final num? startTime;

  /// The end time, in milliseconds, of the utterance that was identified
  /// as PII.
  final num? endTime;

  /// The category of information identified. The only category is `PII`.
  final String? category;

  /// The type of PII identified. For example, `NAME` or `CREDIT_DEBIT_NUMBER`.
  final String? type;

  /// The word or words identified as PII.
  final String? content;

  /// The confidence score associated with the identified PII entity in audio.
  ///
  /// Confidence scores are values between 0 and 1. A larger value indicates
  /// a higher probability that the identified entity correctly matches
  /// the entity spoken in your media.
  final double? confidence;

  /// Creates an [Entity] from the given values.
  const Entity({
    this.startTime,
    this.endTime,
    this.category,
    this.type,
    this.content,
    this.confidence,
  });

  /// Creates an [Entity] from the given [Map].
  factory Entity.fromMap(Map<String, dynamic> map) {
    return Entity(
      startTime: map['StartTime'] != null ? map['StartTime'] as num : null,
      endTime: map['EndTime'] != null ? map['EndTime'] as num : null,
      category: map['Category'] != null ? map['Category'] as String : null,
      type: map['Type'] != null ? map['Type'] as String : null,
      content: map['Content'] != null ? map['Content'] as String : null,
      confidence:
          map['Confidence'] != null ? map['Confidence'] as double : null,
    );
  }

  /// Creates an [Entity] from the given JSON string.
  factory Entity.fromJson(String source) =>
      Entity.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Returns the [Map] representation of this [Entity].
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'StartTime': startTime,
      'EndTime': endTime,
      'Category': category,
      'Type': type,
      'Content': content,
      'Confidence': confidence,
    };
  }

  /// Returns the JSON string representation of this [Entity].
  String toJson() => json.encode(toMap());
}
