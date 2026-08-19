#include "windows_platform_channel.h"
#include "windows_clipboard_state_machine.h"

#include <oleauto.h>
#include <uiautomation.h>
#include <windows.h>

#include <algorithm>
#include <chrono>
#include <cstring>
#include <mutex>
#include <string>
#include <thread>
#include <utility>
#include <vector>

namespace {

constexpr char kChannelName[] = "lingolens/windows_platform";
constexpr int kHotkeyId = 0x4C4C;
constexpr int kDefaultTimeoutMs = 1500;
constexpr std::size_t kMaximumClipboardSnapshotBytes = 64 * 1024 * 1024;
constexpr int kClipboardPostCopyCleanupTimeoutMs = 750;
constexpr UINT kRegisterHotkeyMessage = WM_APP + 40;
constexpr UINT kUnregisterHotkeyMessage = WM_APP + 41;
constexpr UINT kCaptureCompletedMessage = WM_APP + 42;

using EncodableValue = flutter::EncodableValue;

using NativeResponse = lingolens::NativeCaptureResponse;

EncodableValue ResponseValue(const NativeResponse& response) {
  flutter::EncodableMap map;
  map.emplace(EncodableValue("status"), EncodableValue(response.status));
  if (!response.text.empty()) {
    map.emplace(EncodableValue("text"), EncodableValue(response.text));
  }
  if (response.error_code != 0) {
    map.emplace(EncodableValue("errorCode"),
                EncodableValue(static_cast<int32_t>(response.error_code)));
  }
  if (response.current_thread_id != 0) {
    map.emplace(EncodableValue("currentThreadId"),
                EncodableValue(static_cast<int32_t>(response.current_thread_id)));
  }
  if (response.window_thread_id != 0) {
    map.emplace(EncodableValue("windowThreadId"),
                EncodableValue(static_cast<int32_t>(response.window_thread_id)));
  }
  if (!response.cancellation_outcome.empty()) {
    map.emplace(EncodableValue("cancellationOutcome"),
                EncodableValue(response.cancellation_outcome));
  }
  if (response.cancellation_error_code != 0) {
    map.emplace(EncodableValue("cancellationErrorCode"),
                EncodableValue(static_cast<int32_t>(response.cancellation_error_code)));
  }
  return EncodableValue(map);
}

std::string WideToUtf8(const wchar_t* value, int length = -1) {
  if (value == nullptr) {
    return {};
  }
  const int required = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, value,
                                           length, nullptr, 0, nullptr, nullptr);
  if (required <= 0) {
    return {};
  }
  std::string result(static_cast<std::size_t>(required), '\0');
  WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, value, length,
                      result.data(), required, nullptr, nullptr);
  if (length < 0 && !result.empty() && result.back() == '\0') {
    result.pop_back();
  }
  return result;
}

int TimeoutMilliseconds(const EncodableValue* arguments) {
  if (arguments == nullptr || !std::holds_alternative<flutter::EncodableMap>(
                                  *arguments)) {
    return kDefaultTimeoutMs;
  }
  const auto& map = std::get<flutter::EncodableMap>(*arguments);
  const auto it = map.find(EncodableValue("timeoutMs"));
  if (it == map.end() || !std::holds_alternative<int32_t>(it->second)) {
    return kDefaultTimeoutMs;
  }
  return std::clamp(std::get<int32_t>(it->second), 100, 10000);
}

double DoubleArgument(const EncodableValue* arguments, const char* name,
                      double fallback) {
  if (arguments == nullptr || !std::holds_alternative<flutter::EncodableMap>(
                                  *arguments)) {
    return fallback;
  }
  const auto& map = std::get<flutter::EncodableMap>(*arguments);
  const auto it = map.find(EncodableValue(name));
  if (it == map.end()) {
    return fallback;
  }
  if (std::holds_alternative<double>(it->second)) {
    return std::get<double>(it->second);
  }
  if (std::holds_alternative<int32_t>(it->second)) {
    return static_cast<double>(std::get<int32_t>(it->second));
  }
  return fallback;
}

bool IsAccessDenied(HRESULT result) {
  return result == E_ACCESSDENIED || result == HRESULT_FROM_WIN32(ERROR_ACCESS_DENIED);
}

