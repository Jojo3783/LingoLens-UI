import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/windows_capture_controller.dart';
import 'package:lingolens/application/windows_platform_contracts.dart';

void main() {
  test(
    'hotkey registration failure remains visible as a typed state',
    () async {
      final hotkey = _FakeHotkey(
        const HotkeyRegistrationFailure(
          WindowsCaptureFailureCode.hotkeyUnavailable,
        ),
      );
      final controller = _controller(hotkey: hotkey);
      addTearDown(controller.dispose);

      await controller.initialize();

      expect(controller.state.phase, WindowsCapturePhase.failure);
      expect(
        controller.state.failure,
        WindowsCaptureFailureCode.hotkeyUnavailable,
      );
    },
  );

  test('capture fills the input boundary without invoking analysis', () async {
    final hotkey = _FakeHotkey(const HotkeyRegistrationSuccess());
    final selectedText = _FakeSelectedText();
    selectedText.responses.add(
      Future<SelectedTextCaptureOutcome>.value(
        const SelectedTextCaptureSuccess('captured example'),
      ),
    );
    final floatingWindow = _FakeFloatingWindow();
    final activation = _FakeActivation();
    final controller = _controller(
      hotkey: hotkey,
      selectedText: selectedText,
      floatingWindow: floatingWindow,
      activation: activation,
    );
    addTearDown(controller.dispose);

    await controller.initialize();
    hotkey.emit();
    await _settleAsync();

    expect(controller.state.phase, WindowsCapturePhase.captured);
    expect(controller.state.capturedText, 'captured example');
    expect(floatingWindow.showCalls, 1);
    expect(activation.calls, 1);
    expect(floatingWindow.events, ['show']);
    expect(activation.events, ['activate']);
  });

  test(
    'new capture wins over a late completion from an older capture',
    () async {
      final selectedText = _FakeSelectedText();
      final first = Completer<SelectedTextCaptureOutcome>();
      selectedText.responses.add(first.future);
      selectedText.responses.add(
        Future<SelectedTextCaptureOutcome>.value(
          const SelectedTextCaptureSuccess('newer capture'),
        ),
      );
      final controller = _controller(selectedText: selectedText);
      addTearDown(controller.dispose);

      controller.triggerCapture();
      controller.triggerCapture();
      await _settleAsync();
      expect(controller.state.capturedText, 'newer capture');

      first.complete(const SelectedTextCaptureSuccess('stale capture'));
      await _settleAsync();

      expect(controller.state.capturedText, 'newer capture');
    },
  );

  test('panel failure preserves captured text for manual recovery', () async {
    final selectedText = _FakeSelectedText();
    selectedText.responses.add(
      Future<SelectedTextCaptureOutcome>.value(
        const SelectedTextCaptureSuccess('preserved capture'),
      ),
    );
    final floatingWindow = _FakeFloatingWindow(
      const WindowOperationFailure(
        WindowsCaptureFailureCode.windowPositioningFailed,
      ),
    );
    final controller = _controller(
      selectedText: selectedText,
      floatingWindow: floatingWindow,
    );
    addTearDown(controller.dispose);

    controller.triggerCapture();
    await _settleAsync();

    expect(controller.state.phase, WindowsCapturePhase.failure);
    expect(
      controller.state.failure,
      WindowsCaptureFailureCode.windowPositioningFailed,
    );
    expect(controller.state.capturedText, 'preserved capture');
  });

  test('late completion after dispose emits no new state', () async {
    final selectedText = _FakeSelectedText();
    final pending = Completer<SelectedTextCaptureOutcome>();
    selectedText.responses.add(pending.future);
    final controller = _controller(selectedText: selectedText);
    final states = <WindowsCaptureState>[];
    final subscription = controller.states.listen(states.add);
    addTearDown(subscription.cancel);

    controller.triggerCapture();
    await controller.dispose();
    pending.complete(const SelectedTextCaptureSuccess('after dispose'));
    await _settleAsync();

    expect(states, hasLength(1));
    expect(states.single.phase, WindowsCapturePhase.capturing);
  });
}

WindowsCaptureController _controller({
  GlobalHotkeyService? hotkey,
  SelectedTextService? selectedText,
  FloatingWindowService? floatingWindow,
  WindowActivationService? activation,
}) => WindowsCaptureController(
  hotkey: hotkey ?? _FakeHotkey(const HotkeyRegistrationSuccess()),
  selectedText: selectedText ?? _FakeSelectedText(),
  floatingWindow: floatingWindow ?? _FakeFloatingWindow(),
  activation: activation ?? _FakeActivation(),
);

Future<void> _settleAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _FakeHotkey implements GlobalHotkeyService {
  _FakeHotkey(this.registration);

  final HotkeyRegistrationOutcome registration;
  final StreamController<void> _activations =
      StreamController<void>.broadcast();

  @override
  Stream<void> get activations => _activations.stream;

  @override
  Future<HotkeyRegistrationOutcome> initialize() async => registration;

  @override
  Future<void> dispose() => _activations.close();

  void emit() => _activations.add(null);
}

final class _FakeSelectedText implements SelectedTextService {
  final List<Future<SelectedTextCaptureOutcome>> responses =
      <Future<SelectedTextCaptureOutcome>>[];
  int _index = 0;

  @override
  Future<SelectedTextCaptureOutcome> capture({
    Duration timeout = windowsCaptureTimeout,
  }) {
    if (_index >= responses.length) {
      return Future<SelectedTextCaptureOutcome>.value(
        const SelectedTextCaptureFailure(WindowsCaptureFailureCode.noSelection),
      );
    }
    return responses[_index++];
  }

  @override
  Future<void> cancel() async {}
}

final class _FakeFloatingWindow implements FloatingWindowService {
  _FakeFloatingWindow([this.result = const WindowOperationSuccess()]);

  final WindowOperationOutcome result;
  final List<String> events = <String>[];
  int showCalls = 0;

  @override
  Future<WindowOperationOutcome> showPanel({
    double width = 760,
    double height = 720,
  }) async {
    showCalls++;
    events.add('show');
    return result;
  }

  @override
  Future<WindowOperationOutcome> hidePanel() async {
    events.add('hide');
    return const WindowOperationSuccess();
  }
}

final class _FakeActivation implements WindowActivationService {
  final List<String> events = <String>[];
  int calls = 0;

  @override
  Future<WindowOperationOutcome> activate() async {
    calls++;
    events.add('activate');
    return const WindowOperationSuccess();
  }
}
