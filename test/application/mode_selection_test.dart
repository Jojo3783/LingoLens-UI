import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/application/analysis_mode_suggester.dart';
import 'package:lingolens/application/analysis_state.dart';
import 'package:lingolens/domain/analysis_models.dart';

void main() {
  test('deterministic suggestion distinguishes CJK from Latin input', () {
    const suggester = DeterministicAnalysisModeSuggester();

    expect(suggester.suggest('hello world'), AnalysisMode.reading);
    expect(suggester.suggest('這是一段中文'), AnalysisMode.expression);
  });

  test('suggestion and manual override remain Application-owned', () async {
    final provider = _CapturingProvider();
    final controller = AnalysisController(
      provider: provider,
      modeSuggester: const _ExpressionSuggester(),
    );
    addTearDown(controller.dispose);

    controller.updateDraft('hello');
    expect(controller.draft, 'hello');
    expect(controller.modeState.suggestedMode, AnalysisMode.expression);
    expect(controller.modeState.effectiveMode, AnalysisMode.expression);

    expect(controller.selectMode(AnalysisMode.reading), isTrue);
    expect(controller.modeState.hasManualOverride, isTrue);
    expect(controller.modeState.effectiveMode, AnalysisMode.reading);

    controller.updateDraft('changed draft');
    expect(controller.modeState.effectiveMode, AnalysisMode.reading);

    controller.useSuggestion();
    expect(controller.modeState.hasManualOverride, isFalse);
    expect(controller.modeState.effectiveMode, AnalysisMode.expression);

    controller.submit('submitted');
    final success = await _statesOf<AnalysisSuccess>(controller).first;
    expect(provider.requests.single.mode, AnalysisMode.expression);
    expect(success.input, 'submitted');
    expect(success.mode, AnalysisMode.expression);
  });

  test('submit mode and retry preserve immutable mode snapshots', () async {
    final provider = _CapturingProvider();
    final controller = AnalysisController(provider: provider);
    addTearDown(controller.dispose);

    controller.submit('reading', mode: AnalysisMode.reading);
    final first = await _statesOf<AnalysisSuccess>(controller).first;
    controller.selectMode(AnalysisMode.expression);
    controller.retry();
    final second = await _statesOf<AnalysisSuccess>(controller).first;

    expect(first.mode, AnalysisMode.reading);
    expect(first.input, 'reading');
    expect(second.mode, AnalysisMode.reading);
    expect(provider.requests.map((request) => request.mode), [
      AnalysisMode.reading,
      AnalysisMode.reading,
    ]);
    expect(second.requestId, isNot(first.requestId));
  });

  test('mode selection is disabled while a request is loading', () {
    final provider = _ControlledProvider();
    final controller = AnalysisController(provider: provider);
    addTearDown(controller.dispose);

    controller.submit('loading');
    expect(controller.selectMode(AnalysisMode.expression), isFalse);
    expect(controller.modeState.effectiveMode, AnalysisMode.reading);
    controller.cancel();
  });
}

Stream<T> _statesOf<T extends AnalysisSessionState>(
  AnalysisController controller,
) => controller.states.where((state) => state is T).cast<T>();

final class _ExpressionSuggester implements AnalysisModeSuggester {
  const _ExpressionSuggester();

  @override
  AnalysisMode suggest(String normalizedInput) => AnalysisMode.expression;
}

final class _CapturingProvider implements AnalysisProvider {
  final requests = <AnalysisRequest>[];

  @override
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  ) async {
    requests.add(request);
    return _result(request.input);
  }
}

final class _ControlledProvider implements AnalysisProvider {
  final _completers = <String, Completer<AnalysisResult>>{};

  @override
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  ) {
    final completer = Completer<AnalysisResult>();
    _completers[request.input] = completer;
    return completer.future;
  }
}

AnalysisResult _result(String input) => AnalysisResult(
  providerLabel: 'test',
  reading: ReadingAnalysis(
    translation: 'reading-$input',
    sentenceAnalysis: 'sentence-$input',
    grammar: 'grammar-$input',
    vocabulary: 'vocabulary-$input',
    nuance: 'nuance-$input',
  ),
  expression: ExpressionAnalysis(
    natural: 'natural-$input',
    polite: 'polite-$input',
    formal: 'formal-$input',
    context: 'context-$input',
    tone: 'tone-$input',
  ),
);
