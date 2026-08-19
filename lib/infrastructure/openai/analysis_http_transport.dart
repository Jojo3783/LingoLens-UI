import '../../domain/analysis_models.dart';

final class AnalysisHttpRequest {
  const AnalysisHttpRequest({
    required this.endpoint,
    required this.headers,
    required this.body,
    required this.timeout,
    required this.context,
  });

  final Uri endpoint;
  final Map<String, String> headers;
  final String body;
  final Duration timeout;
  final RequestContext context;
}

final class AnalysisHttpResponse {
  const AnalysisHttpResponse({
    required this.statusCode,
    required this.body,
    this.responseReadDuration = Duration.zero,
  });

  final int statusCode;
  final String body;
  final Duration responseReadDuration;
}

enum AnalysisHttpFailureKind { timeout, cancelled, transport, responseTooLarge }

final class AnalysisHttpTransportException implements Exception {
  const AnalysisHttpTransportException(this.kind);

  final AnalysisHttpFailureKind kind;
}

abstract interface class AnalysisHttpTransport {
  Future<AnalysisHttpResponse> postJson(AnalysisHttpRequest request);
}

abstract interface class HttpSessionFactory {
  HttpSession create();
}

abstract interface class HttpSession {
  Future<HttpRequestSession> postUrl(Uri endpoint);

  void close({required bool force});
}

abstract interface class HttpRequestSession {
  void setHeader(String name, String value);

  void setContentLength(int length);

  void writeBody(String body);

  Future<HttpResponseSession> close();

  void abort();
}

abstract interface class HttpResponseSession {
  int get statusCode;

  Stream<List<int>> get byteStream;
}

abstract interface class AnalysisTransportClock {
  Duration now();
}

final class SystemAnalysisTransportClock implements AnalysisTransportClock {
  SystemAnalysisTransportClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  Duration now() => _stopwatch.elapsed;
}
