#include <cassert>
#include <chrono>
#include <limits>
#include <string>
#include <thread>
#include <utility>

#include "../runner/windows_clipboard_state_machine.h"
#include "../runner/windows_platform_primitives.h"

namespace {

struct FakeClipboard {
  using Clock = lingolens::ClipboardFallbackHooks::Clock;

  Clock::time_point now = Clock::time_point{};
  DWORD original_sequence = 10;
  DWORD produced_sequence = 11;
  int sequence_change_at_ms = -1;
  int waits = 0;
  int wait_step_ms = 2;
  int restore_retry_count = 1;
  int restore_attempts = 0;
  bool cancel_after_copy = false;
  bool timeout_after_copy = false;
  bool timeout_without_sequence = false;
  bool third_party_after_produced = false;
  bool restore_succeeds = true;
  bool copied = false;
  bool read = false;
  bool restored = false;
  bool cleanup_finished = false;
  bool cancelled = false;
  bool timed_out = false;
  bool generation_current = true;
  bool produced_observed = false;
  bool cleanup_deadline_received = false;
  int terminal_responses = 0;
};

struct FakeHotkeyRelease {
  using Clock = std::chrono::steady_clock;

  Clock::time_point now = Clock::time_point{};
  int wait_step_ms = 2;
  int waits = 0;
  int release_alt_after_waits = -1;
  int release_s_after_waits = -1;
  int cancel_after_waits = -1;
  int stale_after_waits = -1;
  bool alt_down = false;
  bool s_down = false;
  bool cancelled = false;
  bool generation_current = true;
  bool copy_side_effect_called = false;
};

lingolens::HotkeyReleaseOutcome RunFakeHotkeyRelease(
    FakeHotkeyRelease& fake, std::chrono::milliseconds budget) {
  const auto deadline = fake.now + budget;
  lingolens::HotkeyReleaseHooks hooks;
  hooks.key_down = [&fake](int virtual_key) {
    if (virtual_key == VK_MENU) {
      return fake.alt_down;
    }
    if (virtual_key == 'S') {
      return fake.s_down;
    }
    assert(false);
    return false;
  };
  hooks.wait_for_next_observation = [&fake]() {
    ++fake.waits;
    fake.now += std::chrono::milliseconds(fake.wait_step_ms);
    if (fake.release_alt_after_waits >= 0 &&
        fake.waits >= fake.release_alt_after_waits) {
      fake.alt_down = false;
    }
    if (fake.release_s_after_waits >= 0 &&
        fake.waits >= fake.release_s_after_waits) {
      fake.s_down = false;
    }
    if (fake.cancel_after_waits >= 0 &&
        fake.waits >= fake.cancel_after_waits) {
      fake.cancelled = true;
    }
    if (fake.stale_after_waits >= 0 &&
        fake.waits >= fake.stale_after_waits) {
      fake.generation_current = false;
    }
  };
  hooks.cancelled = [&fake]() { return fake.cancelled; };
  hooks.generation_current = [&fake]() { return fake.generation_current; };
  hooks.now = [&fake]() { return fake.now; };

  const auto outcome =
      lingolens::WaitForHotkeyRelease(std::move(hooks), deadline);
  if (outcome == lingolens::HotkeyReleaseOutcome::released) {
    fake.copy_side_effect_called = true;
  }
  return outcome;
}

lingolens::NativeCaptureResponse RunFakeClipboard(FakeClipboard& fake,
                                                   std::chrono::milliseconds capture_budget,
                                                   std::chrono::milliseconds cleanup_budget =
                                                       std::chrono::milliseconds(750)) {
  fake.now = FakeClipboard::Clock::time_point{};
  const auto capture_deadline = fake.now + capture_budget;
  lingolens::ClipboardFallbackHooks hooks;
  hooks.snapshot = []() { return true; };
  hooks.send_copy = [&fake]() {
    fake.copied = true;
    if (fake.cancel_after_copy) {
      fake.cancelled = true;
      fake.generation_current = false;
    }
    if (fake.timeout_after_copy) {
      fake.timed_out = true;
    }
    return true;
  };
  hooks.sequence = [&fake]() {
    if (fake.timeout_without_sequence) {
      return fake.original_sequence;
    }
    const auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
        fake.now - FakeClipboard::Clock::time_point{});
    if (fake.third_party_after_produced && fake.produced_observed) {
        return fake.produced_sequence + 1;
    }
    if (fake.sequence_change_at_ms >= 0 &&
        elapsed.count() >= fake.sequence_change_at_ms) {
      fake.produced_observed = true;
      return fake.produced_sequence;
    }
    return fake.original_sequence;
  };
  hooks.read_text = [&fake]() {
    fake.read = true;
    return lingolens::NativeCaptureResponse{"success", "synthetic-selected"};
  };
  hooks.wait_for_next_observation = [&fake]() {
    ++fake.waits;
    fake.now += std::chrono::milliseconds(fake.wait_step_ms);
  };
  hooks.cancelled = [&fake]() { return fake.cancelled; };
  hooks.timed_out = [&fake]() { return fake.timed_out; };
  hooks.generation_current = [&fake]() { return fake.generation_current; };
  hooks.may_start_side_effect = [&fake](auto) {
    return !fake.cancelled && !fake.timed_out && fake.generation_current;
  };
  hooks.mark_copy_started = []() {};
  hooks.mark_cleanup_finished = [&fake]() {
    fake.cleanup_finished = true;
    ++fake.terminal_responses;
  };
  hooks.request_cancel = [&fake]() { fake.cancelled = true; };
  hooks.request_timeout = [&fake]() { fake.timed_out = true; };
  hooks.now = [&fake]() { return fake.now; };
  hooks.restore_and_verify = [&fake](DWORD expected_sequence,
                                     FakeClipboard::Clock::time_point deadline) {
    fake.cleanup_deadline_received = deadline > fake.now;
    fake.restored = expected_sequence == fake.produced_sequence;
    for (int attempt = 0; attempt < fake.restore_retry_count; ++attempt) {
      ++fake.restore_attempts;
      fake.now += std::chrono::milliseconds(3);
    }
    return fake.restored && fake.restore_succeeds && fake.now <= deadline;
  };
  return lingolens::ClipboardFallbackStateMachine::Run(
      std::move(hooks), capture_deadline, cleanup_budget);
}

