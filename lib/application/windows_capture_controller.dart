import 'dart:async';

import '../domain/analysis_models.dart';
import 'windows_platform_contracts.dart';

final class WindowsCaptureController {
  WindowsCaptureController({
    required GlobalHotkeyService hotkey,
    required SelectedTextService selectedText,
    required FloatingWindowService floatingWindow,
    required WindowActivationService activation,
    Duration captureTimeout = windowsCaptureTimeout,
  }) : _hotkey = hotkey,
       _selectedText = selectedText,
       _floatingWindow = floatingWindow,
       _activation = activation,
       _captureTimeout = captureTimeout;

  final GlobalHotkeyService _hotkey;
  final SelectedTextService _selectedText;
  final FloatingWindowService _floatingWindow;
  final WindowActivationService _activation;
  final Duration _captureTimeout;
  final StreamController<WindowsCaptureState> _states =
      StreamController<WindowsCaptureState>.broadcast();

  StreamSubscription<void>? _hotkeySubscription;
  WindowsCaptureState _state = const WindowsCaptureState.idle();
  int _captureGeneration = 0;
  bool _disposed = false;

  WindowsCaptureState get state => _state;
  Stream<WindowsCaptureState> get states => _states.stream;

  Future<void> initialize() async {
    if (_disposed) {
      return;
    }
    _hotkeySubscription ??= _hotkey.activations.listen((_) {
      triggerCapture();
    });
    final registration = await _hotkey.initialize();
    if (_disposed) {
      return;
    }
    switch (registration) {
      case HotkeyRegistrationSuccess():
        _emit(const WindowsCaptureState.ready());
      case HotkeyRegistrationFailure(:final code):
        _emit(WindowsCaptureState.hotkeyUnavailable(code));
    }
  }

  void triggerCapture() {
    if (_disposed) {
      return;
    }
    final generation = ++_captureGeneration;
    unawaited(_selectedText.cancel());
    _emit(const WindowsCaptureState.capturing());
    unawaited(_capture(generation));
  }

  Future<void> dismissPanel() async {
    if (_disposed) {
      return;
    }
    await _floatingWindow.hidePanel();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    ++_captureGeneration;
    await _selectedText.cancel();
    await _hotkeySubscription?.cancel();
    _hotkeySubscription = null;
    await _hotkey.dispose();
    await _states.close();
  }

  Future<void> _capture(int generation) async {
    final outcome = await _selectedText.capture(timeout: _captureTimeout);
    if (!_isCurrent(generation)) {
      return;
    }
    switch (outcome) {
      case SelectedTextCaptureFailure(:final code):
        _emit(WindowsCaptureState.failed(code));
        return;
      case SelectedTextCaptureSuccess(:final text):
        final normalized = text.trim();
        if (normalized.isEmpty) {
          _emit(
            const WindowsCaptureState.failed(
              WindowsCaptureFailureCode.emptyCapturedText,
            ),
          );
          return;
        }
        try {
          final validated = AnalysisInput.fromRaw(text);
          final normalizedText = validated.value;
          final shown = await _floatingWindow.showPanel();
          if (!_isCurrent(generation)) {
            return;
          }
          switch (shown) {
            case WindowOperationFailure(:final code):
              _emit(
                WindowsCaptureState.failed(code, capturedText: normalizedText),
              );
              return;
            case WindowOperationSuccess():
              break;
          }

          final activated = await _activation.activate();
          if (!_isCurrent(generation)) {
            return;
          }
          switch (activated) {
            case WindowOperationFailure(:final code):
              _emit(
                WindowsCaptureState.failed(code, capturedText: normalizedText),
              );
              return;
            case WindowOperationSuccess():
              _emit(WindowsCaptureState.captured(normalizedText));
          }
          return;
        } on AnalysisInputException catch (exception) {
          final code = switch (exception.error.code) {
            AnalysisErrorCode.emptyInput =>
              WindowsCaptureFailureCode.emptyCapturedText,
            AnalysisErrorCode.inputTooLong =>
              WindowsCaptureFailureCode.capturedTextTooLong,
            _ => WindowsCaptureFailureCode.unknown,
          };
          _emit(WindowsCaptureState.failed(code, capturedText: text));
          return;
        }
    }
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _captureGeneration;

  void _emit(WindowsCaptureState nextState) {
    if (_disposed) {
      return;
    }
    _state = nextState;
    if (!_states.isClosed) {
      _states.add(nextState);
    }
  }
}
