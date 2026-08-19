import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/domain/analysis_models.dart';
import 'package:lingolens/infrastructure/fake_analysis_provider.dart';

void main() {
  test(
    'Fake Provider emits deterministic, distinct Reading and Expression v3 fields',
    () async {
      final provider = FakeAnalysisProvider(delay: Duration.zero);
      final firstRequest = _request('hello');
      final secondRequest = _request('hello');

      final first = await provider.analyzeFull(
        firstRequest,
        _context(firstRequest),
      );
      final second = await provider.analyzeFull(
        secondRequest,
        _context(secondRequest),
      );

      expect(first.schemaVersion, 3);
      expect(first.toJsonText(), second.toJsonText());
      expect(first.providerLabel, contains('Fake Provider'));
      expect(first.reading.translation, 'FAKE TRANSLATION: hello');
      expect(first.reading.sentenceAnalysis, 'FAKE SENTENCE ANALYSIS: hello');
      expect(first.reading.grammar, 'FAKE GRAMMAR: hello');
      expect(first.reading.vocabulary, 'FAKE VOCABULARY: hello');
      expect(first.reading.nuance, 'FAKE NUANCE: hello');
      expect({
        first.reading.translation,
        first.reading.sentenceAnalysis,
        first.reading.grammar,
        first.reading.vocabulary,
        first.reading.nuance,
      }, hasLength(5));
      expect(first.expression.natural, 'FAKE NATURAL: hello');
      expect(first.expression.polite, 'FAKE POLITE: hello');
      expect(first.expression.formal, 'FAKE FORMAL: hello');
      expect(first.expression.context, 'FAKE CONTEXT: hello');
      expect(first.expression.tone, 'FAKE TONE: hello');
      expect({
        first.expression.natural,
        first.expression.polite,
        first.expression.formal,
        first.expression.context,
        first.expression.tone,
      }, hasLength(5));
    },
  );
}

AnalysisRequest _request(String input) => AnalysisRequest(
  requestId: RequestId.create(),
  input: input,
  mode: AnalysisMode.reading,
);

RequestContext _context(AnalysisRequest request) => RequestContext(
  requestId: request.requestId,
  cancellation: CancellationToken(),
);