void RunWatchdogTests() {
  using Watchdog = lingolens::NativeCaptureDeadlineWatchdog;
  using Outcome = lingolens::NativeCallCancellationOutcome;

  int completion_callbacks = 0;
  Watchdog completion_watchdog;
  completion_watchdog.Start(Watchdog::Clock::now() + std::chrono::milliseconds(100),
                            [&completion_callbacks]() { ++completion_callbacks; });
  completion_watchdog.NotifyWorkerCompleted();
  completion_watchdog.Shutdown();
  assert(completion_callbacks == 0);

  int timeout_callbacks = 0;
  Watchdog timeout_watchdog;
  timeout_watchdog.Start(Watchdog::Clock::now() + std::chrono::milliseconds(10),
                         [&timeout_callbacks]() { ++timeout_callbacks; });
  std::this_thread::sleep_for(std::chrono::milliseconds(25));
  timeout_watchdog.Shutdown();
  assert(timeout_callbacks == 1);
  assert(timeout_watchdog.deadline_triggered());

  int cancel_callbacks = 0;
  const auto cancel_start = Watchdog::Clock::now();
  Watchdog cancel_watchdog;
  cancel_watchdog.Start(cancel_start + std::chrono::seconds(5),
                        [&cancel_callbacks]() { ++cancel_callbacks; });
  std::this_thread::sleep_for(std::chrono::milliseconds(5));
  cancel_watchdog.RequestCancel();
  cancel_watchdog.Shutdown();
  assert(cancel_callbacks == 0);
  assert(Watchdog::Clock::now() - cancel_start < std::chrono::seconds(1));

  int shutdown_callbacks = 0;
  Watchdog shutdown_watchdog;
  shutdown_watchdog.Start(Watchdog::Clock::now() + std::chrono::seconds(5),
                          [&shutdown_callbacks]() { ++shutdown_callbacks; });
  shutdown_watchdog.RequestShutdown();
  shutdown_watchdog.Shutdown();
  assert(shutdown_callbacks == 0);

  int race_callbacks = 0;
  Watchdog race_watchdog;
  race_watchdog.Start(Watchdog::Clock::now() + std::chrono::milliseconds(10),
                      [&race_callbacks]() { ++race_callbacks; });
  std::this_thread::sleep_for(std::chrono::milliseconds(9));
  race_watchdog.RequestCancel();
  race_watchdog.Shutdown();
  assert(race_callbacks <= 1);

  assert(lingolens::ClassifyCallCancellationResult(S_OK) == Outcome::succeeded);
  assert(lingolens::ClassifyCallCancellationResult(E_ACCESSDENIED) == Outcome::failed);

  int destruction_callbacks = 0;
  {
    Watchdog destruction_watchdog;
    destruction_watchdog.Start(Watchdog::Clock::now() + std::chrono::seconds(5),
                               [&destruction_callbacks]() { ++destruction_callbacks; });
  }
  assert(destruction_callbacks == 0);
}

}

