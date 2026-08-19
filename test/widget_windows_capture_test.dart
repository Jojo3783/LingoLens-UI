import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/application/analysis_state.dart';
import 'package:lingolens/application/windows_capture_controller.dart';
import 'package:lingolens/application/windows_platform_contracts.dart';
import 'package:lingolens/domain/analysis_models.dart';
import 'package:lingolens/presentation/analysis_page.dart';

void main() {
  testWidgets('captured text fills input without submitting analysis', (
    tester,
  ) async {
    final controller = AnalysisController(provider: _NeverCalledProvider());
    final selectedText = _WidgetSelectedText(
      const SelectedTextCaptureSuccess('synthetic selected text'),
    );
    final capture = _windowsCapture(selectedText);
    addTearDown(controller.dispose);
    addTearDown(capture.dispose);

    await tester.pumpWidget(_page(controller, capture));
    capture.triggerCapture();
    await tester.pump();
    await tester.pump();

    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('analysis-input')),
    );
    expect(input.controller?.text, 'synthetic selected text');
    expect(controller.state.phase, AnalysisPhase.idle);
    expect(find.byKey(const ValueKey('submit-analysis')), findsOneWidget);
    expect(find.byKey(const ValueKey('cancel-analysis')), findsNothing);
  });

  testWidgets('capture failure is exposed as an accessible user message', (
    tester,
  ) async {
    final controller = AnalysisController(provider: _NeverCalledProvider());
    final capture = _windowsCapture(
      _WidgetSelectedText(
        const SelectedTextCaptureFailure(
          WindowsCaptureFailureCode.accessDenied,
        ),
      ),
    );
    addTearDown(controller.dispose);
    addTearDown(capture.dispose);

    await tester.pumpWidget(_page(controller, capture));
    capture.triggerCapture();
    await tester.pump();
    await tester.pump();

    expect(
      find.bySemanticsLabel('目前的 Windows 應用程式拒絕提供選取文字。'),
      findsAtLeastNWidgets(1),
    );
    expect(find.text('目前的 Windows 應用程式拒絕提供選取文字。'), findsOneWidget);
  });

  testWidgets('Escape requests panel dismissal without changing the draft', (
    tester,
  ) async {
    final controller = AnalysisController(provider: _NeverCalledProvider());
    final floatingWindow = _WidgetFloatingWindow();
    final capture = _windowsCapture(
      _WidgetSelectedText(
        const SelectedTextCaptureSuccess('draft remains available'),
      ),
      floatingWindow: floatingWindow,
    );
    addTearDown(controller.dispose);
    addTearDown(capture.dispose);

    await tester.pumpWidget(_page(controller, capture));
    await tester.tap(find.byKey(const ValueKey('analysis-input')));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(floatingWindow.hideCalls, 1);
    expect(controller.state.phase, AnalysisPhase.idle);
  });
}

Widget _page(AnalysisController controller, WindowsCaptureController capture) =>
    MaterialApp(
      home: AnalysisPage(
        controller: controller,
        windowsCapture: capture,
        onFailureScenarioChanged: (_) {},
      ),
    );

WindowsCaptureController _windowsCapture(
  SelectedTextService selectedText, {
  FloatingWindowService? floatingWindow,
}) => WindowsCaptureController(
  hotkey: _WidgetHotkey(),
  selectedText: selectedText,
  floatingWindow: floatingWindow ?? _WidgetFloatingWindow(),
  activation: _WidgetActivation(),
);

final class _NeverCalledProvider implements AnalysisProvider {
  @override
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  ) async {
    throw StateError('provider must not be called by capture');
  }
}

final class _WidgetHotkey implements GlobalHotkeyService {
  final StreamController<void> _activations =
      StreamController<void>.broadcast();

  @override
  Stream<void> get activations => _activations.stream;

  @override
  Future<HotkeyRegistrationOutcome> initialize() async =>
      const HotkeyRegistrationSuccess();

  @override
  Future<void> dispose() => _activations.close();
}

final class _WidgetSelectedText implements SelectedTextService {
  _WidgetSelectedText(this.outcome);

  final SelectedTextCaptureOutcome outcome;

  @override
  Future<SelectedTextCaptureOutcome> capture({
    Duration timeout = windowsCaptureTimeout,
  }) async => outcome;

  @override
  Future<void> cancel() async {}
}

final class _WidgetFloatingWindow implements FloatingWindowService {
  int hideCalls = 0;

  @override
  Future<WindowOperationOutcome> showPanel({
    double width = 760,
    double height = 720,
  }) async => const WindowOperationSuccess();

  @override
  Future<WindowOperationOutcome> hidePanel() async {
    hideCalls++;
    return const WindowOperationSuccess();
  }
}

final class _WidgetActivation implements WindowActivationService {
  @override
  Future<WindowOperationOutcome> activate() async =>
      const WindowOperationSuccess();
}
