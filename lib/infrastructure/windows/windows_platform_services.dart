import 'dart:async';

import 'package:flutter/services.dart';

import '../../application/windows_platform_contracts.dart';

const MethodChannel _windowsChannel = MethodChannel(
  'lingolens/windows_platform',
);

final class WindowsGlobalHotkeyService implements GlobalHotkeyService {
  WindowsGlobalHotkeyService({MethodChannel? channel})
    : _channel = channel ?? _windowsChannel;

  final MethodChannel _channel;
  final StreamController<void> _activations =
      StreamController<void>.broadcast();
  bool _initialized = false;
  bool _disposed = false;

  @override
  Stream<void> get activations => _activations.stream;

  @override
  Future<HotkeyRegistrationOutcome> initialize() async {
    if (_disposed) {
      return const HotkeyRegistrationFailure(
        WindowsCaptureFailureCode.hotkeyRegistrationFailed,
      );
    }
    if (!_initialized) {
      _channel.setMethodCallHandler(_handleMethodCall);
      _initialized = true;
    }
    try {
      final response = await _channel.invokeMethod<Object?>('registerHotkey');
      final status = _status(response);
      return status == 'success'
          ? const HotkeyRegistrationSuccess()
          : HotkeyRegistrationFailure(_hotkeyFailure(status));
    } on MissingPluginException {
      return const HotkeyRegistrationFailure(
        WindowsCaptureFailureCode.unsupportedPlatform,
      );
    } on PlatformException {
      return const HotkeyRegistrationFailure(
        WindowsCaptureFailureCode.hotkeyRegistrationFailed,
      );
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    try {
      await _channel.invokeMethod<Object?>('unregisterHotkey');
    } on MissingPluginException {
      // 非 Windows 測試環境沒有 native channel，視為已完成清理。
    } on PlatformException {
      // 清理失敗不能阻止 Flutter application 關閉。
    }
    await _activations.close();
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (_disposed || call.method != 'hotkeyActivated') {
      return;
    }
    if (!_activations.isClosed) {
      _activations.add(null);
    }
  }
}

final class WindowsSelectedTextService implements SelectedTextService {
  WindowsSelectedTextService({MethodChannel? channel})
    : _channel = channel ?? _windowsChannel;

  final MethodChannel _channel;
  int _generation = 0;

  @override
  Future<SelectedTextCaptureOutcome> capture({
    Duration timeout = windowsCaptureTimeout,
  }) async {
    final generation = ++_generation;
    final clipboard = await _invoke(
      'captureClipboardFallback',
      <String, Object?>{'timeoutMs': _timeoutMilliseconds(timeout)},
    );
    if (!_isCurrent(generation)) {
      return const SelectedTextCaptureFailure(
        WindowsCaptureFailureCode.cancelled,
      );
    }
    final clipboardStatus = _status(clipboard);
    if (clipboardStatus == 'success') {
      return SelectedTextCaptureSuccess(_text(clipboard));
    }
    return _failure(clipboardStatus);
  }

  @override
  Future<void> cancel() async {
    ++_generation;
    try {
      await _channel.invokeMethod<Object?>('cancelCapture');
    } on MissingPluginException {
      // 非 Windows 測試環境不需要 native cancellation。
    } on PlatformException {
      // 舊 request 的完成結果仍會由 generation guard 丟棄。
    }
  }

  bool _isCurrent(int generation) => generation == _generation;

  int _timeoutMilliseconds(Duration duration) {
    final milliseconds = duration.inMilliseconds;
    return duration > Duration.zero && milliseconds == 0 ? 1 : milliseconds;
  }

  Future<Object?> _invoke(String method, Object? arguments) async {
    try {
      return await _channel.invokeMethod<Object?>(method, arguments);
    } on MissingPluginException {
      return <String, Object?>{'status': 'unsupportedPlatform'};
    } on PlatformException {
      return <String, Object?>{'status': 'unknown'};
    }
  }
}

final class WindowsFloatingWindowService implements FloatingWindowService {
  WindowsFloatingWindowService({MethodChannel? channel})
    : _channel = channel ?? _windowsChannel;

