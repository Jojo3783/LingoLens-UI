import '../domain/analysis_models.dart';

const Duration windowsCaptureTimeout = Duration(milliseconds: 1500);

enum WindowsCaptureFailureCode {
  hotkeyUnavailable,
  hotkeyWrongWindowThread,
  hotkeyRegistrationFailed,
  noSelection,
  captureUnsupported,
  uiAutomationBoundednessBlocked,
  accessDenied,
  captureTimeout,
  clipboardUnavailable,
  clipboardSnapshotUnsupported,
  clipboardUnchanged,
  clipboardEmpty,
  clipboardConcurrentModification,
  clipboardRestoreFailed,
  emptyCapturedText,
  capturedTextTooLong,
  windowActivationFailed,
  windowPositioningFailed,
  cancelled,
  unsupportedPlatform,
  unknown,
}

extension WindowsCaptureFailureContract on WindowsCaptureFailureCode {
  String get wireValue => switch (this) {
    WindowsCaptureFailureCode.hotkeyUnavailable => 'HOTKEY_UNAVAILABLE',
    WindowsCaptureFailureCode.hotkeyWrongWindowThread =>
      'HOTKEY_WRONG_WINDOW_THREAD',
    WindowsCaptureFailureCode.hotkeyRegistrationFailed =>
      'HOTKEY_REGISTRATION_FAILED',
    WindowsCaptureFailureCode.noSelection => 'NO_SELECTION',
    WindowsCaptureFailureCode.captureUnsupported => 'CAPTURE_UNSUPPORTED',
    WindowsCaptureFailureCode.uiAutomationBoundednessBlocked =>
      'T-12R2_UIA_BOUNDEDNESS_BLOCKED',
    WindowsCaptureFailureCode.accessDenied => 'ACCESS_DENIED',
    WindowsCaptureFailureCode.captureTimeout => 'CAPTURE_TIMEOUT',
    WindowsCaptureFailureCode.clipboardUnavailable => 'CLIPBOARD_UNAVAILABLE',
    WindowsCaptureFailureCode.clipboardSnapshotUnsupported =>
      'CLIPBOARD_SNAPSHOT_UNSUPPORTED',
    WindowsCaptureFailureCode.clipboardUnchanged => 'CLIPBOARD_UNCHANGED',
    WindowsCaptureFailureCode.clipboardEmpty => 'CLIPBOARD_EMPTY',
    WindowsCaptureFailureCode.clipboardConcurrentModification =>
      'CLIPBOARD_CONCURRENT_MODIFICATION',
    WindowsCaptureFailureCode.clipboardRestoreFailed =>
      'CLIPBOARD_RESTORE_FAILED',
    WindowsCaptureFailureCode.emptyCapturedText => 'EMPTY_CAPTURED_TEXT',
    WindowsCaptureFailureCode.capturedTextTooLong => 'CAPTURED_TEXT_TOO_LONG',
    WindowsCaptureFailureCode.windowActivationFailed =>
      'WINDOW_ACTIVATION_FAILED',
    WindowsCaptureFailureCode.windowPositioningFailed =>
      'WINDOW_POSITIONING_FAILED',
    WindowsCaptureFailureCode.cancelled => 'CAPTURE_CANCELLED',
    WindowsCaptureFailureCode.unsupportedPlatform => 'UNSUPPORTED_PLATFORM',
    WindowsCaptureFailureCode.unknown => 'WINDOWS_PLATFORM_UNKNOWN',
  };