NativeResponse CaptureWithUiAutomation(
    std::uint64_t generation,
    const std::atomic<std::uint64_t>* current_generation,
    const std::shared_ptr<lingolens::NativeCaptureLifecycle>& lifecycle,
    std::atomic<bool>* call_cancellation_enabled,
    std::atomic<bool>* call_cancellation_supported) {
  const auto interrupted_response = [&]() {
    return lifecycle->IsTimedOut() ? NativeResponse{"captureTimeout", {}}
                                   : NativeResponse{"cancelled", {}};
  };
  const auto is_current = [&]() {
    return generation == current_generation->load() &&
           !lifecycle->IsCancelled() && !lifecycle->IsTimedOut();
  };
  if (!is_current()) {
    return interrupted_response();
  }

  HRESULT com_result = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  const bool should_uninitialize = SUCCEEDED(com_result);
  if (FAILED(com_result) && com_result != RPC_E_CHANGED_MODE) {
    return {"captureUnsupported", {}};
  }

  IUIAutomation* automation = nullptr;
  IUIAutomation2* automation2 = nullptr;
  IUIAutomationElement* element = nullptr;
  IUnknown* unknown_pattern = nullptr;
  IUIAutomationTextPattern* text_pattern = nullptr;
  IUIAutomationTextRangeArray* ranges = nullptr;
  NativeResponse response{"captureUnsupported", {}};

  const HRESULT cancellation_result = CoEnableCallCancellation(nullptr);
  if (FAILED(cancellation_result)) {
    response.status = "uiaBoundednessBlocked";
    if (should_uninitialize) {
      CoUninitialize();
    }
    return response;
  }
  call_cancellation_supported->store(true);
  call_cancellation_enabled->store(true);

  const auto finish = [&]() {
    if (ranges != nullptr) {
      ranges->Release();
    }
    if (text_pattern != nullptr) {
      text_pattern->Release();
    }
    if (unknown_pattern != nullptr) {
      unknown_pattern->Release();
    }
    if (element != nullptr) {
      element->Release();
    }
    if (automation2 != nullptr) {
      automation2->Release();
    }
    if (automation != nullptr) {
      automation->Release();
    }
    if (call_cancellation_enabled->exchange(false)) {
      CoDisableCallCancellation(nullptr);
    }
    if (should_uninitialize) {
      CoUninitialize();
    }
    return response;
  };

  const auto deadline_expired_response = [&]() {
    response = interrupted_response();
    if (!lifecycle->IsCancelled() && !lifecycle->IsTimedOut() &&
        generation == current_generation->load()) {
      response.status = "captureTimeout";
    }
    return finish();
  };

  if (!is_current()) {
    response = interrupted_response();
    return finish();
  }

  HRESULT result = CoCreateInstance(CLSID_CUIAutomation, nullptr,
                                    CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&automation));
  if (FAILED(result)) {
    if (!is_current()) {
      response = interrupted_response();
      return finish();
    }
    response.status = IsAccessDenied(result) ? "accessDenied" : "captureUnsupported";
    return finish();
  }
  if (!is_current()) {
    response = interrupted_response();
    return finish();
  }

  result = automation->QueryInterface(IID_PPV_ARGS(&automation2));
  if (FAILED(result) || automation2 == nullptr) {
    response.status = "uiaBoundednessBlocked";
    return finish();
  }

  DWORD provider_timeout_ms = 0;
  if (!lingolens::CalculateNativeUiaTimeoutMilliseconds(
          std::chrono::steady_clock::now(), lifecycle->deadline(),
          &provider_timeout_ms)) {
    return deadline_expired_response();
  }
  result = automation2->put_ConnectionTimeout(provider_timeout_ms);
  if (FAILED(result)) {
    response.status = "uiaBoundednessBlocked";
    return finish();
  }
  if (!is_current()) {
    response = interrupted_response();
    return finish();
  }
  if (!lingolens::CalculateNativeUiaTimeoutMilliseconds(
          std::chrono::steady_clock::now(), lifecycle->deadline(),
          &provider_timeout_ms)) {
    return deadline_expired_response();
  }
  result = automation2->put_TransactionTimeout(provider_timeout_ms);
  if (FAILED(result)) {
    response.status = "uiaBoundednessBlocked";
    return finish();
  }
  if (!is_current()) {
    response = interrupted_response();
    return finish();
  }
  if (!lingolens::CalculateNativeUiaTimeoutMilliseconds(
          std::chrono::steady_clock::now(), lifecycle->deadline(),
          &provider_timeout_ms)) {
    return deadline_expired_response();
  }

  result = automation->GetFocusedElement(&element);
  if (FAILED(result)) {
    if (!is_current()) {
      response = interrupted_response();
      return finish();
    }
    response.status = IsAccessDenied(result) ? "accessDenied" : "captureUnsupported";
    return finish();
  }
  if (!is_current()) {
    response = interrupted_response();
    return finish();
  }
  result = element->GetCurrentPattern(UIA_TextPatternId, &unknown_pattern);
  if (FAILED(result) || unknown_pattern == nullptr) {
    if (!is_current()) {
      response = interrupted_response();
      return finish();
    }
    response.status = IsAccessDenied(result) ? "accessDenied" : "captureUnsupported";
    return finish();
  }
  if (!is_current()) {
    response = interrupted_response();
    return finish();
  }
  result = unknown_pattern->QueryInterface(IID_PPV_ARGS(&text_pattern));
  if (FAILED(result) || text_pattern == nullptr) {
    if (!is_current()) {
      response = interrupted_response();
      return finish();
    }
    response.status = IsAccessDenied(result) ? "accessDenied" : "captureUnsupported";
    return finish();
  }
  if (!is_current()) {
    response = interrupted_response();
    return finish();
  }
  result = text_pattern->GetSelection(&ranges);
  if (FAILED(result) || ranges == nullptr) {
    if (!is_current()) {
      response = interrupted_response();
      return finish();
    }
    response.status = IsAccessDenied(result) ? "accessDenied" : "noSelection";
    return finish();
  }

  int range_count = 0;
  if (!is_current()) {
    response = interrupted_response();
    return finish();
  }
  ranges->get_Length(&range_count);
  for (int index = 0; index < range_count; ++index) {
    if (!is_current()) {
      response = interrupted_response();
      response.text.clear();
      return finish();
    }
    IUIAutomationTextRange* range = nullptr;
    if (FAILED(ranges->GetElement(index, &range)) || range == nullptr) {
      if (!is_current()) {
        response = interrupted_response();
        response.text.clear();
        return finish();
      }
      continue;
    }
    BSTR selected_text = nullptr;
    if (SUCCEEDED(range->GetText(-1, &selected_text)) && selected_text != nullptr) {
      response.text.append(WideToUtf8(selected_text));
    }
    SysFreeString(selected_text);
    range->Release();
    if (!is_current()) {
      response = interrupted_response();
      response.text.clear();
      return finish();
    }
  }
  response.status = response.text.empty() ? "noSelection" : "success";
  return finish();
}

