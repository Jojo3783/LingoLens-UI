import '../../application/analysis_telemetry.dart';
import '../../domain/analysis_models.dart';
import '../../domain/provider_contracts.dart';
import 'analysis_http_transport.dart';
import 'openai_request_builder.dart';
import 'openai_response_decoder.dart';

final class OpenAiResponsesAnalysisProvider implements AnalysisProvider {
  OpenAiResponsesAnalysisProvider({
    required this.configuration,
    required this.credentials,
    required this.transport,
    AnalysisTelemetrySink? telemetry,
    MonotonicClock? clock,
    OpenAiRequestBuilder? requestBuilder,
    OpenAiResponseDecoder? responseDecoder,
  }) : _telemetry = telemetry ?? InMemoryAnalysisTelemetrySink(),
       _clock = clock ?? SystemMonotonicClock(),
       _requestBuilder = requestBuilder ?? const OpenAiRequestBuilder(),
       _responseDecoder = responseDecoder ?? const OpenAiResponseDecoder();

  static const String providerLabel = 'OpenAI Responses API';

  final OpenAiProviderConfiguration configuration;
  final ProviderCredentialSource credentials;
  final AnalysisHttpTransport transport;
  final AnalysisTelemetrySink _telemetry;
  final MonotonicClock _clock;
  final OpenAiRequestBuilder _requestBuilder;
  final OpenAiResponseDecoder _responseDecoder;

