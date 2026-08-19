import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/application/analysis_execution_strategy.dart';
import 'package:lingolens/application/analysis_state.dart';
import 'package:lingolens/domain/analysis_models.dart';

void main() {
  test('two-stage strategy emits preview before full success', () async {
    final provider = _ProgressiveProvider();
    final controller = AnalysisController(
      provider: provider,
      strategy: const TwoStageStrategy(),
    );
    addTearDown(controller.dispose);

    final states = <AnalysisSessionState>[];
    final subscription = controller.states.listen(states.add);
    addTearDown(subscription.cancel);

    controller.submit('preview first');
    provider.completePreview('preview first');
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, isA<AnalysisPartial>());
    expect(
      (controller.state as AnalysisPartial).preview.primaryText,
      'preview first',
    );

    provider.completeFull();
    await _eventually(() => controller.state is AnalysisSuccess);

    expect(states.whereType<AnalysisLoading>(), hasLength(1));
    expect(states.whereType<AnalysisPartial>(), hasLength(1));
    expect(controller.state, isA<AnalysisSuccess>());
  });

  test('full-only strategy never calls optional preview capability', () async {
    final provider = _ProgressiveProvider();
    final controller = AnalysisController(provider: provider);
    addTearDown(controller.dispose);

    controller.submit('full only');
    expect(controller.state, isA<AnalysisLoading>());
    expect(
      (controller.state as AnalysisLoading).stage,
      AnalysisLoadingStage.full,
    );
    provider.completeFull();
    await _eventually(() => controller.state is AnalysisSuccess);

    expect(provider.previewCalls, 0);
    expect(provider.fullCalls, 1);
  });

  test('preview failure is typed and full success remains usable', () async {
    final provider = _ProgressiveProvider(
      previewError: const AnalysisError.providerFailed(),
    );
    final controller = AnalysisController(
      provider: provider,
      strategy: const TwoStageStrategy(),
    );
    addTearDown(controller.dispose);

    controller.submit('preview failure');
    provider.failPreview();
    await _eventually(
      () =>
          controller.state is AnalysisLoading &&
          (controller.state as AnalysisLoading).previewError != null,
    );
    expect(
      (controller.state as AnalysisLoading).previewError!.code,
      AnalysisErrorCode.providerFailed,
    );

    provider.completeFull();
    await _eventually(() => controller.state is AnalysisSuccess);
  });

  test(
    'full failure after preview preserves partial result and typed error',
    () async {
      final provider = _ProgressiveProvider();
      final controller = AnalysisController(
        provider: provider,
        strategy: const TwoStageStrategy(),
      );
      addTearDown(controller.dispose);

      controller.submit('full failure');
      provider.completePreview('full failure');
      await _eventually(() => controller.state is AnalysisPartial);
      provider.failFull();
      await _eventually(() => controller.state is AnalysisPartialFailure);

      final state = controller.state as AnalysisPartialFailure;
      expect(state.preview.primaryText, 'full failure');
      expect(state.error.code, AnalysisErrorCode.providerFailed);
    },
  );

  test(
    'cancel during preview and full preserves cancellation boundary',
    () async {
      final provider = _ProgressiveProvider();
      final controller = AnalysisController(
        provider: provider,
        strategy: const TwoStageStrategy(),
      );
      addTearDown(controller.dispose);

      controller.submit('cancel preview');
      controller.cancel();
      expect(controller.state, isA<AnalysisCancelled>());
      provider.completePreview('cancel preview');
      await Future<void>.delayed(Duration.zero);
      expect(controller.state, isA<AnalysisCancelled>());

      controller.submit('cancel full');
      provider.completePreview('cancel full', 1);
      await _eventually(() => controller.state is AnalysisPartial);
      controller.cancel();
      provider.completeFull('cancel full');
      await Future<void>.delayed(Duration.zero);
      expect(controller.state, isA<AnalysisCancelled>());
      expect((controller.state as AnalysisCancelled).preview, isNotNull);
    },
  );

  test('new request supersedes stale preview and full completions', () async {
    final provider = _ProgressiveProvider();
    final controller = AnalysisController(
      provider: provider,
      strategy: const TwoStageStrategy(),
    );
    addTearDown(controller.dispose);

    controller.submit('A');
    provider.completePreview('A');
    await _eventually(() => controller.state is AnalysisPartial);
    controller.submit('B');
    provider.failFull('A');
    provider.completePreview('B', 1);
    await _eventually(() => controller.state is AnalysisPartial);
    provider.completeFull('B');
    await _eventually(() => controller.state is AnalysisSuccess);

    final state = controller.state as AnalysisSuccess;
    expect(state.input, 'B');
    expect(state.result.reading.translation, 'B');
  });

  test('retry creates a new request context after partial failure', () async {
    final provider = _ProgressiveProvider();
    final controller = AnalysisController(
      provider: provider,
      strategy: const TwoStageStrategy(),
    );
    addTearDown(controller.dispose);

    controller.submit('retry');
    provider.completePreview('retry');
    await _eventually(() => controller.state is AnalysisPartial);
    provider.failFull();
    await _eventually(() => controller.state is AnalysisPartialFailure);
    final firstRequest = (controller.state as AnalysisPartialFailure).requestId;

    controller.retry();
    final secondRequest = (controller.state as AnalysisLoading).requestId;
    expect(secondRequest, isNot(firstRequest));
    provider.completePreview('retry', 1);
    await _eventually(() => controller.state is AnalysisPartial);
    provider.completeFull(null, 1);
    await _eventually(() => controller.state is AnalysisSuccess);
  });

  test(
    'dispose cancels in-flight work without emitting post-dispose state',
    () async {
      final provider = _ProgressiveProvider();
      final controller = AnalysisController(
        provider: provider,
        strategy: const TwoStageStrategy(),
      );
      controller.submit('dispose');
      await controller.dispose();
      provider.completePreview();
      await Future<void>.delayed(Duration.zero);

      expect(controller.state, isA<AnalysisLoading>());
    },
  );
}