struct ClipboardFormatData {
  UINT format = 0;
  std::vector<BYTE> bytes;
};

struct ClipboardSnapshot {
  std::vector<ClipboardFormatData> formats;
  std::size_t total_bytes = 0;
};

bool OpenClipboardUntil(HWND window, std::chrono::steady_clock::time_point deadline) {
  while (std::chrono::steady_clock::now() < deadline) {
    if (OpenClipboard(window)) {
      return true;
    }
    Sleep(10);
  }
  return false;
}

NativeResponse SnapshotClipboard(HWND window,
                                std::chrono::steady_clock::time_point deadline,
                                ClipboardSnapshot* snapshot) {
  if (!OpenClipboardUntil(window, deadline)) {
    return {"clipboardUnavailable", {}};
  }
  UINT format = 0;
  while ((format = EnumClipboardFormats(format)) != 0) {
    HANDLE handle = GetClipboardData(format);
    const SIZE_T size = handle == nullptr ? 0 : GlobalSize(handle);
    if (handle == nullptr || size == 0 ||
        snapshot->total_bytes + size > kMaximumClipboardSnapshotBytes) {
      CloseClipboard();
      return {"clipboardSnapshotUnsupported", {}};
    }
    void* source = GlobalLock(handle);
    if (source == nullptr) {
      CloseClipboard();
      return {"clipboardSnapshotUnsupported", {}};
    }
    ClipboardFormatData data;
    data.format = format;
    data.bytes.resize(size);
    memcpy(data.bytes.data(), source, size);
    GlobalUnlock(handle);
    snapshot->total_bytes += size;
    snapshot->formats.push_back(std::move(data));
  }
  CloseClipboard();
  return {"success", {}};
}

bool RestoreClipboard(HWND window, const ClipboardSnapshot& snapshot,
                      DWORD expected_sequence,
                      std::chrono::steady_clock::time_point deadline) {
  std::vector<HGLOBAL> allocated;
  allocated.reserve(snapshot.formats.size());
  for (const auto& data : snapshot.formats) {
    HGLOBAL memory = GlobalAlloc(GMEM_MOVEABLE, data.bytes.size());
    if (memory == nullptr) {
      for (HGLOBAL item : allocated) {
        GlobalFree(item);
      }
      return false;
    }
    void* destination = GlobalLock(memory);
    if (destination == nullptr) {
      GlobalFree(memory);
      for (HGLOBAL item : allocated) {
        GlobalFree(item);
      }
      return false;
    }
    memcpy(destination, data.bytes.data(), data.bytes.size());
    GlobalUnlock(memory);
    allocated.push_back(memory);
  }

  if (!OpenClipboardUntil(window, deadline)) {
    for (HGLOBAL item : allocated) {
      GlobalFree(item);
    }
    return false;
  }
  if (GetClipboardSequenceNumber() != expected_sequence) {
    CloseClipboard();
    for (HGLOBAL item : allocated) {
      GlobalFree(item);
    }
    return false;
  }
  bool success = EmptyClipboard() != FALSE;
  std::vector<bool> transferred(snapshot.formats.size(), false);
  for (std::size_t index = 0; success && index < snapshot.formats.size(); ++index) {
    if (SetClipboardData(snapshot.formats[index].format, allocated[index]) ==
        nullptr) {
      GlobalFree(allocated[index]);
      success = false;
    } else {
      transferred[index] = true;
    }
  }
  if (!success) {
    for (std::size_t index = 0; index < allocated.size(); ++index) {
      if (!transferred[index]) {
        GlobalFree(allocated[index]);
      }
    }
  }
  CloseClipboard();
  return success;
}

