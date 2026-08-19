import 'dart:async';

import '../domain/analysis_models.dart';
import 'analysis_action_contracts.dart';
import 'analysis_action_controller.dart';
import 'analysis_execution_strategy.dart';
import 'analysis_mode_suggester.dart';
import 'analysis_state.dart';

final class AnalysisController {
  AnalysisController({
    required AnalysisProvider provider,
    AnalysisExecutionStrategy? strategy,
    AnalysisModeSuggester? modeSuggester,
    AnalysisActionPorts? actionPorts,
  }) : _provider = provider,
       _strategy = strategy ?? const FullOnlyStrategy(),
       _modeSuggester =
           modeSuggester ?? const DeterministicAnalysisModeSuggester(),
       _actions = actionPorts == null
           ? null
           : AnalysisActionController(ports: actionPorts);

  AnalysisProvider _provider;
  AnalysisExecutionStrategy _strategy;
  final AnalysisModeSuggester _modeSuggester;
  final AnalysisActionController? _actions;
  final StreamController<AnalysisSessionState> _states =
      StreamController<AnalysisSessionState>.broadcast();
  final StreamController<AnalysisModeSelectionState> _modeStates =
      StreamController<AnalysisModeSelectionState>.broadcast();

  AnalysisSessionState _state = const AnalysisIdle();
  RequestContext? _activeContext;
  String _lastInput = '';
  AnalysisMode _suggestedMode = AnalysisMode.reading;
  AnalysisMode? _manualMode;
  AnalysisMode _lastSubmittedMode = AnalysisMode.reading;
  String _draft = '';
  AnalysisPreview? _activePreview;
  AnalysisError? _activePreviewError;

  AnalysisSessionState get state => _state;
  Stream<AnalysisSessionState> get states => _states.stream;
  AnalysisModeSelectionState get modeState => AnalysisModeSelectionState(
    suggestedMode: _suggestedMode,
    effectiveMode: _manualMode ?? _suggestedMode,
    hasManualOverride: _manualMode != null,
  );
  Stream<AnalysisModeSelectionState> get modeStates => _modeStates.stream;
  AnalysisActionController? get actions => _actions;
  String get draft => _draft;

  void replaceRuntime({
    required AnalysisProvider provider,
    required AnalysisExecutionStrategy strategy,
  }) {
    _activeContext?.cancel();
    _activeContext = null;
    _activePreview = null;
    _activePreviewError = null;
    _actions?.reset();
    _provider = provider;
    _strategy = strategy;
    _emitMode();
  }

  void updateDraft(String input) {
    _draft = input;
    _suggestedMode = _modeSuggester.suggest(input.trim());
    _emitMode();
  }

  bool selectMode(AnalysisMode mode) {
    if (_activeContext != null) {
      return false;
    }
    _manualMode = mode;
    _emitMode();
    return true;
  }

  void useSuggestion() {
    if (_activeContext != null) {
      return;
    }
    _manualMode = null;
    _emitMode();
  }

  void submit(String input, {AnalysisMode? mode}) {
    final normalizedInput = input.trim();
    updateDraft(input);
    final submittedMode = mode ?? _manualMode ?? _suggestedMode;
    _actions?.reset();
    _activeContext?.cancel();
    _activeContext = null;
    _activePreview = null;
    _activePreviewError = null;
    _lastInput = normalizedInput;
    _lastSubmittedMode = submittedMode;

    final requestId = RequestId.create();
    late final AnalysisInput validatedInput;
    try {
      validatedInput = AnalysisInput.fromRaw(input);
    } on AnalysisInputException catch (exception) {
      _emit(
        AnalysisFailure(
          requestId: requestId,
          input: normalizedInput,
          mode: submittedMode,
          error: exception.error,
        ),
      );
      return;
    }

    final request = AnalysisRequest(
      requestId: requestId,
      input: validatedInput.value,
      mode: submittedMode,
    );
    final context = RequestContext(
      requestId: requestId,
      cancellation: CancellationToken(),
    );
    _activeContext = context;
    _emit(
      AnalysisLoading(
        requestId: requestId,
        input: normalizedInput,
        mode: submittedMode,
        stage: _strategy.initialStage(_provider),
      ),
    );
    unawaited(_run(request, context));
  }