Future<void> _eventually(bool Function() condition) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
  fail('condition was not met');
}

final class _ProgressiveProvider
    implements AnalysisProvider, ProgressiveAnalysisProviderCapability {
  _ProgressiveProvider({this.previewError});

  final AnalysisError? previewError;
  final Map<int, Completer<AnalysisPreview>> _previews = {};
  final Map<int, Completer<AnalysisResult>> _fullResults = {};
  final Map<int, String> _previewInputs = {};
  final Map<int, String> _fullInputs = {};
  int previewCalls = 0;
  int fullCalls = 0;

  @override
  Future<AnalysisPreview> analyzePreview(
    AnalysisRequest request,
    RequestContext context,
  ) {
    previewCalls++;
    _previewInputs[previewCalls - 1] = request.input;
    final completer = Completer<AnalysisPreview>();
    _previews[previewCalls - 1] = completer;
    return completer.future;
  }

  @override
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  ) {
    fullCalls++;
    _fullInputs[fullCalls - 1] = request.input;
    final completer = Completer<AnalysisResult>();
    _fullResults[fullCalls - 1] = completer;
    return completer.future;
  }

  void completePreview([String? input, int requestIndex = 0]) {
    final value = input ?? _previewInputs[requestIndex]!;
    _previews[requestIndex]!.complete(
      AnalysisPreview(
        mode: AnalysisMode.reading,
        providerLabel: 'Test Preview Provider',
        primaryText: value,
      ),
    );
  }

  void failPreview() {
    _previews[0]!.completeError(
      AnalysisProviderException(
        previewError ?? const AnalysisError.providerFailed(),
      ),
    );
  }

  void completeFull([String? input, int requestIndex = 0]) {
    final index = input == null
        ? requestIndex
        : _fullInputs.entries.firstWhere((entry) => entry.value == input).key;
    _fullResults[index]!.complete(_result(input ?? _fullInputs[index]!));
  }

  void failFull([String? input]) {
    final index = input == null
        ? 0
        : _fullInputs.entries.firstWhere((entry) => entry.value == input).key;
    _fullResults[index]!.completeError(
      const AnalysisProviderException(AnalysisError.providerFailed()),
    );
  }
}

AnalysisResult _result(String input) => AnalysisResult(
  providerLabel: 'Test Full Provider',
  reading: ReadingAnalysis(
    translation: input,
    sentenceAnalysis: 'sentence',
    grammar: 'grammar',
    vocabulary: 'vocabulary',
    nuance: 'nuance',
  ),
  expression: ExpressionAnalysis(
    natural: input,
    polite: 'polite',
    formal: 'formal',
    context: 'context',
    tone: 'tone',
  ),
);