bool SnapshotEquals(HWND window, const ClipboardSnapshot& expected,
                    std::chrono::steady_clock::time_point deadline) {
  ClipboardSnapshot actual;
  const NativeResponse response = SnapshotClipboard(window, deadline, &actual);
  if (response.status != "success" || actual.formats.size() != expected.formats.size()) {
    return false;
  }
  for (std::size_t index = 0; index < expected.formats.size(); ++index) {
    if (actual.formats[index].format != expected.formats[index].format ||
        actual.formats[index].bytes != expected.formats[index].bytes) {
      return false;
    }
  }
  return true;
}

NativeResponse ReadClipboardText(HWND window,
                                 std::chrono::steady_clock::time_point deadline) {
  if (!OpenClipboardUntil(window, deadline)) {
    return {"clipboardUnavailable", {}};
  }
  HANDLE handle = GetClipboardData(CF_UNICODETEXT);
  if (handle == nullptr) {
    CloseClipboard();
    return {"clipboardEmpty", {}};
  }
  const wchar_t* text = static_cast<const wchar_t*>(GlobalLock(handle));
  if (text == nullptr) {
    CloseClipboard();
    return {"clipboardEmpty", {}};
  }
  std::string result = WideToUtf8(text);
  GlobalUnlock(handle);
  CloseClipboard();
  if (result.empty()) {
    return {"clipboardEmpty", {}};
  }
  return {"success", std::move(result)};
}

bool SendCopyInput() {
  INPUT inputs[4] = {};
  inputs[0].type = INPUT_KEYBOARD;
  inputs[0].ki.wVk = VK_CONTROL;
  inputs[1].type = INPUT_KEYBOARD;
  inputs[1].ki.wVk = 'C';
  inputs[2].type = INPUT_KEYBOARD;
  inputs[2].ki.wVk = 'C';
  inputs[2].ki.dwFlags = KEYEVENTF_KEYUP;
  inputs[3].type = INPUT_KEYBOARD;
  inputs[3].ki.wVk = VK_CONTROL;
  inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;
  return SendInput(4, inputs, sizeof(INPUT)) == 4;
}

NativeResponse CaptureClipboardFallback(
    HWND window, std::uint64_t generation,
    const std::atomic<std::uint64_t>* current_generation,
    const std::shared_ptr<lingolens::NativeCaptureLifecycle>& lifecycle) {
  const auto deadline = lifecycle->deadline();
  lingolens::HotkeyReleaseHooks release_hooks;
  release_hooks.key_down = [](int virtual_key) {
    return (GetAsyncKeyState(virtual_key) & 0x8000) != 0;
  };
  release_hooks.wait_for_next_observation = []() { Sleep(10); };
  release_hooks.cancelled = [lifecycle]() { return lifecycle->IsCancelled(); };
  release_hooks.generation_current = [generation, current_generation]() {
    return generation == current_generation->load();
  };
  release_hooks.now = []() {
    return lingolens::HotkeyReleaseHooks::Clock::now();
  };
  const auto release_outcome = lingolens::WaitForHotkeyRelease(
      std::move(release_hooks), deadline);
  if (release_outcome == lingolens::HotkeyReleaseOutcome::cancelled) {
    lifecycle->RequestCancel();
    return {"cancelled", {}};
  }
  if (release_outcome == lingolens::HotkeyReleaseOutcome::captureTimeout) {
    lifecycle->RequestTimeout();
    return {"captureTimeout", {}};
  }

  ClipboardSnapshot snapshot;
  lingolens::ClipboardFallbackHooks hooks;
  hooks.snapshot = [&]() {
    return SnapshotClipboard(window, deadline, &snapshot).status == "success";
  };
  hooks.send_copy = SendCopyInput;
  hooks.sequence = GetClipboardSequenceNumber;
  hooks.read_text = [&]() { return ReadClipboardText(window, deadline); };
  hooks.restore_and_verify = [&](DWORD expected_sequence,
                                 lingolens::ClipboardFallbackHooks::Clock::time_point
                                     cleanup_deadline) {
    return RestoreClipboard(window, snapshot, expected_sequence, cleanup_deadline) &&
           SnapshotEquals(window, snapshot, cleanup_deadline);
  };
  hooks.wait_for_next_observation = []() { Sleep(10); };
  hooks.cancelled = [lifecycle]() { return lifecycle->IsCancelled(); };
  hooks.timed_out = [lifecycle]() { return lifecycle->IsTimedOut(); };
  hooks.generation_current = [generation, current_generation]() {
    return generation == current_generation->load();
  };
  hooks.may_start_side_effect = [lifecycle, generation,
                                 current_generation](auto now) {
    return lifecycle->CanStartSideEffect(now) &&
           generation == current_generation->load();
  };
  hooks.mark_copy_started = [lifecycle]() { lifecycle->MarkCopyStarted(); };
  hooks.mark_cleanup_finished =
      [lifecycle]() { lifecycle->MarkCleanupFinished(); };
  hooks.request_cancel = [lifecycle]() { lifecycle->RequestCancel(); };
  hooks.request_timeout = [lifecycle]() { lifecycle->RequestTimeout(); };
  return lingolens::ClipboardFallbackStateMachine::Run(
      std::move(hooks), deadline,
      std::chrono::milliseconds(kClipboardPostCopyCleanupTimeoutMs));
}

}

