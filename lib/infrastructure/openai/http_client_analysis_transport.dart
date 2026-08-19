import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/analysis_models.dart';
import 'analysis_http_transport.dart';

/// `maxResponseBytes` 是單次 Provider response body 的硬性 byte 上限。
const int defaultMaxResponseBytes = 1024 * 1024;

final class HttpClientAnalysisHttpTransport implements AnalysisHttpTransport {
  HttpClientAnalysisHttpTransport({
    HttpSessionFactory? sessionFactory,
    AnalysisTransportClock? clock,
    this.maxResponseBytes = defaultMaxResponseBytes,
  }) : _sessionFactory = sessionFactory ?? const IoHttpSessionFactory(),
       _clock = clock ?? SystemAnalysisTransportClock();

  final HttpSessionFactory _sessionFactory;
  final AnalysisTransportClock _clock;
  final int maxResponseBytes;

  @override
  Future<AnalysisHttpResponse> postJson(AnalysisHttpRequest request) async {
    if (maxResponseBytes <= 0) {
      throw ArgumentError.value(maxResponseBytes, 'maxResponseBytes');
    }

    final session = _sessionFactory.create();
    HttpRequestSession? activeRequest;
    final cancellationSignal = Completer<void>();
    final deadline = _clock.now() + request.timeout;

    void abortTransport() {
      try {
        activeRequest?.abort();
      } catch (_) {
        // 即使 abort 失敗，Cancellation 仍必須保持 typed 結果。
      }
      try {
        session.close(force: true);
      } catch (_) {
        // 即使 client close 失敗，Cancellation 仍必須保持 typed 結果。
      }
      if (!cancellationSignal.isCompleted) {
        cancellationSignal.complete();
      }
    }

    request.context.cancellation.addListener(abortTransport);
    try {
      request.context.cancellation.throwIfCancelled();
      final createdRequest = await _awaitStage(
        operation: session.postUrl(request.endpoint),
        cancellation: cancellationSignal.future,
        token: request.context.cancellation,
        deadline: deadline,
        abort: abortTransport,
      );
      request.context.cancellation.throwIfCancelled();
      activeRequest = createdRequest;

      for (final entry in request.headers.entries) {
        request.context.cancellation.throwIfCancelled();
        createdRequest.setHeader(entry.key, entry.value);
      }
      request.context.cancellation.throwIfCancelled();
      final bodyBytes = utf8.encode(request.body);
      request.context.cancellation.throwIfCancelled();
      createdRequest.setContentLength(bodyBytes.length);
      request.context.cancellation.throwIfCancelled();
      createdRequest.writeBody(request.body);

      request.context.cancellation.throwIfCancelled();
      final response = await _awaitStage(
        operation: createdRequest.close(),
        cancellation: cancellationSignal.future,
        token: request.context.cancellation,
        deadline: deadline,
        abort: abortTransport,
      );
      request.context.cancellation.throwIfCancelled();

      final responseReadStart = _clock.now();
      final bodyRead = _startBodyRead(
        response: response,
        context: request.context,
        activeRequest: activeRequest,
        session: session,
        cancellationSignal: cancellationSignal.future,
      );
      late final String body;
      try {
        body = await _awaitStage(
          operation: bodyRead.future,
          cancellation: cancellationSignal.future,
          token: request.context.cancellation,
          deadline: deadline,
          abort: abortTransport,
        );
      } finally {
        await bodyRead.cancel();
      }
      request.context.cancellation.throwIfCancelled();

      return AnalysisHttpResponse(
        statusCode: response.statusCode,
        body: body,
        responseReadDuration: _elapsed(responseReadStart, _clock.now()),
      );
    } on AnalysisHttpTransportException {
      rethrow;
    } on AnalysisProviderException catch (exception) {
      if (exception.error.code == AnalysisErrorCode.requestCancelled) {
        throw const AnalysisHttpTransportException(
          AnalysisHttpFailureKind.cancelled,
        );
      }
      rethrow;
    } on TimeoutException {
      abortTransport();
      throw const AnalysisHttpTransportException(
        AnalysisHttpFailureKind.timeout,
      );
    } on Object {
      if (request.context.cancellation.isCancelled) {
        throw const AnalysisHttpTransportException(
          AnalysisHttpFailureKind.cancelled,
        );
      }
      throw const AnalysisHttpTransportException(
        AnalysisHttpFailureKind.transport,
      );
    } finally {
      request.context.cancellation.removeListener(abortTransport);
      try {
        session.close(force: true);
      } catch (_) {
        // Cleanup 失敗不得改變已完成的 Provider outcome。
      }
    }
  }

