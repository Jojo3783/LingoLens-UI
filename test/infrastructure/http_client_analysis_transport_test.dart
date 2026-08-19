import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:lingolens/domain/analysis_models.dart';
import 'package:lingolens/infrastructure/openai/analysis_http_transport.dart';
import 'package:lingolens/infrastructure/openai/http_client_analysis_transport.dart';

void main() {
  group('HttpClientAnalysisHttpTransport', () {
    test(
      'cancellation before request establishment closes client and sends no body',
      () async {
        final session = ControlledHttpSession();
        final transport = HttpClientAnalysisHttpTransport(
          sessionFactory: ControlledHttpSessionFactory(session),
        );
        final context = _context();
        final future = transport.postJson(_request(context));

        await pumpEventQueue();
        context.cancel();
        session.completePostUrlWithError(StateError('socket closed'));

        await expectLater(
          future,
          throwsA(
            isA<AnalysisHttpTransportException>().having(
              (error) => error.kind,
              'kind',
              AnalysisHttpFailureKind.cancelled,
            ),
          ),
        );
        expect(session.forceClosed, isTrue);
        expect(session.request?.writeCount ?? 0, 0);
      },
    );

    test(
      'cancellation after request establishment aborts request before body write',
      () async {
        final session = ControlledHttpSession(autoCreateRequest: true);
        final context = _context();
        session.onHeader = context.cancel;
        final transport = HttpClientAnalysisHttpTransport(
          sessionFactory: ControlledHttpSessionFactory(session),
        );

        await expectLater(
          transport.postJson(_request(context)),
          throwsA(
            isA<AnalysisHttpTransportException>().having(
              (error) => error.kind,
              'kind',
              AnalysisHttpFailureKind.cancelled,
            ),
          ),
        );
        expect(session.request?.abortCount, 1);
        expect(session.request?.writeCount, 0);
      },
    );

    test('cancellation wins a transport exception race', () async {
      final session = ControlledHttpSession();
      final context = _context();
      final transport = HttpClientAnalysisHttpTransport(
        sessionFactory: ControlledHttpSessionFactory(session),
      );
      final future = transport.postJson(_request(context));

      await pumpEventQueue();
      context.cancel();
      session.completePostUrlWithError(StateError('connection reset'));

      await expectLater(
        future,
        throwsA(
          isA<AnalysisHttpTransportException>().having(
            (error) => error.kind,
            'kind',
            AnalysisHttpFailureKind.cancelled,
          ),
        ),
      );
    });

    test(
      'response body limit accepts exact limit and rejects limit plus one byte',
      () async {
        final exactSession = ControlledHttpSession(
          autoCreateRequest: true,
          responseBody: utf8.encode('12345'),
        );
        final exactTransport = HttpClientAnalysisHttpTransport(
          sessionFactory: ControlledHttpSessionFactory(exactSession),
          maxResponseBytes: 5,
        );
        final exact = await exactTransport.postJson(_request(_context()));
        expect(exact.body, '12345');

        final oversizedSession = ControlledHttpSession(
          autoCreateRequest: true,
          responseBody: utf8.encode('123456'),
        );
        final oversizedTransport = HttpClientAnalysisHttpTransport(
          sessionFactory: ControlledHttpSessionFactory(oversizedSession),
          maxResponseBytes: 5,
        );

        await expectLater(
          oversizedTransport.postJson(_request(_context())),
          throwsA(
            isA<AnalysisHttpTransportException>().having(
              (error) => error.kind,
              'kind',
              AnalysisHttpFailureKind.responseTooLarge,
            ),
          ),
        );
        expect(oversizedSession.forceClosed, isTrue);
      },
    );

    test('connect and body stages share one overall deadline', () async {
      final session = ControlledHttpSession(
        postUrlFuture: Future<HttpRequestSession>.delayed(
          const Duration(milliseconds: 8),
          () => ControlledHttpRequest(
            responseFuture: Future<HttpResponseSession>.delayed(
              const Duration(milliseconds: 8),
              () => ControlledHttpResponse(body: const <List<int>>[]),
            ),
          ),
        ),
      );
      final transport = HttpClientAnalysisHttpTransport(
        sessionFactory: ControlledHttpSessionFactory(session),
      );

      final stopwatch = Stopwatch()..start();
      await expectLater(
        transport.postJson(
          _request(_context(), timeout: const Duration(milliseconds: 10)),
        ),
        throwsA(
          isA<AnalysisHttpTransportException>().having(
            (error) => error.kind,
            'kind',
            AnalysisHttpFailureKind.timeout,
          ),
        ),
      );
      stopwatch.stop();
      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 35)));
    });
  });
}