struct WindowsPlatformChannel::HotkeyRequest {
  bool register_hotkey;
  std::unique_ptr<MethodResult> result;
};

struct WindowsPlatformChannel::NativeCaptureOperation {
  NativeCaptureOperation(
      HWND window,
      std::function<NativeResponse(
          std::shared_ptr<lingolens::NativeCaptureLifecycle>,
          std::atomic<DWORD>*,
          std::atomic<bool>*,
          std::atomic<bool>*)> work,
      std::shared_ptr<lingolens::NativeCaptureLifecycle> lifecycle,
      std::unique_ptr<MethodResult> result)
      : window(window),
        work(std::move(work)),
        lifecycle(std::move(lifecycle)),
        result(std::move(result)) {}

  void StartWatchdog() {
    watchdog.Start(lifecycle->deadline(), [this]() { HandleDeadline(); });
  }

  void RequestCancel() {
    lifecycle->RequestCancel();
    TryCancelComCall();
    watchdog.RequestCancel();
  }

  void RequestShutdown() {
    lifecycle->RequestCancel();
    TryCancelComCall();
    watchdog.RequestShutdown();
  }

  void CompleteWorker() { watchdog.NotifyWorkerCompleted(); }

  void Shutdown() { watchdog.Shutdown(); }

  void ApplyCancellationMetadata(NativeResponse* output) const {
    if (!call_cancellation_supported.load() && !cancellation_attempted.load()) {
      return;
    }
    if (!cancellation_attempted.load()) {
      output->cancellation_outcome = "notAttempted";
      return;
    }
    const HRESULT cancellation_result = cancellation_result_.load();
    const auto outcome = lingolens::ClassifyCallCancellationResult(cancellation_result);
    output->cancellation_outcome =
        outcome == lingolens::NativeCallCancellationOutcome::succeeded
            ? "succeeded"
            : "failed";
    if (outcome == lingolens::NativeCallCancellationOutcome::failed) {
      output->cancellation_error_code = static_cast<DWORD>(cancellation_result);
    }
  }

  ~NativeCaptureOperation() {
    RequestShutdown();
    if (worker.joinable()) {
      worker.join();
    }
    Shutdown();
  }

 private:
  void HandleDeadline() {
    lifecycle->RequestTimeout();
    TryCancelComCall();
  }

  void TryCancelComCall() {
    if (!call_cancellation_enabled.load()) {
      return;
    }
    const DWORD target_thread_id = worker_thread_id.load();
    if (target_thread_id == 0 || target_thread_id == GetCurrentThreadId()) {
      return;
    }
    bool expected = false;
    if (!cancellation_attempted.compare_exchange_strong(expected, true)) {
      return;
    }
    cancellation_result_.store(CoCancelCall(target_thread_id, 0));
  }

 public:
  HWND window;
  std::function<NativeResponse(
      std::shared_ptr<lingolens::NativeCaptureLifecycle>,
      std::atomic<DWORD>*,
      std::atomic<bool>*,
      std::atomic<bool>*)>
      work;
  std::shared_ptr<lingolens::NativeCaptureLifecycle> lifecycle;
  std::unique_ptr<MethodResult> result;
  NativeResponse response;
  std::mutex response_mutex;
  std::thread worker;
  lingolens::NativeCaptureDeadlineWatchdog watchdog;
  std::atomic<DWORD> worker_thread_id{0};
  std::atomic<bool> call_cancellation_enabled{false};
  std::atomic<bool> call_cancellation_supported{false};
  std::atomic<bool> cancellation_attempted{false};
  std::atomic<HRESULT> cancellation_result_{E_NOTIMPL};
};

