# T-12R Windows Manual Smoke

## Required scenarios

1. Launch the final `lingolens.exe`。
2. Register `Alt + S` and verify registration-success UI。
3. Capture selected text without auto-submit。
4. Verify panel show and activation ordering；failed activation must preserve draft and
   must not request focus。
5. Verify cancellation／timeout cleanup and clipboard restoration。
6. Relaunch and verify no stale registration or detached worker remains。

Task: T-12R Windows manual smoke
Command: final disposable `build/windows/x64/runner/Release/lingolens.exe` launch probe；human Alt+S interaction was unavailable in this tool session
Working directory: Windows host
Result: `BLOCKED`
Observed: process `lingolens.exe` launched and was responsive for 3 seconds；it was then stopped as the process started by the probe。
Generated artifacts: screenshots and raw machine logs are not committed；only sanitized result belongs here
Limitations: must not claim `PASS` from native harness alone；host hotkey ownership may produce `T-12R_BLOCKED_ENVIRONMENT_ALT_S_ALREADY_REGISTERED`。
