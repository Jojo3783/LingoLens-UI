import '../domain/analysis_models.dart';
import '../domain/provider_contracts.dart';

enum AnalysisTelemetryEventType {
  analysisRequestStarted,
  providerStarted,
  providerCompleted,
  schemaDecodeCompleted,
  analysisRequestFailed,
  analysisRequestCancelled,
}

extension AnalysisTelemetryEventTypeContract on AnalysisTelemetryEventType {
  String get wireValue => switch (this) {
    AnalysisTelemetryEventType.analysisRequestStarted =>
      'analysis_request_started',
    AnalysisTelemetryEventType.providerStarted => 'provider_started',
    AnalysisTelemetryEventType.providerCompleted => 'provider_completed',
    AnalysisTelemetryEventType.schemaDecodeCompleted =>
      'schema_decode_completed',
    AnalysisTelemetryEventType.analysisRequestFailed =>
      'analysis_request_failed',
    AnalysisTelemetryEventType.analysisRequestCancelled =>
      'analysis_request_cancelled',
  };
}

enum AnalysisMetricName {
  providerSetupMs,
  responseReadMs,
  jsonDecodeMs,
  totalLatencyMs,
}

extension AnalysisMetricNameContract on AnalysisMetricName {
  String get wireValue => switch (this) {
    AnalysisMetricName.providerSetupMs => 'provider_setup_ms',
    AnalysisMetricName.responseReadMs => 'response_read_ms',
    AnalysisMetricName.jsonDecodeMs => 'json_decode_ms',
    AnalysisMetricName.totalLatencyMs => 'total_latency_ms',
  };
}

enum AnalysisTelemetryOutcome { success, failure, cancelled }

abstract interface class MonotonicClock {
  Duration now();
}

final class SystemMonotonicClock implements MonotonicClock {
  SystemMonotonicClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  Duration now() => _stopwatch.elapsed;
}

final class AnalysisTelemetryEvent {
  const AnalysisTelemetryEvent({
    required this.type,
    required this.requestId,
    required this.providerKind,
    required this.mode,
    this.modelIdentifier,
    this.stage,
    this.outcome,
    this.errorCode,
    this.duration,
    this.httpStatusCategory,
  });

  final AnalysisTelemetryEventType type;
  final RequestId requestId;
  final ProviderKind providerKind;
  final AnalysisMode mode;
  final String? modelIdentifier;
  final String? stage;
  final AnalysisTelemetryOutcome? outcome;
  final AnalysisErrorCode? errorCode;
  final Duration? duration;
  final int? httpStatusCategory;
}

final class AnalysisMetricSample {
  const AnalysisMetricSample({
    required this.name,
    required this.requestId,
    required this.providerKind,
    required this.mode,
    required this.value,
    this.modelIdentifier,
  });

  final AnalysisMetricName name;
  final RequestId requestId;
  final ProviderKind providerKind;
  final AnalysisMode mode;
  final Duration value;
  final String? modelIdentifier;
}

abstract interface class AnalysisTelemetrySink {
  void recordEvent(AnalysisTelemetryEvent event);

  void recordMetric(AnalysisMetricSample sample);
}

final class InMemoryAnalysisTelemetrySink implements AnalysisTelemetrySink {
  InMemoryAnalysisTelemetrySink({this.capacity = 200}) : assert(capacity > 0);

  final int capacity;
  final List<AnalysisTelemetryEvent> events = <AnalysisTelemetryEvent>[];
  final List<AnalysisMetricSample> metrics = <AnalysisMetricSample>[];

  @override
  void recordEvent(AnalysisTelemetryEvent event) {
    events.add(event);
    _trim(events);
  }

  @override
  void recordMetric(AnalysisMetricSample sample) {
    metrics.add(sample);
    _trim(metrics);
  }

  void _trim<T>(List<T> values) {
    if (values.length > capacity) {
      values.removeRange(0, values.length - capacity);
    }
  }
}