WindowsPlatformChannel::WindowsPlatformChannel(flutter::FlutterEngine* engine,
                                               HWND window)
    : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      engine->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<EncodableValue>& call,
             std::unique_ptr<MethodResult> result) {
        HandleMethodCall(call, std::move(result));
      });
}

WindowsPlatformChannel::~WindowsPlatformChannel() {
  shutting_down_ = true;
  CancelActiveCaptures();
  for (const auto& operation : capture_operations_) {
    operation->RequestShutdown();
    if (operation->worker.joinable()) {
      operation->worker.join();
    }
    operation->Shutdown();
  }
  capture_operations_.clear();
  if (hotkey_registered_) {
    UnregisterHotKey(window_, kHotkeyId);
  }
}

bool WindowsPlatformChannel::HandleWindowMessage(UINT message, WPARAM wparam,
                                                 LPARAM lparam) {
  if (message == kRegisterHotkeyMessage || message == kUnregisterHotkeyMessage) {
    std::unique_ptr<HotkeyRequest> request(
        reinterpret_cast<HotkeyRequest*>(lparam));
    if (request == nullptr) {
      return true;
    }
    if (message == kRegisterHotkeyMessage) {
      RegisterHotkeyOnOwnerThread(std::move(request->result));
    } else {
      UnregisterHotkeyOnOwnerThread(std::move(request->result));
    }
    return true;
  }
  if (message == kCaptureCompletedMessage) {
    CompleteCapture(reinterpret_cast<void*>(lparam));
    return true;
  }
  if (message != WM_HOTKEY || wparam != kHotkeyId || channel_ == nullptr) {
    return false;
  }
  channel_->InvokeMethod("hotkeyActivated", std::make_unique<EncodableValue>());
  return true;
}

void WindowsPlatformChannel::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& call,
    std::unique_ptr<MethodResult> result) {
  if (call.method_name() == "registerHotkey") {
    RegisterHotkey(std::move(result));
  } else if (call.method_name() == "unregisterHotkey") {
    UnregisterHotkey(std::move(result));
  } else if (call.method_name() == "cancelCapture") {
    CancelCapture(std::move(result));
  } else if (call.method_name() == "captureSelectedText") {
    CaptureSelectedText(call.arguments(), std::move(result));
  } else if (call.method_name() == "captureClipboardFallback") {
    CaptureClipboardFallback(call.arguments(), std::move(result));
  } else if (call.method_name() == "showPanel") {
    ShowPanel(call.arguments(), std::move(result));
  } else if (call.method_name() == "hidePanel") {
    HidePanel(std::move(result));
  } else if (call.method_name() == "activateWindow") {
    ActivateWindow(std::move(result));
  } else {
    result->NotImplemented();
  }
}

void WindowsPlatformChannel::RegisterHotkey(std::unique_ptr<MethodResult> result) {
  const DWORD window_thread_id = GetWindowThreadProcessId(window_, nullptr);
  if (window_thread_id != GetCurrentThreadId()) {
    auto request = new HotkeyRequest{true, std::move(result)};
    if (!PostMessage(window_, kRegisterHotkeyMessage, 0,
                     reinterpret_cast<LPARAM>(request))) {
      std::unique_ptr<HotkeyRequest> failed(request);
      failed->result->Success(ResponseValue({"registrationFailed", {}}));
    }
    return;
  }
  RegisterHotkeyOnOwnerThread(std::move(result));
}

void WindowsPlatformChannel::UnregisterHotkey(std::unique_ptr<MethodResult> result) {
  const DWORD window_thread_id = GetWindowThreadProcessId(window_, nullptr);
  if (window_thread_id != GetCurrentThreadId()) {
    auto request = new HotkeyRequest{false, std::move(result)};
    if (!PostMessage(window_, kUnregisterHotkeyMessage, 0,
                     reinterpret_cast<LPARAM>(request))) {
      std::unique_ptr<HotkeyRequest> failed(request);
      failed->result->Success(ResponseValue({"registrationFailed", {}}));
    }
    return;
  }
  UnregisterHotkeyOnOwnerThread(std::move(result));
}

