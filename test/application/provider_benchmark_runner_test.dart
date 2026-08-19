import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/provider_benchmark_runner.dart';
import 'package:lingolens/domain/provider_contracts.dart';
import 'package:lingolens/infrastructure/fake_analysis_provider.dart';

void main() {
  group('ProviderBenchmarkRunner tests', () {
    late ProviderBenchmarkRunner runner;
    late FakeAnalysisProvider fakeProvider;

    setUp(() {
      runner = ProviderBenchmarkRunner();
      fakeProvider = FakeAnalysisProvider(
        delay: const Duration(milliseconds: 10),
      );
    });

    test('evaluates successful provider benchmark metrics', () async {
      final sampleInputs = ['Hello world', 'How are you?', 'Good morning'];
      final metrics = await runner.evaluateProvider(
        provider: fakeProvider,
        providerKind: ProviderKind.fake,
        sampleInputs: sampleInputs,
      );

      expect(metrics.providerKind, ProviderKind.fake);
      expect(metrics.totalRequests, 3);
      expect(metrics.successfulRequests, 3);
      expect(metrics.failedRequests, 0);
      expect(metrics.schemaAdherenceRate, 1.0);
      expect(metrics.failureRate, 0.0);
      expect(metrics.estimatedTokenCount, greaterThan(0));

      final jsonMap = metrics.toJson();
      expect(jsonMap['providerKind'], 'fake');
      expect(jsonMap['totalRequests'], 3);
      expect(jsonMap['schemaAdherenceRate'], 1.0);
    });

    test('evaluates failure provider benchmark metrics when provider fails', (
    ) async {
      fakeProvider.shouldFail = true;
      final sampleInputs = ['Failure test input'];
      final metrics = await runner.evaluateProvider(
        provider: fakeProvider,
        providerKind: ProviderKind.fake,
        sampleInputs: sampleInputs,
      );

      expect(metrics.totalRequests, 1);
      expect(metrics.successfulRequests, 0);
      expect(metrics.failedRequests, 1);
      expect(metrics.schemaAdherenceRate, 0.0);
      expect(metrics.failureRate, 1.0);
    });

    test('compares Fake Provider and OpenAI Provider benchmarks', () async {
      final failingProvider = FakeAnalysisProvider(
        delay: const Duration(milliseconds: 5),
        shouldFail: true,
      );
      final sampleInputs = ['Sample text for comparative analysis'];

      final comparison = await runner.compareProviders(
        fakeProvider: fakeProvider,
        openAiProvider: failingProvider,
        sampleInputs: sampleInputs,
      );

      expect(comparison.fakeMetrics.successfulRequests, 1);
      expect(comparison.openAiMetrics.failedRequests, 1);

      final jsonMap = comparison.toJson();
      expect(jsonMap, contains('fakeProvider'));
      expect(jsonMap, contains('openAiProvider'));
    });

    test('throws ArgumentError when sampleInputs is empty', () async {
      expect(
        () => runner.evaluateProvider(
          provider: fakeProvider,
          providerKind: ProviderKind.fake,
          sampleInputs: [],
        ),
        throwsArgumentError,
      );
    });
  });
}
