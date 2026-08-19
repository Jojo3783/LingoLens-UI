import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/application/analysis_state.dart';
import 'package:lingolens/domain/analysis_models.dart';
import 'package:lingolens/infrastructure/fake_analysis_provider.dart';

void main() {
  test('Fake Provider success is deterministic and typed', () async {
    final provider = FakeAnalysisProvider(delay: Duration.zero);
    final controller = AnalysisController(provider: provider);
    addTearDown(controller.dispose);

    final resultFuture = _statesOf<AnalysisSuccess>(controller).first;
    controller.submit('synthetic input');
    final state = await resultFuture;

    expect(state.result.providerLabel, contains('Fake Provider'));
    expect(state.result.reading, isA<ReadingAnalysis>());
    expect(state.result.expression, isA<ExpressionAnalysis>());
    expect(
      state.result.reading.translation,
      'FAKE TRANSLATION: synthetic input',
    );
  });

  test('Fake Provider failure remains a typed failure', () async {
    final controller = AnalysisController(
      provider: FakeAnalysisProvider(delay: Duration.zero, shouldFail: true),
    );
    addTearDown(controller.dispose);

    final failureFuture = _statesOf<AnalysisFailure>(controller).first;
    controller.submit('synthetic failure');
    final state = await failureFuture;

    expect(state.error.code, AnalysisErrorCode.providerFailed);
    expect(state.error.message, isNot(contains('Exception')));
  });

  test('delayed Fake Provider observes cancellation', () async {
    final controller = AnalysisController(
      provider: FakeAnalysisProvider(delay: const Duration(seconds: 1)),
    );
    addTearDown(controller.dispose);

    final cancelledFuture = _statesOf<AnalysisCancelled>(controller).first;
    controller.submit('synthetic slow request');
    controller.cancel();
    final state = await cancelledFuture;

    expect(state.phase, AnalysisPhase.cancelled);
    expect(controller.state, isA<AnalysisCancelled>());
  });

  test('user cancellation remains cancelled after a late success', () async {
    final provider = _ControlledProvider();
    final controller = AnalysisController(provider: provider);
    addTearDown(controller.dispose);

    final cancelledFuture = _statesOf<AnalysisCancelled>(controller).first;
    controller.submit('synthetic cancelled request');
    controller.cancel();
    provider.complete('synthetic cancelled request');

    final state = await cancelledFuture;
    await Future<void>.delayed(Duration.zero);

    expect(state.phase, AnalysisPhase.cancelled);
    expect(controller.state, isA<AnalysisCancelled>());
  });

  test(
    'latest request wins and stale result cannot overwrite current state',
    () async {
      final provider = _ControlledProvider();
      final controller = AnalysisController(provider: provider);
      addTearDown(controller.dispose);

      final successFuture = _statesOf<AnalysisSuccess>(controller).first;
      controller.submit('old');
      controller.submit('new');
      provider.complete('old');
      provider.complete('new');
      final state = await successFuture;

      expect(state.result.reading.translation, 'new');
      expect(state.requestId, isNot(provider.requestIds['old']));
    },
  );

  test('stale failure cannot overwrite a newer successful request', () async {
    final provider = _ControlledProvider();
    final controller = AnalysisController(provider: provider);
    addTearDown(controller.dispose);

    final successFuture = _statesOf<AnalysisSuccess>(controller).first;
    controller.submit('synthetic old failure');
    controller.submit('synthetic new success');
    provider.fail('synthetic old failure');
    provider.complete('synthetic new success');

    final state = await successFuture;

    expect(state.result.reading.translation, 'synthetic new success');
    expect(controller.state, isA<AnalysisSuccess>());
  });

  test(
    'unexpected provider exception becomes sanitized unknown error',
    () async {
      final provider = _ControlledProvider();
      final controller = AnalysisController(provider: provider);
      addTearDown(controller.dispose);

      final failureFuture = _statesOf<AnalysisFailure>(controller).first;
      controller.submit('synthetic unexpected error');
      provider.failUnexpectedly('synthetic unexpected error');

      final state = await failureFuture;

      expect(state.error.code, AnalysisErrorCode.unknownError);
      expect(state.error.message, '分析失敗，請稍後重試。');
      expect(state.error.message, isNot(contains('synthetic')));
    },
  );

  test('retry creates a new RequestId', () async {
    final controller = AnalysisController(
      provider: FakeAnalysisProvider(delay: Duration.zero),
    );
    addTearDown(controller.dispose);

    final firstFuture = _statesOf<AnalysisSuccess>(controller).first;
    controller.submit('retry input');
    final first = await firstFuture;

    final secondFuture = _statesOf<AnalysisSuccess>(controller).first;
    controller.retry();
    final second = await secondFuture;

    expect(second.requestId, isNot(first.requestId));
  });

  test('empty input becomes typed failure without calling provider', () async {
    final provider = _CountingProvider();
    final controller = AnalysisController(provider: provider);
    addTearDown(controller.dispose);

    final failureFuture = _statesOf<AnalysisFailure>(controller).first;
    controller.submit('   ');
    final state = await failureFuture;

    expect(state.error.code, AnalysisErrorCode.emptyInput);
    expect(provider.callCount, 0);
  });

  test('disposing the controller suppresses a late fake completion', () async {
    final provider = _ControlledProvider();
    final controller = AnalysisController(provider: provider);

    controller.submit('synthetic disposed request');
    expect(controller.state, isA<AnalysisLoading>());
    await controller.dispose();
    provider.complete('synthetic disposed request');
    await Future<void>.delayed(Duration.zero);

    expect(controller.state, isA<AnalysisLoading>());
  });
}

Stream<T> _statesOf<T extends AnalysisSessionState>(
  AnalysisController controller,
) {
  return controller.states.where((state) => state is T).cast<T>();
}

final class _ControlledProvider implements AnalysisProvider {
  final Map<String, Completer<AnalysisResult>> _completers = {};
  final Map<String, RequestId> requestIds = {};
  int callCount = 0;

  @override
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  ) {
    callCount++;
    requestIds[request.input] = request.requestId;
    final completer = Completer<AnalysisResult>();
    _completers[request.input] = completer;
    return completer.future;
  }

  void complete(String input) {
    _completers[input]!.complete(
      AnalysisResult(
        providerLabel: 'Controlled Fake Provider',
        reading: ReadingAnalysis(
          translation: input,
          sentenceAnalysis: 'synthetic sentence',
          grammar: 'synthetic grammar',
          vocabulary: 'synthetic vocabulary',
          nuance: 'synthetic nuance',
        ),
        expression: ExpressionAnalysis(
          natural: input,
          polite: input,
          formal: input,
          context: input,
          tone: input,
        ),
      ),
    );
  }

  void fail(String input) {
    _completers[input]!.completeError(
      const AnalysisProviderException(AnalysisError.providerFailed()),
    );
  }

  void failUnexpectedly(String input) {
    _completers[input]!.completeError(StateError('synthetic provider error'));
  }
}

final class _CountingProvider implements AnalysisProvider {
  int callCount = 0;

  @override
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  ) {
    callCount++;
    throw StateError('provider must not be called for empty input');
  }
}