void WindowsPlatformChannel::RegisterHotkeyOnOwnerThread(
    std::unique_ptr<MethodResult> result) {
  if (hotkey_registered_) {
    result->Success(ResponseValue({"success", {}}));
    return;
  }
  if (RegisterHotKey(window_, kHotkeyId, lingolens::kRequiredHotkeyModifiers,
                     lingolens::kRequiredHotkeyVirtualKey)) {
    hotkey_registered_ = true;
    result->Success(ResponseValue({"success", {}}));
    return;
  }
  const DWORD error_code = GetLastError();
  const DWORD current_thread_id = GetCurrentThreadId();
  const DWORD window_thread_id = GetWindowThreadProcessId(window_, nullptr);
  const auto status = lingolens::ClassifyHotkeyRegistration(
      current_thread_id, window_thread_id, error_code);
  const char* wire_status = "registrationFailed";
  if (status == lingolens::HotkeyRegistrationStatus::wrongWindowThread) {
    wire_status = "wrongWindowThread";
  } else if (status == lingolens::HotkeyRegistrationStatus::hotkeyUnavailable) {
    wire_status = "hotkeyUnavailable";
  }
  result->Success(ResponseValue({wire_status, {}, error_code,
                                 current_thread_id, window_thread_id}));
}

void WindowsPlatformChannel::UnregisterHotkeyOnOwnerThread(
    std::unique_ptr<MethodResult> result) {
  if (hotkey_registered_) {
    hotkey_registered_ = false;
    UnregisterHotKey(window_, kHotkeyId);
  }
  result->Success(ResponseValue({"success", {}}));
}

void WindowsPlatformChannel::CancelCapture(std::unique_ptr<MethodResult> result) {
  CancelActiveCaptures();
  result->Success(ResponseValue({"success", {}}));
}

void WindowsPlatformChannel::CancelActiveCaptures() {
  capture_generation_->fetch_add(1);
  for (const auto& operation : capture_operations_) {
    operation->RequestCancel();
  }
}

void WindowsPlatformChannel::CaptureSelectedText(
    const EncodableValue* arguments, std::unique_ptr<MethodResult> result) {
  CancelActiveCaptures();
  const std::uint64_t generation = capture_generation_->fetch_add(1) + 1;
  const int timeout_ms = TimeoutMilliseconds(arguments);
  const auto generation_state = capture_generation_;
  StartCapture(
      [generation_state, generation](
          std::shared_ptr<lingolens::NativeCaptureLifecycle> lifecycle,
          std::atomic<DWORD>*,
          std::atomic<bool>* call_cancellation_enabled,
          std::atomic<bool>* call_cancellation_supported) {
        return CaptureWithUiAutomation(
            generation, generation_state.get(), lifecycle,
            call_cancellation_enabled, call_cancellation_supported);
      },
      timeout_ms, std::move(result));
}

void WindowsPlatformChannel::CaptureClipboardFallback(
    const EncodableValue* arguments, std::unique_ptr<MethodResult> result) {
  CancelActiveCaptures();
  const std::uint64_t generation = capture_generation_->fetch_add(1) + 1;
  const int timeout_ms = TimeoutMilliseconds(arguments);
  const auto generation_state = capture_generation_;
  const HWND window = window_;
  StartCapture(
      [window, generation_state, generation](
          std::shared_ptr<lingolens::NativeCaptureLifecycle> lifecycle,
          std::atomic<DWORD>*,
          std::atomic<bool>*,
          std::atomic<bool>*) {
        return ::CaptureClipboardFallback(window, generation,
                                          generation_state.get(), lifecycle);
      },
      timeout_ms, std::move(result));
}

void WindowsPlatformChannel::StartCapture(
    std::function<NativeResponse(
        std::shared_ptr<lingolens::NativeCaptureLifecycle>,
        std::atomic<DWORD>*,
        std::atomic<bool>*,
        std::atomic<bool>*)> work,
    int timeout_ms, std::unique_ptr<MethodResult> result) {
  if (shutting_down_) {
    result->Success(ResponseValue({"cancelled", {}}));
    return;
  }
  auto lifecycle = std::make_shared<lingolens::NativeCaptureLifecycle>(
      std::chrono::steady_clock::now() + std::chrono::milliseconds(timeout_ms));
  auto operation = std::make_shared<NativeCaptureOperation>(
      window_, std::move(work), std::move(lifecycle), std::move(result));
  capture_operations_.push_back(operation);
  operation->StartWatchdog();
  operation->worker = std::thread([operation]() {
    operation->worker_thread_id.store(GetCurrentThreadId());
    NativeResponse response = operation->work(operation->lifecycle,
                                              &operation->worker_thread_id,
                                              &operation->call_cancellation_enabled,
                                              &operation->call_cancellation_supported);
    operation->worker_thread_id.store(0);
    if (operation->lifecycle->IsCancelled()) {
      response = {"cancelled", {}};
    } else if (std::chrono::steady_clock::now() >=
               operation->lifecycle->deadline()) {
      operation->lifecycle->RequestTimeout();
      response = {"captureTimeout", {}};
    }
    operation->ApplyCancellationMetadata(&response);
    {
      std::lock_guard<std::mutex> lock(operation->response_mutex);
      operation->response = std::move(response);
    }
    operation->CompleteWorker();
    PostMessage(operation->window, kCaptureCompletedMessage, 0,
                reinterpret_cast<LPARAM>(operation.get()));
  });
}

