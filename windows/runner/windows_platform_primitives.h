#ifndef RUNNER_WINDOWS_PLATFORM_PRIMITIVES_H_
#define RUNNER_WINDOWS_PLATFORM_PRIMITIVES_H_

#include <windows.h>

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <functional>
#include <limits>
#include <mutex>
#include <string>
#include <thread>
#include <utility>

namespace lingolens {

constexpr UINT kRequiredHotkeyModifiers = MOD_ALT | MOD_NOREPEAT;
constexpr UINT kRequiredHotkeyVirtualKey = 'S';

struct NativeCaptureResponse {
  std::string status;
  std::string text;
  DWORD error_code = 0;
  DWORD current_thread_id = 0;
  DWORD window_thread_id = 0;
  std::string cancellation_outcome;
  DWORD cancellation_error_code = 0;
};

inline bool CalculateNativeUiaTimeoutMilliseconds(
    std::chrono::steady_clock::time_point now,
    std::chrono::steady_clock::time_point deadline,
    DWORD* timeout_ms) {
  if (timeout_ms == nullptr || now >= deadline) {
    return false;
  }
  const auto remaining_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
      deadline - now);
  if (remaining_ms.count() <= 0) {
    *timeout_ms = 1;
    return true;
  }
  const auto max_timeout_ms = std::chrono::milliseconds(
      static_cast<std::chrono::milliseconds::rep>(
          std::numeric_limits<DWORD>::max()));
  *timeout_ms = remaining_ms >= max_timeout_ms
                    ? std::numeric_limits<DWORD>::max()
                    : static_cast<DWORD>(remaining_ms.count());
  return *timeout_ms > 0;
}

enum class HotkeyRegistrationStatus {
  success,
  hotkeyUnavailable,
  wrongWindowThread,
  registrationFailed,
};

inline HotkeyRegistrationStatus ClassifyHotkeyRegistration(
    DWORD current_thread_id, DWORD window_thread_id, DWORD error_code) {
  if (current_thread_id != window_thread_id ||
      error_code == ERROR_WINDOW_OF_OTHER_THREAD) {
    return HotkeyRegistrationStatus::wrongWindowThread;
  }
  if (error_code == ERROR_HOTKEY_ALREADY_REGISTERED) {
    return HotkeyRegistrationStatus::hotkeyUnavailable;
  }
  return HotkeyRegistrationStatus::registrationFailed;
}

enum class NativeCaptureTerminal { none, success, cancelled, timeout };

enum class NativeCallCancellationOutcome { notAttempted, succeeded, failed };

inline NativeCallCancellationOutcome ClassifyCallCancellationResult(
    HRESULT result) {
  return result == S_OK ? NativeCallCancellationOutcome::succeeded
                        : NativeCallCancellationOutcome::failed;
}

class NativeCaptureDeadlineWatchdog {
 public:
  using Clock = std::chrono::steady_clock;

  NativeCaptureDeadlineWatchdog() = default;
  ~NativeCaptureDeadlineWatchdog() { Shutdown(); }

  NativeCaptureDeadlineWatchdog(const NativeCaptureDeadlineWatchdog&) = delete;
  NativeCaptureDeadlineWatchdog& operator=(const NativeCaptureDeadlineWatchdog&) = delete;

  void Start(Clock::time_point deadline, std::function<void()> on_deadline) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (watchdog_.joinable()) {
      return;
    }
    deadline_ = deadline;
    on_deadline_ = std::move(on_deadline);
    worker_completed_ = false;
    cancel_requested_ = false;
    shutdown_requested_ = false;
    deadline_triggered_.store(false);
    watchdog_ = std::thread([this]() { WaitForDeadline(); });
  }

  void NotifyWorkerCompleted() {
    {
      std::lock_guard<std::mutex> lock(mutex_);
      worker_completed_ = true;
    }
    condition_.notify_all();
  }

  void RequestCancel() {
    {
      std::lock_guard<std::mutex> lock(mutex_);
      cancel_requested_ = true;
    }
    condition_.notify_all();
  }

  void RequestShutdown() {
    {
      std::lock_guard<std::mutex> lock(mutex_);
      shutdown_requested_ = true;
    }
    condition_.notify_all();
  }

  void Shutdown() {
    RequestShutdown();
    if (watchdog_.joinable()) {
      watchdog_.join();
    }
  }

  bool deadline_triggered() const { return deadline_triggered_.load(); }

 private:
  void WaitForDeadline() {
    std::unique_lock<std::mutex> lock(mutex_);
    const bool stopped = condition_.wait_until(
        lock, deadline_, [this]() {
          return worker_completed_ || cancel_requested_ || shutdown_requested_;
        });
    if (stopped || worker_completed_ || cancel_requested_ || shutdown_requested_) {
      return;
    }
    deadline_triggered_.store(true);
    auto on_deadline = on_deadline_;
    lock.unlock();
    if (on_deadline) {
      on_deadline();
    }
  }

  mutable std::mutex mutex_;
  std::condition_variable condition_;
  Clock::time_point deadline_ = Clock::now();
  std::function<void()> on_deadline_;
  bool worker_completed_ = false;
  bool cancel_requested_ = false;
  bool shutdown_requested_ = false;
  std::atomic<bool> deadline_triggered_{false};
  std::thread watchdog_;
};