  void cancel() {
    final context = _activeContext;
    if (context == null) {
      return;
    }
    final preview = _activePreview;
    final previewError = _activePreviewError;
    context.cancel();
    _activeContext = null;
    _activePreview = null;
    _activePreviewError = null;
    _actions?.reset();
    _emit(
      AnalysisCancelled(
        requestId: context.requestId,
        input: _lastInput,
        mode: _lastSubmittedMode,
        preview: preview,
        previewError: previewError,
      ),
    );
  }

  void retry() {
    if (_lastInput.isNotEmpty) {
      submit(_lastInput, mode: _lastSubmittedMode);
    }
  }

  Future<void> dispose() async {
    _activeContext?.cancel();
    _activeContext = null;
    await _actions?.dispose();
    await _states.close();
    await _modeStates.close();
  }

  Future<void> _run(AnalysisRequest request, RequestContext context) async {
    AnalysisPreview? preview;
    AnalysisError? previewError;
    try {
      final result = await _strategy.execute(
        _provider,
        request,
        context,
        onPreview: (nextPreview) {
          if (!_isCurrent(context)) {
            return;
          }
          preview = nextPreview;
          previewError = null;
          _activePreview = nextPreview;
          _activePreviewError = null;
          _emit(
            AnalysisPartial(
              requestId: request.requestId,
              input: request.input,
              mode: request.mode,
              preview: nextPreview,
            ),
          );
        },
        onPreviewFailure: (error) {
          if (!_isCurrent(context)) {
            return;
          }
          previewError = error;
          _activePreviewError = error;
          _emit(
            AnalysisLoading(
              requestId: request.requestId,
              input: request.input,
              mode: request.mode,
              stage: AnalysisLoadingStage.full,
              previewError: error,
            ),
          );
        },
      );
      if (!_isCurrent(context)) {
        return;
      }
      _activeContext = null;
      _activePreview = null;
      _activePreviewError = null;
      final success = AnalysisSuccess(
        requestId: request.requestId,
        input: request.input,
        mode: request.mode,
        result: result,
      );
      _actions?.setSuccess(success);
      _emit(success);
    } on AnalysisApplicationException catch (exception) {
      if (!_isCurrent(context)) {
        return;
      }
      _activeContext = null;
      _activePreview = null;
      _activePreviewError = null;
      final availablePreview = preview;
      if (exception.error.code == AnalysisErrorCode.requestCancelled) {
        _emit(
          AnalysisCancelled(
            requestId: request.requestId,
            input: request.input,
            mode: request.mode,
            preview: preview,
            previewError: previewError,
          ),
        );
      } else if (availablePreview != null) {
        _emit(
          AnalysisPartialFailure(
            requestId: request.requestId,
            input: request.input,
            mode: request.mode,
            preview: availablePreview,
            error: exception.error,
            previewError: previewError,
          ),
        );
      } else {
        _emit(
          AnalysisFailure(
            requestId: request.requestId,
            input: request.input,
            mode: request.mode,
            error: exception.error,
            previewError: previewError,
          ),
        );
      }
    } catch (_) {
      if (!_isCurrent(context)) {
        return;
      }
      _activeContext = null;
      _activePreview = null;
      _activePreviewError = null;
      final availablePreview = preview;
      if (availablePreview != null) {
        _emit(
          AnalysisPartialFailure(
            requestId: request.requestId,
            input: request.input,
            mode: request.mode,
            preview: availablePreview,
            error: const AnalysisError.unknownError(),
            previewError: previewError,
          ),
        );
        return;
      }
      _emit(
        AnalysisFailure(
          requestId: request.requestId,
          input: request.input,
          mode: request.mode,
          error: const AnalysisError.unknownError(),
          previewError: previewError,
        ),
      );
    }
  }

  bool _isCurrent(RequestContext context) => _activeContext == context;

  void _emitMode() {
    final nextState = modeState;
    if (!_modeStates.isClosed) {
      _modeStates.add(nextState);
    }
  }

  void _emit(AnalysisSessionState nextState) {
    _state = nextState;
    if (!_states.isClosed) {
      _states.add(nextState);
    }
  }
}