  final MethodChannel _channel;

  @override
  Future<WindowOperationOutcome> showPanel({
    double width = 760,
    double height = 720,
  }) async {
    final response = await _invoke('showPanel', <String, Object?>{
      'width': width,
      'height': height,
    });
    return _windowOutcome(_status(response));
  }

  @override
  Future<WindowOperationOutcome> hidePanel() async {
    final response = await _invoke('hidePanel');
    return _windowOutcome(_status(response));
  }

  Future<Object?> _invoke(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<Object?>(method, arguments);
    } on MissingPluginException {
      return <String, Object?>{'status': 'unsupportedPlatform'};
    } on PlatformException {
      return <String, Object?>{'status': 'windowActivationFailed'};
    }
  }
}

final class WindowsWindowActivationService implements WindowActivationService {
  WindowsWindowActivationService({MethodChannel? channel})
    : _channel = channel ?? _windowsChannel;

  final MethodChannel _channel;

  @override
  Future<WindowOperationOutcome> activate() async {
    try {
      final response = await _channel.invokeMethod<Object?>('activateWindow');
      return _windowOutcome(_status(response));
    } on MissingPluginException {
      return const WindowOperationFailure(
        WindowsCaptureFailureCode.unsupportedPlatform,
      );
    } on PlatformException {
      return const WindowOperationFailure(
        WindowsCaptureFailureCode.windowActivationFailed,
      );
    }
  }
}

String _status(Object? response) {
  if (response is Map) {
    final value = response['status'];
    if (value is String) {
      return value;
    }
  }
  return 'unknown';
}

String _text(Object? response) {
  if (response is Map) {
    final value = response['text'];
    if (value is String) {
      return value;
    }
  }
  return '';
}

SelectedTextCaptureFailure _failure(String status) =>
    SelectedTextCaptureFailure(switch (status) {
      'noSelection' => WindowsCaptureFailureCode.noSelection,
      'captureUnsupported' => WindowsCaptureFailureCode.captureUnsupported,
      'uiaBoundednessBlocked' =>
        WindowsCaptureFailureCode.uiAutomationBoundednessBlocked,
      'accessDenied' => WindowsCaptureFailureCode.accessDenied,
      'captureTimeout' => WindowsCaptureFailureCode.captureTimeout,
      'clipboardUnavailable' => WindowsCaptureFailureCode.clipboardUnavailable,
      'clipboardSnapshotUnsupported' =>
        WindowsCaptureFailureCode.clipboardSnapshotUnsupported,
      'clipboardUnchanged' => WindowsCaptureFailureCode.clipboardUnchanged,
      'clipboardEmpty' => WindowsCaptureFailureCode.clipboardEmpty,
      'clipboardConcurrentModification' =>
        WindowsCaptureFailureCode.clipboardConcurrentModification,
      'clipboardRestoreFailed' =>
        WindowsCaptureFailureCode.clipboardRestoreFailed,
      'cancelled' => WindowsCaptureFailureCode.cancelled,
      'unsupportedPlatform' => WindowsCaptureFailureCode.unsupportedPlatform,
      _ => WindowsCaptureFailureCode.unknown,
    });

WindowsCaptureFailureCode _hotkeyFailure(String status) => switch (status) {
  'hotkeyUnavailable' => WindowsCaptureFailureCode.hotkeyUnavailable,
  'wrongWindowThread' => WindowsCaptureFailureCode.hotkeyWrongWindowThread,
  'registrationFailed' => WindowsCaptureFailureCode.hotkeyRegistrationFailed,
  _ => WindowsCaptureFailureCode.hotkeyRegistrationFailed,
};

WindowOperationOutcome _windowOutcome(String status) => status == 'success'
    ? const WindowOperationSuccess()
    : WindowOperationFailure(switch (status) {
        'windowPositioningFailed' =>
          WindowsCaptureFailureCode.windowPositioningFailed,
        'unsupportedPlatform' => WindowsCaptureFailureCode.unsupportedPlatform,
        _ => WindowsCaptureFailureCode.windowActivationFailed,
      });
