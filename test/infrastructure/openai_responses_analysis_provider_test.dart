import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:lingolens/application/analysis_state.dart';
import 'package:lingolens/application/analysis_telemetry.dart';
import 'package:lingolens/application/provider_composition.dart';
import 'package:lingolens/domain/analysis_models.dart';
import 'package:lingolens/domain/provider_contracts.dart';
import 'package:lingolens/infrastructure/fake_analysis_provider.dart';
import 'package:lingolens/infrastructure/openai/analysis_http_transport.dart';
import 'package:lingolens/infrastructure/openai/openai_responses_analysis_provider.dart';

void main() {
  group('OpenAiResponsesAnalysisProvider', () {
    test('default composition stays Fake and makes no HTTP request', () {
      final composition = createAnalysisProviderComposition();

      expect(composition.provider, isA<FakeAnalysisProvider>());
      expect(
        composition.strategy.initialStage(composition.provider),
        AnalysisLoadingStage.preview,
      );
      expect(composition.disclosure!.message, contains('不會傳送網路請求'));
    });

    test('missing configuration fails before transport invocation', () async {
      final transport = RecordingTransport();
      final provider = _provider(transport, model: '');

      await expectLater(
        provider.analyzeFull(_request(), _context()),
        throwsA(
          isA<AnalysisProviderException>().having(
            (error) => error.error.code,
            'code',
            AnalysisErrorCode.providerConfigurationRequired,
          ),
        ),
      );
      expect(transport.requests, isEmpty);
    });

    test(
      'missing credential stays selected as typed configuration failure',
      () async {
        final transport = RecordingTransport();
        final provider = _provider(transport, credential: null);

        await expectLater(
          provider.analyzeFull(_request(), _context()),
          throwsA(
            isA<AnalysisProviderException>().having(
              (error) => error.error.code,
              'code',
              AnalysisErrorCode.providerConfigurationRequired,
            ),
          ),
        );
        expect(transport.requests, isEmpty);
      },
    );

    test(
      'builds exact Responses API request and decodes typed result',
      () async {
        final transport = RecordingTransport()..response = _successResponse();
        final telemetry = InMemoryAnalysisTelemetrySink();
        final provider = _provider(transport, telemetry: telemetry);
        final request = _request(input: '你好 🌏 sentinel');

        final result = await provider.analyzeFull(request, _context());
        final payload = jsonDecode(transport.requests.single.body) as Map;
        final input = payload['input'] as List;
        final system = input[0] as Map;
        final user = input[1] as Map;
        final schema =
            ((payload['text'] as Map)['format'] as Map)['schema'] as Map;

        expect(
          transport.requests.single.endpoint.toString(),
          'https://api.openai.com/v1/responses',
        );
        expect(
          transport.requests.single.headers['Authorization'],
          'Bearer controlled-credential',
        );
        expect(payload['model'], 'gpt-test');
        expect(payload['store'], false);
        expect(system['role'], 'system');
        expect(user['role'], 'user');
        expect(
          (system['content'] as List).single['text'],
          isNot(contains('sentinel')),
        );
        expect((user['content'] as List).last['text'], '你好 🌏 sentinel');
        expect(
          (payload['text'] as Map)['format'],
          containsPair('type', 'json_schema'),
        );
        expect(
          (payload['text'] as Map)['format'],
          containsPair('strict', true),
        );
        expect(schema['additionalProperties'], false);
        expect(
          schema['required'],
          containsAll(<String>['reading', 'expression']),
        );
        expect(result.schemaVersion, analysisSchemaVersion);
        expect(result.providerLabel, 'OpenAI Responses API');
        expect(result.reading.translation, 'translated');
        expect(result.expression.natural, 'natural');
        expect(telemetry.events.map((event) => event.type.wireValue), [
          'analysis_request_started',
          'provider_started',
          'schema_decode_completed',
          'provider_completed',
        ]);
        expect(
          telemetry.metrics.map((metric) => metric.name.wireValue),
          containsAll(<String>[
            'provider_setup_ms',
            'response_read_ms',
            'json_decode_ms',
            'total_latency_ms',
          ]),
        );
      },
    );

    test(
      'records exact transport latency boundaries and successful event ordering',
      () async {
        final transport = RecordingTransport()
          ..response = AnalysisHttpResponse(
            statusCode: 200,
            body: _responseWithText(
              jsonEncode({'reading': _reading(), 'expression': _expression()}),
            ),
            responseReadDuration: const Duration(milliseconds: 37),
          );
        final telemetry = InMemoryAnalysisTelemetrySink();
        final provider = _provider(
          transport,
          telemetry: telemetry,
          clock: _SequenceClock(<Duration>[
            Duration.zero,
            const Duration(milliseconds: 10),
            const Duration(milliseconds: 20),
            const Duration(milliseconds: 30),
            const Duration(milliseconds: 42),
            const Duration(milliseconds: 50),
            const Duration(milliseconds: 60),
          ]),
        );

        await provider.analyzeFull(_request(), _context());

        final metrics = <AnalysisMetricName, Duration>{
          for (final metric in telemetry.metrics) metric.name: metric.value,
        };
        expect(
          metrics[AnalysisMetricName.providerSetupMs],
          const Duration(milliseconds: 10),
        );
        expect(
          metrics[AnalysisMetricName.responseReadMs],
          const Duration(milliseconds: 37),
        );
        expect(
          metrics[AnalysisMetricName.jsonDecodeMs],
          const Duration(milliseconds: 12),
        );
        expect(
          metrics[AnalysisMetricName.totalLatencyMs],
          const Duration(milliseconds: 60),
        );
        expect(telemetry.events.map((event) => event.type), [
          AnalysisTelemetryEventType.analysisRequestStarted,
          AnalysisTelemetryEventType.providerStarted,
          AnalysisTelemetryEventType.schemaDecodeCompleted,
          AnalysisTelemetryEventType.providerCompleted,
        ]);
      },
    );

    test(
      'invalid schema emits one failure terminal outcome and no provider completion',
      () async {
        final telemetry = InMemoryAnalysisTelemetrySink();
        final provider = _provider(
          RecordingTransport()
            ..response = AnalysisHttpResponse(
              statusCode: 200,
              body: _responseWithText('{"reading":{}}'),
            ),
          telemetry: telemetry,
        );

        await expectLater(
          provider.analyzeFull(_request(), _context()),
          throwsA(isA<AnalysisProviderException>()),
        );

        expect(
          telemetry.events.where(
            (event) =>
                event.type == AnalysisTelemetryEventType.providerCompleted,
          ),
          isEmpty,
        );
        expect(
          telemetry.events.where(
            (event) =>
                event.type == AnalysisTelemetryEventType.analysisRequestFailed,
          ),
          hasLength(1),
        );
      },
    );

    test(
      'maps refusal, incomplete, malformed, empty, and unexpected output',
      () async {
        final cases = <String, String>{
          'refusal': jsonEncode({
            'status': 'completed',
            'output': [
              {
                'type': 'message',
                'content': [
                  {'type': 'refusal', 'refusal': 'no'},
                ],
              },
            ],
          }),
          'incomplete': jsonEncode({'status': 'incomplete'}),
          'malformed': 'not-json',
          'empty': jsonEncode({'status': 'completed', 'output': []}),
          'unexpected': _responseWithText(jsonEncode({'reading': _reading()})),
        };

        for (final entry in cases.entries) {
          final transport = RecordingTransport()
            ..response = AnalysisHttpResponse(
              statusCode: 200,
              body: entry.value,
            );
          final provider = _provider(transport);
          await expectLater(
            provider.analyzeFull(_request(), _context()),
            throwsA(
              isA<AnalysisProviderException>().having(
                (error) => error.error.code,
                'code',
                entry.key == 'refusal'
                    ? AnalysisErrorCode.providerRefused
                    : AnalysisErrorCode.invalidStructuredOutput,
              ),
            ),
            reason: entry.key,
          );
        }
      },
    );

    test('maps authentication, rate limit, and server failures', () async {
      for (final entry in <int, AnalysisErrorCode>{
        401: AnalysisErrorCode.providerAuthenticationFailed,
        403: AnalysisErrorCode.providerAuthenticationFailed,
        429: AnalysisErrorCode.providerRateLimited,
        500: AnalysisErrorCode.providerFailed,
      }.entries) {
        final transport = RecordingTransport()
          ..response = AnalysisHttpResponse(statusCode: entry.key, body: '{}');
        final provider = _provider(transport);
        await expectLater(
          provider.analyzeFull(_request(), _context()),
          throwsA(
            isA<AnalysisProviderException>().having(
              (error) => error.error.code,
              'code',
              entry.value,
            ),
          ),
        );
      }
    });

    test('propagates cancellation to transport exactly once', () async {
      final transport = RecordingTransport()..hold = true;
      final provider = _provider(transport);
      final context = _context();
      final future = provider.analyzeFull(_request(), context);
      await pumpEventQueue();
      context.cancel();

      await expectLater(
        future,
        throwsA(
          isA<AnalysisProviderException>().having(
            (error) => error.error.code,
            'code',
            AnalysisErrorCode.requestCancelled,
          ),
        ),
      );
      expect(transport.abortCount, 1);
    });

    test('telemetry sink failure cannot change successful outcome', () async {
      final transport = RecordingTransport()..response = _successResponse();
      final provider = _provider(transport, telemetry: ThrowingTelemetrySink());

      final result = await provider.analyzeFull(_request(), _context());

      expect(result.providerLabel, 'OpenAI Responses API');
    });
  });
}