  Future<T> _awaitStage<T>({
    required Future<T> operation,
    required Future<void> cancellation,
    required CancellationToken token,
    required Duration deadline,
    required void Function() abort,
  }) async {
    final remaining = deadline - _clock.now();
    if (remaining <= Duration.zero) {
      abort();
      throw const AnalysisHttpTransportException(
        AnalysisHttpFailureKind.timeout,
      );
    }
    try {
      return await Future.any<T>(<Future<T>>[
        operation,
        cancellation.then<T>((_) {
          throw const AnalysisHttpTransportException(
            AnalysisHttpFailureKind.cancelled,
          );
        }),
      ]).timeout(remaining);
    } on AnalysisHttpTransportException {
      rethrow;
    } on TimeoutException {
      abort();
      throw const AnalysisHttpTransportException(
        AnalysisHttpFailureKind.timeout,
      );
    } on Object {
      if (token.isCancelled) {
        throw const AnalysisHttpTransportException(
          AnalysisHttpFailureKind.cancelled,
        );
      }
      rethrow;
    }
  }

  _BodyReadOperation _startBodyRead({
    required HttpResponseSession response,
    required RequestContext context,
    required HttpRequestSession? activeRequest,
    required HttpSession session,
    required Future<void> cancellationSignal,
  }) {
    final completer = Completer<String>();
    final bytes = <int>[];
    StreamSubscription<List<int>>? subscription;
    var finished = false;

    void closeTransport() {
      try {
        activeRequest?.abort();
      } catch (_) {
        // 保留 typed transport result。
      }
      try {
        session.close(force: true);
      } catch (_) {
        // 保留 typed transport result。
      }
    }

    void completeError(Object error, [StackTrace? stackTrace]) {
      if (finished) {
        return;
      }
      finished = true;
      final trace = stackTrace ?? StackTrace.current;
      subscription?.cancel();
      completer.completeError(error, trace);
    }

    void completeSuccess() {
      if (finished) {
        return;
      }
      finished = true;
      try {
        completer.complete(utf8.decode(bytes));
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    }

    subscription = response.byteStream.listen(
      (chunk) {
        if (context.cancellation.isCancelled) {
          closeTransport();
          completeError(
            const AnalysisHttpTransportException(
              AnalysisHttpFailureKind.cancelled,
            ),
          );
          return;
        }
        if (bytes.length + chunk.length > maxResponseBytes) {
          closeTransport();
          completeError(
            const AnalysisHttpTransportException(
              AnalysisHttpFailureKind.responseTooLarge,
            ),
          );
          return;
        }
        bytes.addAll(chunk);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (context.cancellation.isCancelled) {
          completeError(
            const AnalysisHttpTransportException(
              AnalysisHttpFailureKind.cancelled,
            ),
          );
          return;
        }
        completeError(error, stackTrace);
      },
      onDone: completeSuccess,
      cancelOnError: false,
    );

    cancellationSignal.then((_) {
      closeTransport();
      completeError(
        const AnalysisHttpTransportException(AnalysisHttpFailureKind.cancelled),
      );
    });

    return _BodyReadOperation(
      future: completer.future,
      cancel: () async => subscription?.cancel(),
    );
  }

  Duration _elapsed(Duration start, Duration end) {
    final value = end - start;
    return value.isNegative ? Duration.zero : value;
  }
}

final class _BodyReadOperation {
  const _BodyReadOperation({required this.future, required this.cancel});

  final Future<String> future;
  final Future<void> Function() cancel;
}

final class IoHttpSessionFactory implements HttpSessionFactory {
  const IoHttpSessionFactory();

  @override
  HttpSession create() => IoHttpSession(HttpClient());
}

final class IoHttpSession implements HttpSession {
  IoHttpSession(this._client);

  final HttpClient _client;

  @override
  Future<HttpRequestSession> postUrl(Uri endpoint) async =>
      IoHttpRequest(await _client.postUrl(endpoint));

  @override
  void close({required bool force}) => _client.close(force: force);
}

final class IoHttpRequest implements HttpRequestSession {
  IoHttpRequest(this._request);

  final HttpClientRequest _request;

  @override
  void setHeader(String name, String value) =>
      _request.headers.set(name, value);

  @override
  void setContentLength(int length) => _request.contentLength = length;

  @override
  void writeBody(String body) => _request.write(body);

  @override
  Future<HttpResponseSession> close() async =>
      IoHttpResponse(await _request.close());

  @override
  void abort() => _request.abort();
}

final class IoHttpResponse implements HttpResponseSession {
  IoHttpResponse(this._response);

  final HttpClientResponse _response;

  @override
  int get statusCode => _response.statusCode;

  @override
  Stream<List<int>> get byteStream => _response;
}
