import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/application/analysis_state.dart';
import 'package:lingolens/domain/analysis_models.dart';

void main() {
  test('known provider timeout maps to PROVIDER_TIMEOUT', () async {
    expect(
      await _failureFor(const AnalysisProviderException.timeout()),
      AnalysisErrorCode.providerTimeout,
    );
  });

  test('missing provider maps to PROVIDER_NOT_FOUND', () async {
    expect(
      await _failureFor(const AnalysisProviderException.notFound()),
      AnalysisErrorCode.providerNotFound,
    );
  });

  test('provider failure remains PROVIDER_FAILED', () async {
    expect(
      await _failureFor(const AnalysisProviderException.providerFailed()),
      AnalysisErrorCode.providerFailed,
    );
  });

  test('structured-output failure maps to INVALID_STRUCTURED_OUTPUT', () async {
    expect(
      await _failureFor(
        const AnalysisProviderException.invalidStructuredOutput(),
      ),
      AnalysisErrorCode.invalidStructuredOutput,
    );
  });

  test('unexpected exception maps to sanitized UNKNOWN_ERROR', () async {
    final failure = await _failureFor(StateError('raw provider secret'));

    expect(failure, AnalysisErrorCode.unknownError);
  });

  test('raw exception text does not reach visible failure state', () async {
    final controller = AnalysisController(
      provider: _ThrowingProvider(StateError('raw provider secret')),
    );
    addTearDown(controller.dispose);

    final failure = _statesOf<AnalysisFailure>(controller).first;
    controller.submit('valid input');
    final state = await failure;

    expect(state.error.code, AnalysisErrorCode.unknownError);
    expect(state.error.message, '分析失敗，請稍後重試。');
    expect(state.error.message, isNot(contains('raw provider secret')));
  });
}

Future<AnalysisErrorCode> _failureFor(Object error) async {
  final controller = AnalysisController(provider: _ThrowingProvider(error));
  addTearDown(controller.dispose);

  final failure = _statesOf<AnalysisFailure>(controller).first;
  controller.submit('valid input');
  return (await failure).error.code;
}

Stream<T> _statesOf<T extends AnalysisSessionState>(
  AnalysisController controller,
) => controller.states.where((state) => state is T).cast<T>();

final class _ThrowingProvider implements AnalysisProvider {
  const _ThrowingProvider(this.error);

  final Object error;

  @override
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  ) => Future<AnalysisResult>.error(error);
}