class NativeCaptureLifecycle {
 public:
  explicit NativeCaptureLifecycle(
      std::chrono::steady_clock::time_point deadline)
      : deadline_(deadline) {}

  bool CanStartSideEffect(std::chrono::steady_clock::time_point now) const {
    return !cancel_requested_.load() && !timeout_requested_.load() &&
           now < deadline_;
  }

  void MarkCopyStarted() { cleanup_required_.store(true); }

  void MarkCleanupFinished() {
    cleanup_required_.store(false);
    if (cancel_requested_.load()) {
      TryTerminalIfCleanupComplete(NativeCaptureTerminal::cancelled);
    } else if (timeout_requested_.load()) {
      TryTerminalIfCleanupComplete(NativeCaptureTerminal::timeout);
    }
  }

  void RequestCancel() {
    cancel_requested_.store(true);
    TryTerminalIfCleanupComplete(NativeCaptureTerminal::cancelled);
  }

  void RequestTimeout() {
    timeout_requested_.store(true);
    TryTerminalIfCleanupComplete(NativeCaptureTerminal::timeout);
  }

  NativeCaptureTerminal WorkerTerminal() const {
    if (cancel_requested_.load()) {
      return NativeCaptureTerminal::cancelled;
    }
    if (timeout_requested_.load()) {
      return NativeCaptureTerminal::timeout;
    }
    return NativeCaptureTerminal::success;
  }

  bool IsCancelled() const { return cancel_requested_.load(); }

  bool IsTimedOut() const { return timeout_requested_.load(); }

  bool CleanupRequired() const { return cleanup_required_.load(); }

  std::chrono::steady_clock::time_point deadline() const { return deadline_; }

  bool TryTerminal(NativeCaptureTerminal terminal) {
    int expected = static_cast<int>(NativeCaptureTerminal::none);
    return terminal_.compare_exchange_strong(expected,
                                             static_cast<int>(terminal));
  }

  NativeCaptureTerminal terminal() const {
    return static_cast<NativeCaptureTerminal>(terminal_.load());
  }

 private:
  void TryTerminalIfCleanupComplete(NativeCaptureTerminal terminal) {
    if (!cleanup_required_.load()) {
      TryTerminal(terminal);
    }
  }

  const std::chrono::steady_clock::time_point deadline_;
  std::atomic<bool> cancel_requested_{false};
  std::atomic<bool> timeout_requested_{false};
  std::atomic<bool> cleanup_required_{false};
  std::atomic<int> terminal_{static_cast<int>(NativeCaptureTerminal::none)};
};

enum class HotkeyReleaseOutcome { released, captureTimeout, cancelled };

struct HotkeyReleaseHooks {
  using Clock = std::chrono::steady_clock;

  std::function<bool(int)> key_down;
  std::function<void()> wait_for_next_observation;
  std::function<bool()> cancelled;
  std::function<bool()> generation_current;
  std::function<Clock::time_point()> now;
};

inline HotkeyReleaseOutcome WaitForHotkeyRelease(
    HotkeyReleaseHooks hooks,
    HotkeyReleaseHooks::Clock::time_point deadline) {
  while (true) {
    if (hooks.cancelled() || !hooks.generation_current()) {
      return HotkeyReleaseOutcome::cancelled;
    }
    if (hooks.now() >= deadline) {
      return HotkeyReleaseOutcome::captureTimeout;
    }
    if (!hooks.key_down(VK_MENU) && !hooks.key_down('S')) {
      return HotkeyReleaseOutcome::released;
    }
    hooks.wait_for_next_observation();
  }
}

}

#endif