OpenAiResponsesAnalysisProvider _provider(
  RecordingTransport transport, {
  String model = 'gpt-test',
  String? credential = 'controlled-credential',
  AnalysisTelemetrySink? telemetry,
  MonotonicClock? clock,
}) => OpenAiResponsesAnalysisProvider(
  configuration: OpenAiProviderConfiguration(model: model),
  credentials: _Credentials(credential),
  transport: transport,
  telemetry: telemetry,
  clock: clock ?? _Clock(),
);

AnalysisRequest _request({String input = 'hello'}) => AnalysisRequest(
  requestId: RequestId.create(),
  input: input,
  mode: AnalysisMode.reading,
);

RequestContext _context() => RequestContext(
  requestId: RequestId.create(),
  cancellation: CancellationToken(),
);

AnalysisHttpResponse _successResponse() => AnalysisHttpResponse(
  statusCode: 200,
  body: _responseWithText(
    jsonEncode({'reading': _reading(), 'expression': _expression()}),
  ),
);

String _responseWithText(String text) => jsonEncode({
  'status': 'completed',
  'output': [
    {
      'type': 'message',
      'content': [
        {'type': 'output_text', 'text': text},
      ],
    },
  ],
});

Map<String, String> _reading() => <String, String>{
  'translation': 'translated',
  'sentenceAnalysis': 'sentence',
  'grammar': 'grammar',
  'vocabulary': 'vocabulary',
  'nuance': 'nuance',
};

