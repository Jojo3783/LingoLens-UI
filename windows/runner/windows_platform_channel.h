#ifndef RUNNER_WINDOWS_PLATFORM_CHANNEL_H_
#define RUNNER_WINDOWS_PLATFORM_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/flutter_engine.h>
#include <flutter/method_channel.h>
#include <flutter/method_call.h>
#include <flutter/method_result.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <atomic>
#include <cstdint>
#include <functional>
#include <memory>
#include <thread>
#include <vector>

#include "windows_platform_primitives.h"

class WindowsPlatformChannel {
 public:
  WindowsPlatformChannel(flutter::FlutterEngine* engine, HWND window);
  ~WindowsPlatformChannel();

  WindowsPlatformChannel(const WindowsPlatformChannel&) = delete;
  WindowsPlatformChannel& operator=(const WindowsPlatformChannel&) = delete;

  bool HandleWindowMessage(UINT message, WPARAM wparam, LPARAM lparam);

 private:
  using EncodableValue = flutter::EncodableValue;
  using MethodResult = flutter::MethodResult<EncodableValue>;

  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue>& call,
      std::unique_ptr<MethodResult> result);
  void RegisterHotkey(std::unique_ptr<MethodResult> result);
  void UnregisterHotkey(std::unique_ptr<MethodResult> result);
  void CancelCapture(std::unique_ptr<MethodResult> result);
  void CaptureSelectedText(
      const flutter::EncodableValue* arguments,
      std::unique_ptr<MethodResult> result);
  void CaptureClipboardFallback(
      const flutter::EncodableValue* arguments,
      std::unique_ptr<MethodResult> result);
  void ShowPanel(const flutter::EncodableValue* arguments,
                 std::unique_ptr<MethodResult> result);
  void HidePanel(std::unique_ptr<MethodResult> result);
  void ActivateWindow(std::unique_ptr<MethodResult> result);
  void RegisterHotkeyOnOwnerThread(std::unique_ptr<MethodResult> result);
  void UnregisterHotkeyOnOwnerThread(std::unique_ptr<MethodResult> result);
  void StartCapture(
      std::function<lingolens::NativeCaptureResponse(
          std::shared_ptr<lingolens::NativeCaptureLifecycle>,
          std::atomic<DWORD>*,
          std::atomic<bool>*,
          std::atomic<bool>*)> work,
      int timeout_ms,
      std::unique_ptr<MethodResult> result);
  void CompleteCapture(void* operation);
  void CancelActiveCaptures();

  struct NativeCaptureOperation;
  struct HotkeyRequest;

  HWND window_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;
  std::shared_ptr<std::atomic<std::uint64_t>> capture_generation_ =
      std::make_shared<std::atomic<std::uint64_t>>(0);
  std::vector<std::shared_ptr<NativeCaptureOperation>> capture_operations_;
  bool hotkey_registered_ = false;
  bool shutting_down_ = false;
};

#endif
