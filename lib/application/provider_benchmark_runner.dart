import 'dart:async';

import '../domain/analysis_models.dart';
import '../domain/provider_contracts.dart';
import 'analysis_telemetry.dart';

final class ProviderBenchmarkMetrics {
  const ProviderBenchmarkMetrics({
    required this.providerKind,
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.cancelledRequests,
    required this.averageLatency,
    required this.averageSetupLatency,
    required this.averageReadLatency,
    required this.averageDecodeLatency,
    required this.schemaAdherenceRate,
    required this.failureRate,
    required this.cancellationSuccessRate,
    required this.estimatedTokenCount,
  });

  final ProviderKind providerKind;
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final int cancelledRequests;
  final Duration averageLatency;
  final Duration averageSetupLatency;
  final Duration averageReadLatency;
  final Duration averageDecodeLatency;
  final double schemaAdherenceRate;
  final double failureRate;
  final double cancellationSuccessRate;
  final int estimatedTokenCount;

  Map<String, Object?> toJson() => <String, Object?>{
    'providerKind': providerKind.wireValue,
    'totalRequests': totalRequests,
    'successfulRequests': successfulRequests,
    'failedRequests': failedRequests,
    'cancelledRequests': cancelledRequests,
    'averageLatencyMs': averageLatency.inMilliseconds,
    'averageSetupLatencyMs': averageSetupLatency.inMilliseconds,
    'averageReadLatencyMs': averageReadLatency.inMilliseconds,
    'averageDecodeLatencyMs': averageDecodeLatency.inMilliseconds,
    'schemaAdherenceRate': schemaAdherenceRate,
    'failureRate': failureRate,
    'cancellationSuccessRate': cancellationSuccessRate,
    'estimatedTokenCount': estimatedTokenCount,
  };
}

final class ProviderBenchmarkComparison {
  const ProviderBenchmarkComparison({
    required this.fakeMetrics,
    required this.openAiMetrics,
  });

  final ProviderBenchmarkMetrics fakeMetrics;
  final ProviderBenchmarkMetrics openAiMetrics;

  Map<String, Object?> toJson() => <String, Object?>{
    'fakeProvider': fakeMetrics.toJson(),
    'openAiProvider': openAiMetrics.toJson(),
  };
}

final class ProviderBenchmarkRunner {
  ProviderBenchmarkRunner({
    AnalysisTelemetrySink? telemetrySink,
  }) : _telemetry = telemetrySink ?? InMemoryAnalysisTelemetrySink();

  final AnalysisTelemetrySink _telemetry;

  AnalysisTelemetrySink get telemetry => _telemetry;