void WindowsPlatformChannel::CompleteCapture(void* raw_operation) {
  auto iterator = std::find_if(
      capture_operations_.begin(), capture_operations_.end(),
      [raw_operation](const auto& operation) {
        return operation.get() == raw_operation;
      });
  if (iterator == capture_operations_.end()) {
    return;
  }
  const auto operation = *iterator;
  if (operation->worker.joinable()) {
    operation->worker.join();
  }
  operation->Shutdown();
  NativeResponse response;
  {
    std::lock_guard<std::mutex> lock(operation->response_mutex);
    response = std::move(operation->response);
  }
  auto result = std::move(operation->result);
  capture_operations_.erase(iterator);
  if (result != nullptr) {
    result->Success(ResponseValue(response));
  }
}

void WindowsPlatformChannel::ShowPanel(const EncodableValue* arguments,
                                       std::unique_ptr<MethodResult> result) {
  if (window_ == nullptr) {
    result->Success(ResponseValue({"windowPositioningFailed", {}}));
    return;
  }
  POINT cursor;
  if (!GetCursorPos(&cursor)) {
    result->Success(ResponseValue({"windowPositioningFailed", {}}));
    return;
  }
  HMONITOR monitor = MonitorFromPoint(cursor, MONITOR_DEFAULTTONEAREST);
  MONITORINFO monitor_info{sizeof(MONITORINFO)};
  if (monitor == nullptr || !GetMonitorInfo(monitor, &monitor_info)) {
    result->Success(ResponseValue({"windowPositioningFailed", {}}));
    return;
  }
  const UINT dpi = GetDpiForWindow(window_);
  const UINT effective_dpi = dpi == 0 ? 96 : dpi;
  const int width = MulDiv(static_cast<int>(DoubleArgument(arguments, "width", 760)),
                           effective_dpi, 96);
  const int height = MulDiv(static_cast<int>(DoubleArgument(arguments, "height", 720)),
                            effective_dpi, 96);
  const RECT work = monitor_info.rcWork;
  const int bounded_width = std::min<int>(
      width, static_cast<int>(work.right - work.left));
  const int bounded_height = std::min<int>(
      height, static_cast<int>(work.bottom - work.top));
  const int left = std::clamp(cursor.x + 16, work.left, work.right - bounded_width);
  const int top = std::clamp(cursor.y + 16, work.top, work.bottom - bounded_height);
  if (IsIconic(window_)) {
    ShowWindow(window_, SW_RESTORE);
  }
  if (!SetWindowPos(window_, HWND_TOP, left, top, bounded_width, bounded_height,
                    SWP_NOACTIVATE | SWP_SHOWWINDOW)) {
    result->Success(ResponseValue({"windowPositioningFailed", {}}));
    return;
  }
  ShowWindow(window_, SW_SHOWNOACTIVATE);
  result->Success(ResponseValue({"success", {}}));
}

void WindowsPlatformChannel::HidePanel(std::unique_ptr<MethodResult> result) {
  if (window_ == nullptr || !IsWindow(window_)) {
    result->Success(ResponseValue({"windowActivationFailed", {}}));
    return;
  }
  ShowWindow(window_, SW_MINIMIZE);
  result->Success(ResponseValue({"success", {}}));
}

void WindowsPlatformChannel::ActivateWindow(std::unique_ptr<MethodResult> result) {
  if (window_ == nullptr) {
    result->Success(ResponseValue({"windowActivationFailed", {}}));
    return;
  }
  const HWND foreground_window = GetForegroundWindow();
  const DWORD foreground_thread = foreground_window == nullptr
                                      ? 0
                                      : GetWindowThreadProcessId(
                                            foreground_window, nullptr);
  const DWORD current_thread = GetCurrentThreadId();
  const bool attached = foreground_thread != 0 &&
                        foreground_thread != current_thread &&
                        AttachThreadInput(current_thread, foreground_thread, TRUE);
  ShowWindow(window_, SW_RESTORE);
  BringWindowToTop(window_);
  const bool activated = SetForegroundWindow(window_) != FALSE;
  if (attached) {
    AttachThreadInput(current_thread, foreground_thread, FALSE);
  }
  if (!activated) {
    result->Success(ResponseValue({"windowActivationFailed", {}}));
    return;
  }
  SetFocus(window_);
  result->Success(ResponseValue({"success", {}}));
}
