#ifndef RUNNER_WINDOWS_CLIPBOARD_STATE_MACHINE_H_
#define RUNNER_WINDOWS_CLIPBOARD_STATE_MACHINE_H_

#include "windows_platform_primitives.h"

#include <functional>
#include <utility>

namespace lingolens {

struct ClipboardFallbackHooks {
  using Clock = std::chrono::steady_clock;

  std::function<bool()> snapshot;
  std::function<bool()> send_copy;
  std::function<DWORD()> sequence;
  std::function<NativeCaptureResponse()> read_text;
  std::function<bool(DWORD, Clock::time_point)> restore_and_verify;
  std::function<void()> wait_for_next_observation;
  std::function<bool()> cancelled;
  std::function<bool()> timed_out;
  std::function<bool()> generation_current;
  std::function<bool(Clock::time_point)> may_start_side_effect;
  std::function<void()> mark_copy_started;
  std::function<void()> mark_cleanup_finished;
  std::function<void()> request_cancel;
  std::function<void()> request_timeout;
  std::function<Clock::time_point()> now;
};

class ClipboardFallbackStateMachine {
 public:
  using Clock = ClipboardFallbackHooks::Clock;

  static NativeCaptureResponse Run(
      ClipboardFallbackHooks hooks,
      ClipboardFallbackHooks::Clock::time_point capture_deadline,
      Clock::duration cleanup_budget) {
    const auto current_time = [&]() {
      return hooks.now == nullptr ? Clock::now() : hooks.now();
    };
    const auto interrupted_status = [&]() {
      return hooks.cancelled() || !hooks.generation_current()
                 ? NativeCaptureResponse{"cancelled", {}}
                 : NativeCaptureResponse{"captureTimeout", {}};
    };

    if (!hooks.may_start_side_effect(current_time()) ||
        current_time() >= capture_deadline) {
      if (!hooks.cancelled()) {
        hooks.request_timeout();
      } else {
        hooks.request_cancel();
      }
      return interrupted_status();
    }
    if (!hooks.snapshot()) {
      return {"clipboardUnavailable", {}};
    }

    const DWORD original_sequence = hooks.sequence();
    if (!hooks.may_start_side_effect(current_time()) ||
        current_time() >= capture_deadline) {
      hooks.request_timeout();
      return interrupted_status();
    }
    if (!hooks.send_copy()) {
      return {"clipboardUnavailable", {}};
    }
    hooks.mark_copy_started();

    const auto cleanup_deadline = capture_deadline + cleanup_budget;
    DWORD produced_sequence = original_sequence;
    bool produced = false;
    bool capture_timed_out = hooks.timed_out != nullptr && hooks.timed_out();

    const auto observe_sequence = [&]() {
      const DWORD observed_sequence = hooks.sequence();
      if (observed_sequence != original_sequence) {
        produced_sequence = observed_sequence;
        produced = true;
      }
    };

    while (!produced && !capture_timed_out && !hooks.cancelled() &&
           current_time() < capture_deadline) {
      observe_sequence();
      if (produced) {
        break;
      }
      if (!hooks.generation_current()) {
        hooks.request_cancel();
      }
      hooks.wait_for_next_observation();
    }

    if (!produced && current_time() >= capture_deadline) {
      capture_timed_out = true;
      hooks.request_timeout();
    }

    while (!produced && current_time() < cleanup_deadline) {
      observe_sequence();
      if (produced) {
        break;
      }
      if (!hooks.generation_current()) {
        hooks.request_cancel();
      }
      hooks.wait_for_next_observation();
    }

    if (!produced) {
      hooks.mark_cleanup_finished();
      return interrupted_status();
    }

    NativeCaptureResponse response{"clipboardUnchanged", {}};
    if (!capture_timed_out && current_time() < capture_deadline &&
        !hooks.cancelled() && hooks.generation_current() &&
        hooks.may_start_side_effect(current_time())) {
      response = hooks.read_text();
    }

    const DWORD before_restore = hooks.sequence();
    if (before_restore == produced_sequence) {
      if (!hooks.restore_and_verify(produced_sequence, cleanup_deadline)) {
        response = {"clipboardRestoreFailed", {}};
      }
    } else {
      response = {"clipboardConcurrentModification", {}};
    }
    hooks.mark_cleanup_finished();

    if (response.status == "clipboardRestoreFailed" ||
        response.status == "clipboardConcurrentModification") {
      return response;
    }
    if (hooks.cancelled() || !hooks.generation_current()) {
      return {"cancelled", {}};
    }
    if (capture_timed_out) {
      return {"captureTimeout", {}};
    }
    return response;
  }

  static NativeCaptureResponse Run(
      ClipboardFallbackHooks hooks,
      ClipboardFallbackHooks::Clock::time_point capture_deadline) {
    return Run(std::move(hooks), capture_deadline, std::chrono::milliseconds(750));
  }
};

}

#endif
