import 'dart:async';

import '../domain/analysis_models.dart';

final class FakeAnalysisProvider
    implements AnalysisProvider, ProgressiveAnalysisProviderCapability {
  FakeAnalysisProvider({
    this.delay = const Duration(milliseconds: 350),
    this.shouldFail = false,
    this.previewDelay,
    this.previewShouldFail = false,
  });

  final Duration delay;
  final Duration? previewDelay;
  bool shouldFail;
  final bool previewShouldFail;

  @override
  Future<AnalysisPreview> analyzePreview(
    AnalysisRequest request,
    RequestContext context,
  ) async {
    context.cancellation.throwIfCancelled();
    await _waitForCompletion(context, previewDelay ?? delay);
    context.cancellation.throwIfCancelled();
    if (previewShouldFail) {
      throw const AnalysisProviderException(AnalysisError.providerFailed());
    }

    final primaryText = switch (request.mode) {
      AnalysisMode.reading => 'FAKE TRANSLATION PREVIEW: ${request.input}',
      AnalysisMode.expression => 'FAKE NATURAL PREVIEW: ${request.input}',
    };
    return AnalysisPreview(
      mode: request.mode,
      providerLabel: 'Fake Provider（deterministic development data）',
      primaryText: primaryText,
    );
  }

  @override
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  ) async {
    context.cancellation.throwIfCancelled();
    await _waitForCompletion(context, delay);
    context.cancellation.throwIfCancelled();
    if (shouldFail) {
      throw const AnalysisProviderException(AnalysisError.providerFailed());
    }

    return AnalysisResult(
      providerLabel: 'Fake Provider（deterministic development data）',
      reading: ReadingAnalysis(
        translation: 'FAKE TRANSLATION: ${request.input}',
        sentenceAnalysis: 'FAKE SENTENCE ANALYSIS: ${request.input}',
        grammar: 'FAKE GRAMMAR: ${request.input}',
        vocabulary: 'FAKE VOCABULARY: ${request.input}',
        nuance: 'FAKE NUANCE: ${request.input}',
      ),
      expression: ExpressionAnalysis(
        natural: 'FAKE NATURAL: ${request.input}',
        polite: 'FAKE POLITE: ${request.input}',
        formal: 'FAKE FORMAL: ${request.input}',
        context: 'FAKE CONTEXT: ${request.input}',
        tone: 'FAKE TONE: ${request.input}',
      ),
    );
  }

  Future<void> _waitForCompletion(RequestContext context, Duration wait) {
    if (wait == Duration.zero) {
      return Future<void>.value();
    }

    final completer = Completer<void>();
    Timer? timer;
    late void Function() onCancelled;

    void finish([Object? error]) {
      if (completer.isCompleted) {
        return;
      }
      context.cancellation.removeListener(onCancelled);
      timer?.cancel();
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(error);
      }
    }

    onCancelled = () {
      finish(const AnalysisProviderException(AnalysisError.requestCancelled()));
    };

    context.cancellation.addListener(onCancelled);
    if (!completer.isCompleted) {
      timer = Timer(wait, finish);
    }
    return completer.future;
  }
}