Map<String, String> _expression() => <String, String>{
  'natural': 'natural',
  'polite': 'polite',
  'formal': 'formal',
  'context': 'context',
  'tone': 'tone',
};

final class _Credentials implements ProviderCredentialSource {
  const _Credentials(this.value);

  final String? value;

  @override
  String? readApiKey() => value;
}

final class _Clock implements MonotonicClock {
  Duration _current = Duration.zero;

  @override
  Duration now() {
    _current += const Duration(milliseconds: 1);
    return _current;
  }
}

final class _SequenceClock implements MonotonicClock {
  _SequenceClock(this._values);

  final List<Duration> _values;
  var _index = 0;

  @override
  Duration now() {
    final value =
        _values[_index < _values.length ? _index : _values.length - 1];
    _index++;
    return value;
  }
}

final class RecordingTransport implements AnalysisHttpTransport {
  final List<AnalysisHttpRequest> requests = <AnalysisHttpRequest>[];
  AnalysisHttpResponse response = _successResponse();
  bool hold = false;
  int abortCount = 0;
  Completer<AnalysisHttpResponse>? _completer;

  @override
  Future<AnalysisHttpResponse> postJson(AnalysisHttpRequest request) {
    requests.add(request);
    if (!hold) {
      return Future<AnalysisHttpResponse>.value(response);
    }
    _completer = Completer<AnalysisHttpResponse>();
    request.context.cancellation.addListener(() {
      abortCount++;
      _completer!.completeError(
        const AnalysisHttpTransportException(AnalysisHttpFailureKind.cancelled),
      );
    });
    return _completer!.future;
  }
}

final class ThrowingTelemetrySink implements AnalysisTelemetrySink {
  @override
  void recordEvent(AnalysisTelemetryEvent event) => throw StateError('sink');

  @override
  void recordMetric(AnalysisMetricSample sample) => throw StateError('sink');
}