AnalysisHttpRequest _request(
  RequestContext context, {
  Duration timeout = const Duration(seconds: 1),
}) => AnalysisHttpRequest(
  endpoint: Uri.parse('https://example.test/responses'),
  headers: const <String, String>{'Authorization': 'Bearer controlled'},
  body: '{"input":"sentinel"}',
  timeout: timeout,
  context: context,
);

RequestContext _context() => RequestContext(
  requestId: RequestId.create(),
  cancellation: CancellationToken(),
);

final class ControlledHttpSessionFactory implements HttpSessionFactory {
  const ControlledHttpSessionFactory(this.session);

  final ControlledHttpSession session;

  @override
  HttpSession create() => session;
}

final class ControlledHttpSession implements HttpSession {
  ControlledHttpSession({
    this.responseBody = const <int>[],
    Future<HttpRequestSession>? postUrlFuture,
    Future<HttpResponseSession>? responseFuture,
    this.autoCreateRequest = false,
  }) : _postUrlFuture = postUrlFuture,
       _responseFuture = responseFuture;

  final List<int> responseBody;
  final Future<HttpRequestSession>? _postUrlFuture;
  final Future<HttpResponseSession>? _responseFuture;
  final bool autoCreateRequest;
  final Completer<HttpRequestSession> _postUrl =
      Completer<HttpRequestSession>();
  ControlledHttpRequest? request;
  void Function()? onHeader;
  bool forceClosed = false;

  @override
  Future<HttpRequestSession> postUrl(Uri endpoint) {
    if (_postUrlFuture != null) {
      return _postUrlFuture;
    }
    if (autoCreateRequest) {
      return Future<HttpRequestSession>.value(createRequest());
    }
    return _postUrl.future;
  }

  @override
  void close({required bool force}) => forceClosed = force;

  void completePostUrlWithError(Object error) {
    if (!_postUrl.isCompleted) {
      _postUrl.completeError(error);
    }
  }

  ControlledHttpRequest createRequest() {
    final created = ControlledHttpRequest(
      onHeader: onHeader,
      responseFuture:
          _responseFuture ??
          Future<HttpResponseSession>.value(
            ControlledHttpResponse(body: <List<int>>[responseBody]),
          ),
    );
    request = created;
    if (!_postUrl.isCompleted) {
      _postUrl.complete(created);
    }
    return created;
  }
}

final class ControlledHttpRequest implements HttpRequestSession {
  ControlledHttpRequest({this.onHeader, required this.responseFuture});

  final void Function()? onHeader;
  final Future<HttpResponseSession> responseFuture;
  int writeCount = 0;
  int abortCount = 0;

  @override
  void setHeader(String name, String value) => onHeader?.call();

  @override
  void setContentLength(int length) {}

  @override
  void writeBody(String body) => writeCount++;

  @override
  Future<HttpResponseSession> close() => responseFuture;

  @override
  void abort() => abortCount++;
}

final class ControlledHttpResponse implements HttpResponseSession {
  const ControlledHttpResponse({required this.body});

  final List<List<int>> body;

  @override
  int get statusCode => 200;

  @override
  Stream<List<int>> get byteStream => Stream<List<int>>.fromIterable(body);
}