  String get userMessage => switch (this) {
    WindowsCaptureFailureCode.hotkeyUnavailable => '全域快捷鍵目前無法使用；仍可直接在輸入框輸入文字。',
    WindowsCaptureFailureCode.hotkeyWrongWindowThread =>
      '全域快捷鍵註冊執行緒不正確，請重新啟動 LingoLens。',
    WindowsCaptureFailureCode.hotkeyRegistrationFailed =>
      '全域快捷鍵註冊失敗；仍可直接在輸入框輸入文字。',
    WindowsCaptureFailureCode.noSelection => '目前沒有可取得的選取文字。',
    WindowsCaptureFailureCode.captureUnsupported =>
      '目前的 Windows 應用程式不支援選取文字擷取。',
    WindowsCaptureFailureCode.uiAutomationBoundednessBlocked =>
      'UI Automation 擷取無法安全保證取消邊界，請改用手動輸入。',
    WindowsCaptureFailureCode.accessDenied => '目前的 Windows 應用程式拒絕提供選取文字。',
    WindowsCaptureFailureCode.captureTimeout => '選取文字擷取逾時，請重試。',
    WindowsCaptureFailureCode.clipboardUnavailable =>
      'Clipboard 目前無法使用，請改用手動輸入。',
    WindowsCaptureFailureCode.clipboardSnapshotUnsupported =>
      'Clipboard 內容格式無法安全保存，因此未進行擷取。',
    WindowsCaptureFailureCode.clipboardUnchanged => 'Clipboard 沒有產生新的選取文字。',
    WindowsCaptureFailureCode.clipboardEmpty => 'Clipboard 擷取結果為空白。',
    WindowsCaptureFailureCode.clipboardConcurrentModification =>
      'Clipboard 已被其他應用程式變更，為避免覆蓋新內容，擷取已取消。',
    WindowsCaptureFailureCode.clipboardRestoreFailed =>
      'Clipboard 還原未經確認完成，為保護資料未採用擷取結果。',
    WindowsCaptureFailureCode.emptyCapturedText => '擷取結果為空白，請改用手動輸入。',
    WindowsCaptureFailureCode.capturedTextTooLong =>
      '擷取文字超過 2000 個 Unicode code points，請縮短後重試。',
    WindowsCaptureFailureCode.windowActivationFailed =>
      'LingoLens 視窗無法啟用；擷取文字仍保留在輸入狀態中。',
    WindowsCaptureFailureCode.windowPositioningFailed =>
      'LingoLens 視窗無法定位；擷取文字仍保留在輸入狀態中。',
    WindowsCaptureFailureCode.cancelled => '選取文字擷取已取消。',
    WindowsCaptureFailureCode.unsupportedPlatform => '目前平台不支援 Windows 選取文字擷取。',
    WindowsCaptureFailureCode.unknown => 'Windows 選取文字擷取失敗，請改用手動輸入。',
  };
}

sealed class SelectedTextCaptureOutcome {
  const SelectedTextCaptureOutcome();
}

final class SelectedTextCaptureSuccess extends SelectedTextCaptureOutcome {
  const SelectedTextCaptureSuccess(this.text);

  final String text;
}

final class SelectedTextCaptureFailure extends SelectedTextCaptureOutcome {
  const SelectedTextCaptureFailure(this.code);

  final WindowsCaptureFailureCode code;
}

sealed class HotkeyRegistrationOutcome {
  const HotkeyRegistrationOutcome();
}

final class HotkeyRegistrationSuccess extends HotkeyRegistrationOutcome {
  const HotkeyRegistrationSuccess();
}

final class HotkeyRegistrationFailure extends HotkeyRegistrationOutcome {
  const HotkeyRegistrationFailure(this.code);

  final WindowsCaptureFailureCode code;
}

sealed class WindowOperationOutcome {
  const WindowOperationOutcome();
}

final class WindowOperationSuccess extends WindowOperationOutcome {
  const WindowOperationSuccess();
}

final class WindowOperationFailure extends WindowOperationOutcome {
  const WindowOperationFailure(this.code);

  final WindowsCaptureFailureCode code;
}

abstract interface class GlobalHotkeyService {
  Stream<void> get activations;

  Future<HotkeyRegistrationOutcome> initialize();

  Future<void> dispose();
}

abstract interface class SelectedTextService {
  Future<SelectedTextCaptureOutcome> capture({
    Duration timeout = windowsCaptureTimeout,
  });

  Future<void> cancel();
}

abstract interface class FloatingWindowService {
  Future<WindowOperationOutcome> showPanel({
    double width = 760,
    double height = 720,
  });

  Future<WindowOperationOutcome> hidePanel();
}

abstract interface class WindowActivationService {
  Future<WindowOperationOutcome> activate();
}

final class WindowsCaptureState {
  const WindowsCaptureState._({
    required this.phase,
    this.failure,
    this.capturedText,
  });

  const WindowsCaptureState.idle() : this._(phase: WindowsCapturePhase.idle);

  const WindowsCaptureState.ready() : this._(phase: WindowsCapturePhase.ready);

  const WindowsCaptureState.hotkeyUnavailable(WindowsCaptureFailureCode code)
    : this._(phase: WindowsCapturePhase.failure, failure: code);

  const WindowsCaptureState.capturing()
    : this._(phase: WindowsCapturePhase.capturing);

  const WindowsCaptureState.captured(String text)
    : this._(phase: WindowsCapturePhase.captured, capturedText: text);

  const WindowsCaptureState.failed(
    WindowsCaptureFailureCode code, {
    String? capturedText,
  }) : this._(
         phase: WindowsCapturePhase.failure,
         failure: code,
         capturedText: capturedText,
       );

  final WindowsCapturePhase phase;
  final WindowsCaptureFailureCode? failure;
  final String? capturedText;
}

enum WindowsCapturePhase { idle, ready, capturing, captured, failure }

extension WindowsCaptureStateApplicationError on WindowsCaptureFailureCode {
  AnalysisError? get analysisError => switch (this) {
    WindowsCaptureFailureCode.emptyCapturedText =>
      const AnalysisError.emptyInput(),
    WindowsCaptureFailureCode.capturedTextTooLong =>
      const AnalysisError.inputTooLong(),
    _ => null,
  };
}
