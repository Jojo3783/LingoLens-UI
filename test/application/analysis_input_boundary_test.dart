import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/application/analysis_state.dart';
import 'package:lingolens/domain/analysis_models.dart';

void main() {
  test('empty input is rejected before provider invocation', () async {
    final provider = _CountingProvider();
    final controller = AnalysisController(provider: provider);
    addTearDown(controller.dispose);

    final failure = _failures(controller).first;
    controller.submit('');
    final state = await failure;

    expect(state.error.code, AnalysisErrorCode.emptyInput);
    expect(provider.callCount, 0);
  });

  test('whitespace-only input is rejected after trimming', () async {
    final provider = _CountingProvider();
    final controller = AnalysisController(provider: provider);
    addTearDown(controller.dispose);

    final failure = _failures(controller).first;
    controller.submit('  \t\n  ');
    final state = await failure;

    expect(state.error.code, AnalysisErrorCode.emptyInput);
    expect(state.input, isEmpty);
    expect(provider.callCount, 0);
  });

  test('one-character input is accepted after normalization', () async {
    final provider = _CountingProvider();
    final controller = AnalysisController(provider: provider);
    addTearDown(controller.dispose);

    final loading = _statesOf<AnalysisLoading>(controller).first;
    controller.submit(' x ');
    final state = await loading;

    expect(state.input, 'x');
    expect(provider.callCount, 1);
  });

  test('exactly 2,000 Unicode scalar values are accepted', () async {
    final provider = _CountingProvider();
    final controller = AnalysisController(provider: provider);
    addTearDown(controller.dispose);

    final loading = _statesOf<AnalysisLoading>(controller).first;
    controller.submit(
      List<String>.filled(maxAnalysisInputCharacters, 'a').join(),
    );
    final state = await loading;

    expect(state.input.runes.length, maxAnalysisInputCharacters);
    expect(provider.callCount, 1);
  });

  test(
    '2,001 Unicode scalar values are rejected before provider invocation',
    () async {
      final provider = _CountingProvider();
      final controller = AnalysisController(provider: provider);
      addTearDown(controller.dispose);

      final failure = _failures(controller).first;
      controller.submit(
        List<String>.filled(maxAnalysisInputCharacters + 1, 'a').join(),
      );
      final state = await failure;

      expect(state.error.code, AnalysisErrorCode.inputTooLong);
      expect(provider.callCount, 0);
    },
  );

  test('supplementary-plane emoji count as one Unicode scalar value', () async {
    final provider = _CountingProvider();
    final controller = AnalysisController(provider: provider);
    addTearDown(controller.dispose);

    final loading = _statesOf<AnalysisLoading>(controller).first;
    final input = List<String>.filled(maxAnalysisInputCharacters, '🙂').join();
    controller.submit(input);
    final state = await loading;

    expect(input.runes.length, maxAnalysisInputCharacters);
    expect(state.input, input);
    expect(provider.callCount, 1);
  });
}

Stream<AnalysisFailure> _failures(AnalysisController controller) =>
    _statesOf<AnalysisFailure>(controller);

Stream<T> _statesOf<T extends AnalysisSessionState>(
  AnalysisController controller,
) => controller.states.where((state) => state is T).cast<T>();

final class _CountingProvider implements AnalysisProvider {
  int callCount = 0;

  @override
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  ) async {
    callCount++;
    return const AnalysisResult(
      providerLabel: 'Provider',
      reading: ReadingAnalysis(
        translation: 'Translation',
        sentenceAnalysis: 'Sentence analysis',
        grammar: 'Grammar',
        vocabulary: 'Vocabulary',
        nuance: 'Nuance',
      ),
      expression: ExpressionAnalysis(
        natural: 'Natural',
        polite: 'Polite',
        formal: 'Formal',
        context: 'Context',
        tone: 'Tone',
      ),
    );
  }
}
