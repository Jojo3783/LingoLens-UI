import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/application/analysis_execution_strategy.dart';
import 'package:lingolens/application/analysis_state.dart';
import 'package:lingolens/domain/analysis_models.dart';

void main() {
  group('T-10 late completion closure', () {
    test('late Preview success after request B cannot overwrite B', () async {
      final provider = _ControlledProgressiveProvider();
      final controller = AnalysisController(
        provider: provider,
        strategy: const TwoStageStrategy(),
      );

      controller.submit('A');
      await pumpEventQueue();
      controller.submit('B');
      await pumpEventQueue();
      provider.completePreview('B');
      await pumpEventQueue();
      provider.completeFull('B');
      await pumpEventQueue(times: 3);
      provider.completePreview('A');
      await pumpEventQueue(times: 3);

      expect(controller.state, isA<AnalysisSuccess>());
      expect((controller.state as AnalysisSuccess).input, 'B');
      expect(provider.previewCalls, 2);
      expect(provider.fullCalls, 1);
      await controller.dispose();
    });

    test('late Preview failure after request B cannot overwrite B', () async {
      final provider = _ControlledProgressiveProvider();
      final controller = AnalysisController(
        provider: provider,
        strategy: const TwoStageStrategy(),
      );

      controller.submit('A');
      await pumpEventQueue();
      controller.submit('B');
      await pumpEventQueue();
      provider.completePreview('B');
      await pumpEventQueue();
      provider.completeFull('B');
      await pumpEventQueue(times: 3);
      provider.failPreview('A');
      await pumpEventQueue(times: 3);

      expect(controller.state, isA<AnalysisSuccess>());
      expect((controller.state as AnalysisSuccess).input, 'B');
      expect(provider.previewCalls, 2);
      expect(provider.fullCalls, 1);
      await controller.dispose();
    });

    test('late Full success after request B cannot overwrite B', () async {
      final provider = _ControlledProgressiveProvider();
      final controller = AnalysisController(
        provider: provider,
        strategy: const TwoStageStrategy(),
      );

      controller.submit('A');
      await pumpEventQueue();
      provider.completePreview('A');
      await pumpEventQueue(times: 2);
      controller.submit('B');
      await pumpEventQueue();
      provider.completePreview('B');
      await pumpEventQueue();
      provider.completeFull('B');
      await pumpEventQueue(times: 3);
      provider.completeFull('A');
      await pumpEventQueue(times: 3);

      expect(controller.state, isA<AnalysisSuccess>());
      expect((controller.state as AnalysisSuccess).input, 'B');
      expect(provider.previewCalls, 2);
      expect(provider.fullCalls, 2);
      await controller.dispose();
    });
  });
}

final class _ControlledProgressiveProvider
    implements AnalysisProvider, ProgressiveAnalysisProviderCapability {
  final Map<String, Completer<AnalysisPreview>> _previews =
      <String, Completer<AnalysisPreview>>{};
  final Map<String, Completer<AnalysisResult>> _full =
      <String, Completer<AnalysisResult>>{};
  int previewCalls = 0;
  int fullCalls = 0;

  @override
  Future<AnalysisPreview> analyzePreview(
    AnalysisRequest request,
    RequestContext context,
  ) {
    previewCalls++;
    final completer = Completer<AnalysisPreview>();
    _previews[request.input] = completer;
    return completer.future;
  }

  @override
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  ) {
    fullCalls++;
    final completer = Completer<AnalysisResult>();
    _full[request.input] = completer;
    return completer.future;
  }

  void completePreview(String input) {
    _previews[input]!.complete(
      AnalysisPreview(
        mode: AnalysisMode.reading,
        providerLabel: 'controlled',
        primaryText: 'preview $input',
      ),
    );
  }

  void failPreview(String input) {
    _previews[input]!.completeError(
      const AnalysisProviderException.providerFailed(),
    );
  }

  void completeFull(String input) {
    _full[input]!.complete(_result(input));
  }
}

AnalysisResult _result(String input) => AnalysisResult(
  providerLabel: 'controlled',
  reading: ReadingAnalysis(
    translation: 'translation $input',
    sentenceAnalysis: 'sentence',
    grammar: 'grammar',
    vocabulary: 'vocabulary',
    nuance: 'nuance',
  ),
  expression: ExpressionAnalysis(
    natural: 'natural',
    polite: 'polite',
    formal: 'formal',
    context: 'context',
    tone: 'tone',
  ),
);
