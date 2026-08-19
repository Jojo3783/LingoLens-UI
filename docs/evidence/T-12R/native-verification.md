# T-12R Windows Native Verification

## Native harness command record

Task: T-12R Windows native lifecycle
Command: `VsDevCmd.bat -arch=x64 -host_arch=x64 && cmake -G Ninja -S windows/test -B build/native-harness-final && cmake --build build/native-harness-final && build/native-harness-final/lingolens_native_platform_harness.exe`
Working directory: disposable clone under `D:\\GitHub\\workspace\\lingolens-t12r-final4`
Start time: `2026-07-29`
End time: `2026-07-29`
Exit code: `0`
Result: `PASS`
Relevant stdout: CMake configured、compiled and linked the native harness；`HARNESS_PRESENT` confirmed the executable。
Relevant stderr: MSVC include tracing only；no compiler error。
Generated artifacts: disposable `build/native-harness-final/`；not committed
Git status before: clean disposable clone
Git status after: generated build output remained only in disposable clone
Limitations: this is deterministic native harness coverage，not a replacement for manual hotkey registration and UI Automation smoke。

## Covered boundaries

- Required registration contract is `Alt + S` with `MOD_NOREPEAT`。
- Registration and unregister messages are dispatched to the window owner thread。
- Capture work is owned by a `NativeCaptureOperation` and has no detached worker。
- Completion is posted back to the owner window and the worker is joined before the
  operation is released。
- UI Automation and clipboard failures map to typed platform statuses without raw
  input or secret logging。
- Previous T-12R harness evidence did not prove post-Copy cleanup after cancellation
  or timeout。Actual cleanup state-machine coverage is now recorded in
  `docs/evidence/T-12R2/native-state-machine.md`。

## Environment note

The Visual Studio generator path previously hit the host Windows SDK
`GetLatestSDKTargetPlatformVersion` error. Ninja through `VsDevCmd.bat` was used as
the successful native verification path；this is recorded as an environment
limitation，not suppressed as a product result。