int main() {
  using namespace std::chrono_literals;
  using lingolens::ClassifyHotkeyRegistration;
  using lingolens::HotkeyRegistrationStatus;
  using lingolens::NativeCaptureLifecycle;
  using lingolens::NativeCaptureTerminal;

  FakeHotkeyRelease already_released;
  assert(RunFakeHotkeyRelease(already_released, 20ms) ==
         lingolens::HotkeyReleaseOutcome::released);
  assert(already_released.waits == 0);
  assert(already_released.copy_side_effect_called);

  FakeHotkeyRelease delayed_alt;
  delayed_alt.alt_down = true;
  delayed_alt.release_alt_after_waits = 3;
  assert(RunFakeHotkeyRelease(delayed_alt, 20ms) ==
         lingolens::HotkeyReleaseOutcome::released);
  assert(delayed_alt.waits == 3);

  FakeHotkeyRelease delayed_s;
  delayed_s.alt_down = true;
  delayed_s.s_down = true;
  delayed_s.release_alt_after_waits = 2;
  delayed_s.release_s_after_waits = 4;
  assert(RunFakeHotkeyRelease(delayed_s, 20ms) ==
         lingolens::HotkeyReleaseOutcome::released);
  assert(delayed_s.waits == 4);

  FakeHotkeyRelease deadline_while_alt;
  deadline_while_alt.alt_down = true;
  assert(RunFakeHotkeyRelease(deadline_while_alt, 5ms) ==
         lingolens::HotkeyReleaseOutcome::captureTimeout);
  assert(!deadline_while_alt.copy_side_effect_called);

  FakeHotkeyRelease cancelled_wait;
  cancelled_wait.alt_down = true;
  cancelled_wait.cancel_after_waits = 2;
  assert(RunFakeHotkeyRelease(cancelled_wait, 20ms) ==
         lingolens::HotkeyReleaseOutcome::cancelled);
  assert(!cancelled_wait.copy_side_effect_called);

  FakeHotkeyRelease stale_wait;
  stale_wait.s_down = true;
  stale_wait.stale_after_waits = 2;
  assert(RunFakeHotkeyRelease(stale_wait, 20ms) ==
         lingolens::HotkeyReleaseOutcome::cancelled);
  assert(!stale_wait.copy_side_effect_called);

  FakeHotkeyRelease side_effect_gate;
  side_effect_gate.alt_down = true;
  side_effect_gate.s_down = true;
  side_effect_gate.release_alt_after_waits = 2;
  side_effect_gate.release_s_after_waits = 4;
  assert(RunFakeHotkeyRelease(side_effect_gate, 20ms) ==
         lingolens::HotkeyReleaseOutcome::released);
  assert(side_effect_gate.waits == 4);
  assert(!side_effect_gate.alt_down);
  assert(!side_effect_gate.s_down);
  assert(side_effect_gate.copy_side_effect_called);

  RunWatchdogTests();

  using Clock = std::chrono::steady_clock;
  const auto helper_now = Clock::time_point{};
  DWORD uia_timeout_ms = 0;
  assert(lingolens::CalculateNativeUiaTimeoutMilliseconds(
      helper_now, helper_now + 1500ms, &uia_timeout_ms));
  assert(uia_timeout_ms == 1500);
  assert(lingolens::CalculateNativeUiaTimeoutMilliseconds(
      helper_now, helper_now + std::chrono::microseconds(500),
      &uia_timeout_ms));
  assert(uia_timeout_ms == 1);
  assert(!lingolens::CalculateNativeUiaTimeoutMilliseconds(
      helper_now, helper_now, &uia_timeout_ms));
  assert(!lingolens::CalculateNativeUiaTimeoutMilliseconds(
      helper_now, helper_now - 1ms, &uia_timeout_ms));
  assert(lingolens::CalculateNativeUiaTimeoutMilliseconds(
      helper_now, Clock::time_point::max(), &uia_timeout_ms));
  assert(uia_timeout_ms == std::numeric_limits<DWORD>::max());

  assert(ClassifyHotkeyRegistration(10, 10, ERROR_HOTKEY_ALREADY_REGISTERED) ==
         HotkeyRegistrationStatus::hotkeyUnavailable);
  assert(ClassifyHotkeyRegistration(10, 10, ERROR_WINDOW_OF_OTHER_THREAD) ==
         HotkeyRegistrationStatus::wrongWindowThread);
  assert(ClassifyHotkeyRegistration(10, 10, ERROR_ACCESS_DENIED) ==
         HotkeyRegistrationStatus::registrationFailed);

  const auto deadline = std::chrono::steady_clock::now() + 1s;
  NativeCaptureLifecycle cancelled_before_copy(deadline);
  assert(cancelled_before_copy.CanStartSideEffect(
      std::chrono::steady_clock::now()));
  cancelled_before_copy.RequestCancel();
  assert(!cancelled_before_copy.CanStartSideEffect(
      std::chrono::steady_clock::now()));
  assert(cancelled_before_copy.terminal() == NativeCaptureTerminal::cancelled);
  assert(!cancelled_before_copy.TryTerminal(NativeCaptureTerminal::success));

  NativeCaptureLifecycle cancelled_after_copy(deadline);
  cancelled_after_copy.MarkCopyStarted();
  cancelled_after_copy.RequestCancel();
  assert(cancelled_after_copy.terminal() == NativeCaptureTerminal::none);
  cancelled_after_copy.MarkCleanupFinished();
  assert(cancelled_after_copy.terminal() == NativeCaptureTerminal::cancelled);

  NativeCaptureLifecycle timed_out_before_copy(deadline);
  timed_out_before_copy.RequestTimeout();
  assert(timed_out_before_copy.terminal() == NativeCaptureTerminal::timeout);
  assert(!timed_out_before_copy.CanStartSideEffect(
      std::chrono::steady_clock::now()));

  NativeCaptureLifecycle timed_out_after_copy(deadline);
  timed_out_after_copy.MarkCopyStarted();
  timed_out_after_copy.RequestTimeout();
  assert(timed_out_after_copy.terminal() == NativeCaptureTerminal::none);
  timed_out_after_copy.MarkCleanupFinished();
  assert(timed_out_after_copy.terminal() == NativeCaptureTerminal::timeout);

  FakeClipboard cancelled_after_copy_fake;
  cancelled_after_copy_fake.cancel_after_copy = true;
  cancelled_after_copy_fake.sequence_change_at_ms = 4;
  const auto cancelled_result =
      RunFakeClipboard(cancelled_after_copy_fake, 100ms);
  assert(cancelled_result.status == "cancelled");
  assert(cancelled_after_copy_fake.copied);
  assert(cancelled_after_copy_fake.waits >= 2);
  assert(cancelled_after_copy_fake.restored);
  assert(cancelled_after_copy_fake.cleanup_finished);
  assert(!cancelled_after_copy_fake.read);

  FakeClipboard cancellation_cleanup_fake;
  cancellation_cleanup_fake.cancel_after_copy = true;
  cancellation_cleanup_fake.sequence_change_at_ms = 12;
  const auto cancellation_cleanup_result =
      RunFakeClipboard(cancellation_cleanup_fake, 10ms, 20ms);
  assert(cancellation_cleanup_result.status == "cancelled");
  assert(cancellation_cleanup_fake.copied);
  assert(!cancellation_cleanup_fake.read);
  assert(cancellation_cleanup_fake.restored);
  assert(cancellation_cleanup_fake.cleanup_finished);
  assert(cancellation_cleanup_fake.terminal_responses == 1);

  FakeClipboard timeout_after_copy_fake;
  timeout_after_copy_fake.timeout_after_copy = true;
  timeout_after_copy_fake.sequence_change_at_ms = 4;
  const auto timeout_result = RunFakeClipboard(timeout_after_copy_fake, 20ms, 20ms);
  assert(timeout_result.status == "captureTimeout");
  assert(timeout_after_copy_fake.copied);
  assert(!timeout_after_copy_fake.read);
  assert(timeout_after_copy_fake.restored);
  assert(timeout_after_copy_fake.cleanup_finished);

  FakeClipboard production_ratio_fake;
  production_ratio_fake.sequence_change_at_ms = 1000;
  const auto production_ratio_result =
      RunFakeClipboard(production_ratio_fake, 1500ms, 750ms);
  assert(production_ratio_result.status == "success");
  assert(production_ratio_fake.read);
  assert(production_ratio_fake.restored);
  assert(production_ratio_fake.restore_attempts == 1);
  assert(production_ratio_fake.cleanup_deadline_received);
  assert(production_ratio_fake.terminal_responses == 1);

  FakeClipboard late_sequence_fake;
  late_sequence_fake.sequence_change_at_ms = 1600;
  const auto late_sequence_result =
      RunFakeClipboard(late_sequence_fake, 1500ms, 750ms);
  assert(late_sequence_result.status == "captureTimeout");
  assert(!late_sequence_fake.read);
  assert(late_sequence_fake.restored);
  assert(late_sequence_fake.cleanup_deadline_received);
  assert(late_sequence_fake.terminal_responses == 1);

  FakeClipboard delayed_sequence_fake;
  delayed_sequence_fake.sequence_change_at_ms = 2;
  const auto delayed_result = RunFakeClipboard(delayed_sequence_fake, 100ms);
  assert(delayed_result.status == "success");
  assert(delayed_result.text == "synthetic-selected");
  assert(delayed_sequence_fake.read);
  assert(delayed_sequence_fake.restored);
  assert(delayed_sequence_fake.cleanup_finished);

  FakeClipboard third_party_fake;
  third_party_fake.sequence_change_at_ms = 4;
  third_party_fake.third_party_after_produced = true;
  const auto third_party_result = RunFakeClipboard(third_party_fake, 100ms);
  assert(third_party_result.status == "clipboardConcurrentModification");
  assert(!third_party_fake.restored);
  assert(third_party_fake.cleanup_finished);

  FakeClipboard restore_failure_fake;
  restore_failure_fake.sequence_change_at_ms = 4;
  restore_failure_fake.restore_succeeds = false;
  const auto restore_failure_result =
      RunFakeClipboard(restore_failure_fake, 100ms);
  assert(restore_failure_result.status == "clipboardRestoreFailed");
  assert(restore_failure_fake.cleanup_finished);

  FakeClipboard shutdown_after_copy_fake;
  shutdown_after_copy_fake.cancel_after_copy = true;
  shutdown_after_copy_fake.sequence_change_at_ms = 4;
  const auto shutdown_result = RunFakeClipboard(shutdown_after_copy_fake, 100ms);
  assert(shutdown_result.status == "cancelled");
  assert(shutdown_after_copy_fake.restored);
  assert(shutdown_after_copy_fake.cleanup_finished);

  FakeClipboard just_before_deadline_fake;
  just_before_deadline_fake.sequence_change_at_ms = 8;
  const auto just_before_deadline_result =
      RunFakeClipboard(just_before_deadline_fake, 10ms, 20ms);
  assert(just_before_deadline_result.status == "success");
  assert(just_before_deadline_fake.read);

  FakeClipboard after_capture_deadline_fake;
  after_capture_deadline_fake.sequence_change_at_ms = 12;
  const auto after_capture_deadline_result =
      RunFakeClipboard(after_capture_deadline_fake, 10ms, 20ms);
  assert(after_capture_deadline_result.status == "captureTimeout");
  assert(!after_capture_deadline_fake.read);
  assert(after_capture_deadline_fake.restored);
  assert(after_capture_deadline_fake.cleanup_deadline_received);

  FakeClipboard retry_restore_fake;
  retry_restore_fake.sequence_change_at_ms = 12;
  retry_restore_fake.restore_retry_count = 3;
  const auto retry_restore_result =
      RunFakeClipboard(retry_restore_fake, 10ms, 30ms);
  assert(retry_restore_result.status == "captureTimeout");
  assert(retry_restore_fake.restore_attempts == 3);
  assert(retry_restore_fake.restored);

  FakeClipboard cleanup_expired_fake;
  const auto cleanup_expired_result =
      RunFakeClipboard(cleanup_expired_fake, 10ms, 10ms);
  assert(cleanup_expired_result.status == "captureTimeout");
  assert(cleanup_expired_fake.cleanup_finished);
  assert(!cleanup_expired_fake.read);

  assert(cancelled_after_copy_fake.terminal_responses == 1);
  assert(timeout_after_copy_fake.terminal_responses == 1);
  assert(after_capture_deadline_fake.terminal_responses == 1);

  return 0;
}