  Future<ProviderBenchmarkMetrics> evaluateProvider({
    required AnalysisProvider provider,
    required ProviderKind providerKind,
    required List<String> sampleInputs,
    AnalysisMode mode = AnalysisMode.reading,
  }) async {
    if (sampleInputs.isEmpty) {
      throw ArgumentError('sampleInputs must not be empty');
    }

    var successful = 0;
    var failed = 0;
    var cancelled = 0;
    var totalLatencyUs = 0;
    var totalSetupUs = 0;
    var totalReadUs = 0;
    var totalDecodeUs = 0;
    var totalEstimatedTokens = 0;

    for (final input in sampleInputs) {
      final requestId = RequestId.create();
      final cancellation = CancellationToken();
      final context = RequestContext(
        requestId: requestId,
        cancellation: cancellation,
      );
      final request = AnalysisRequest(
        requestId: requestId,
        input: input,
        mode: mode,
      );

      _telemetry.recordEvent(
        AnalysisTelemetryEvent(
          type: AnalysisTelemetryEventType.analysisRequestStarted,
          requestId: requestId,
          providerKind: providerKind,
          mode: mode,
        ),
      );

      final stopwatch = Stopwatch()..start();
      try {
        final result = await provider.analyzeFull(request, context);
        stopwatch.stop();

        successful++;
        totalLatencyUs += stopwatch.elapsedMicroseconds;

        // Estimate tokens: input runes + output JSON runes divided by ~4
        final jsonText = result.toJsonText();
        final estimatedTokens = ((input.runes.length + jsonText.runes.length) / 4).ceil();
        totalEstimatedTokens += estimatedTokens;

        _telemetry.recordEvent(
          AnalysisTelemetryEvent(
            type: AnalysisTelemetryEventType.providerCompleted,
            requestId: requestId,
            providerKind: providerKind,
            mode: mode,
            outcome: AnalysisTelemetryOutcome.success,
            duration: stopwatch.elapsed,
          ),
        );
        _telemetry.recordMetric(
          AnalysisMetricSample(
            name: AnalysisMetricName.totalLatencyMs,
            requestId: requestId,
            providerKind: providerKind,
            mode: mode,
            value: stopwatch.elapsed,
          ),
        );
      } on AnalysisProviderException catch (e) {
        stopwatch.stop();
        if (e.error.code == AnalysisErrorCode.requestCancelled) {
          cancelled++;
          _telemetry.recordEvent(
            AnalysisTelemetryEvent(
              type: AnalysisTelemetryEventType.analysisRequestCancelled,
              requestId: requestId,
              providerKind: providerKind,
              mode: mode,
              outcome: AnalysisTelemetryOutcome.cancelled,
              errorCode: e.error.code,
              duration: stopwatch.elapsed,
            ),
          );
        } else {
          failed++;
          _telemetry.recordEvent(
            AnalysisTelemetryEvent(
              type: AnalysisTelemetryEventType.analysisRequestFailed,
              requestId: requestId,
              providerKind: providerKind,
              mode: mode,
              outcome: AnalysisTelemetryOutcome.failure,
              errorCode: e.error.code,
              duration: stopwatch.elapsed,
            ),
          );
        }
      } catch (_) {
        stopwatch.stop();
        failed++;
      }
    }

    final total = sampleInputs.length;
    final avgLatency = total > 0 ? Duration(microseconds: totalLatencyUs ~/ total) : Duration.zero;
    final schemaAdherence = successful / total;
    final failRate = failed / total;
    final cancelSuccessRate = cancelled > 0 ? 1.0 : (total > 0 && failed == 0 ? 1.0 : 0.0);

    return ProviderBenchmarkMetrics(
      providerKind: providerKind,
      totalRequests: total,
      successfulRequests: successful,
      failedRequests: failed,
      cancelledRequests: cancelled,
      averageLatency: avgLatency,
      averageSetupLatency: Duration(microseconds: totalSetupUs ~/ (total == 0 ? 1 : total)),
      averageReadLatency: Duration(microseconds: totalReadUs ~/ (total == 0 ? 1 : total)),
      averageDecodeLatency: Duration(microseconds: totalDecodeUs ~/ (total == 0 ? 1 : total)),
      schemaAdherenceRate: schemaAdherence,
      failureRate: failRate,
      cancellationSuccessRate: cancelSuccessRate,
      estimatedTokenCount: totalEstimatedTokens,
    );
  }

  Future<ProviderBenchmarkComparison> compareProviders({
    required AnalysisProvider fakeProvider,
    required AnalysisProvider openAiProvider,
    required List<String> sampleInputs,
  }) async {
    final fakeMetrics = await evaluateProvider(
      provider: fakeProvider,
      providerKind: ProviderKind.fake,
      sampleInputs: sampleInputs,
    );

    final openAiMetrics = await evaluateProvider(
      provider: openAiProvider,
      providerKind: ProviderKind.openAiResponses,
      sampleInputs: sampleInputs,
    );

    return ProviderBenchmarkComparison(
      fakeMetrics: fakeMetrics,
      openAiMetrics: openAiMetrics,
    );
  }
}