  @override
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  ) async {
    final totalStart = _clock.now();
    var terminalOutcomeRecorded = false;
    var totalLatencyRecorded = false;

    void recordFailure(AnalysisError error) {
      if (terminalOutcomeRecorded) {
        return;
      }
      terminalOutcomeRecorded = true;
      final cancelled = error.code == AnalysisErrorCode.requestCancelled;
      _recordEvent(
        AnalysisTelemetryEvent(
          type: cancelled
              ? AnalysisTelemetryEventType.analysisRequestCancelled
              : AnalysisTelemetryEventType.analysisRequestFailed,
          requestId: request.requestId,
          providerKind: ProviderKind.openAiResponses,
          mode: request.mode,
          modelIdentifier: _sanitizedModel,
          stage: 'request',
          outcome: cancelled
              ? AnalysisTelemetryOutcome.cancelled
              : AnalysisTelemetryOutcome.failure,
          errorCode: error.code,
          duration: _elapsed(totalStart, _clock.now()),
        ),
      );
      if (!totalLatencyRecorded) {
        totalLatencyRecorded = true;
        _recordMetric(
          AnalysisMetricSample(
            name: AnalysisMetricName.totalLatencyMs,
            requestId: request.requestId,
            providerKind: ProviderKind.openAiResponses,
            mode: request.mode,
            modelIdentifier: _sanitizedModel,
            value: _elapsed(totalStart, _clock.now()),
          ),
        );
      }
    }

    _recordEvent(
      AnalysisTelemetryEvent(
        type: AnalysisTelemetryEventType.analysisRequestStarted,
        requestId: request.requestId,
        providerKind: ProviderKind.openAiResponses,
        mode: request.mode,
        modelIdentifier: _sanitizedModel,
        stage: 'request',
      ),
    );
    try {
      final setupStart = _clock.now();
      configuration.validate();
      context.cancellation.throwIfCancelled();
      final apiKey = _readCredential();
      context.cancellation.throwIfCancelled();
      final httpRequest = _requestBuilder.build(
        configuration: configuration,
        apiKey: apiKey,
        request: request,
        context: context,
      );
      context.cancellation.throwIfCancelled();
      _recordMetric(
        AnalysisMetricSample(
          name: AnalysisMetricName.providerSetupMs,
          requestId: request.requestId,
          providerKind: ProviderKind.openAiResponses,
          mode: request.mode,
          modelIdentifier: _sanitizedModel,
          value: _elapsed(setupStart, _clock.now()),
        ),
      );
      _recordEvent(
        AnalysisTelemetryEvent(
          type: AnalysisTelemetryEventType.providerStarted,
          requestId: request.requestId,
          providerKind: ProviderKind.openAiResponses,
          mode: request.mode,
          modelIdentifier: _sanitizedModel,
          stage: 'provider',
        ),
      );
      final response = await transport.postJson(httpRequest);
      _recordMetric(
        AnalysisMetricSample(
          name: AnalysisMetricName.responseReadMs,
          requestId: request.requestId,
          providerKind: ProviderKind.openAiResponses,
          mode: request.mode,
          modelIdentifier: _sanitizedModel,
          value: response.responseReadDuration,
        ),
      );
      _throwForStatus(response.statusCode);
      final decodeStart = _clock.now();
      late final AnalysisResult result;
      late final Duration decodeDuration;
      try {
        result = _responseDecoder.decode(response.body);
      } finally {
        decodeDuration = _elapsed(decodeStart, _clock.now());
        _recordMetric(
          AnalysisMetricSample(
            name: AnalysisMetricName.jsonDecodeMs,
            requestId: request.requestId,
            providerKind: ProviderKind.openAiResponses,
            mode: request.mode,
            modelIdentifier: _sanitizedModel,
            value: decodeDuration,
          ),
        );
      }
      _recordEvent(
        AnalysisTelemetryEvent(
          type: AnalysisTelemetryEventType.schemaDecodeCompleted,
          requestId: request.requestId,
          providerKind: ProviderKind.openAiResponses,
          mode: request.mode,
          modelIdentifier: _sanitizedModel,
          stage: 'schema_decode',
          outcome: AnalysisTelemetryOutcome.success,
          duration: decodeDuration,
        ),
      );
      terminalOutcomeRecorded = true;
      _recordEvent(
        AnalysisTelemetryEvent(
          type: AnalysisTelemetryEventType.providerCompleted,
          requestId: request.requestId,
          providerKind: ProviderKind.openAiResponses,
          mode: request.mode,
          modelIdentifier: _sanitizedModel,
          stage: 'provider',
          outcome: AnalysisTelemetryOutcome.success,
          duration: _elapsed(totalStart, _clock.now()),
          httpStatusCategory: response.statusCode ~/ 100,
        ),
      );
      _recordMetric(
        AnalysisMetricSample(
          name: AnalysisMetricName.totalLatencyMs,
          requestId: request.requestId,
          providerKind: ProviderKind.openAiResponses,
          mode: request.mode,
          modelIdentifier: _sanitizedModel,
          value: _elapsed(totalStart, _clock.now()),
        ),
      );
      totalLatencyRecorded = true;
      return result;
    } on AnalysisProviderException catch (exception) {
      recordFailure(exception.error);
      rethrow;
    } on AnalysisHttpTransportException catch (exception) {
      final error = switch (exception.kind) {
        AnalysisHttpFailureKind.timeout => const AnalysisError(
          AnalysisErrorCode.providerTimeout,
        ),
        AnalysisHttpFailureKind.cancelled =>
          const AnalysisError.requestCancelled(),
        AnalysisHttpFailureKind.responseTooLarge => const AnalysisError(
          AnalysisErrorCode.invalidStructuredOutput,
        ),
        AnalysisHttpFailureKind.transport =>
          const AnalysisError.providerFailed(),
      };
      recordFailure(error);
      throw AnalysisProviderException(error);
    } catch (_) {
      const error = AnalysisError.providerFailed();
      recordFailure(error);
      throw const AnalysisProviderException.providerFailed();
    }
  }

  String get _sanitizedModel {
    final value = configuration.model.trim();
    final normalized = value.replaceAll(RegExp(r'[^A-Za-z0-9._:-]'), '_');
    final boundedLength = normalized.length > 80 ? 80 : normalized.length;
    final sanitized = normalized.substring(0, boundedLength);
    return sanitized.isEmpty ? 'unknown_model' : sanitized;
  }

  String _readCredential() {
    try {
      final key = credentials.readApiKey();
      if (key == null || key.trim().isEmpty) {
        throw const AnalysisProviderException.configurationRequired();
      }
      return key;
    } on AnalysisProviderException {
      rethrow;
    } catch (_) {
      throw const AnalysisProviderException.configurationRequired();
    }
  }

  void _throwForStatus(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    if (statusCode == 401 || statusCode == 403) {
      throw const AnalysisProviderException.authenticationFailed();
    }
    if (statusCode == 429) {
      throw const AnalysisProviderException.rateLimited();
    }
    if (statusCode >= 500) {
      throw const AnalysisProviderException.providerFailed();
    }
    throw const AnalysisProviderException.providerFailed();
  }

  void _recordEvent(AnalysisTelemetryEvent event) {
    try {
      _telemetry.recordEvent(event);
    } catch (_) {
      // Telemetry 僅供診斷，不得改變 Provider outcome。
    }
  }

  void _recordMetric(AnalysisMetricSample sample) {
    try {
      _telemetry.recordMetric(sample);
    } catch (_) {
      // Telemetry 僅供診斷，不得改變 Provider outcome。
    }
  }

  Duration _elapsed(Duration start, Duration end) {
    final value = end - start;
    return value.isNegative ? Duration.zero : value;
  }
}
