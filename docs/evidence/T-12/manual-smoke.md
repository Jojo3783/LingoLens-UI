# T-12 Manual Windows Smoke

## Required scenario

Required default hotkey：`Ctrl+Alt+Space`。

Synthetic text：`T12 synthetic selected text`。

## Host evidence

在 LingoLens 啟動前，使用另一個 window probe 註冊同一組 hotkey：

```text
ProbeRegisterHotKeyBeforeLingoLens: False
ProbeLastError: 1408
SameHotkey: Ctrl+Alt+Space
```

`1408` 對應既有 global hotkey owner。LingoLens 因此不能在此 host 上證明
registration-success flow；依規格不得移除或竄改外部 owner，也不得將其他 hotkey
冒充成 required default。

## Observed results

| Scenario | Result | Evidence |
|---|---|---|
| LingoLens launches with required hotkey conflict | `PASS` | [manual-hotkey-conflict.png](manual-hotkey-conflict.png) |
| Typed hotkey-unavailable state keeps manual input available | `UNVERIFIED_IN_SCREENSHOT` | UI screenshot shows manual input; typed state requires a later clean-owner rerun |
| Required registration-success smoke | `BLOCKED_ENVIRONMENT` | baseline `RegisterHotKey` probe returned `False`, error `1408` |
| Selected text via required hotkey | `NOT_RUN` | blocked by pre-existing owner |
| Panel activation after required hotkey | `NOT_RUN` | blocked by pre-existing owner |
| Escape dismissal | `PASS` | widget regression test |
| Multi-monitor manual verification | `NOT_RUN` | deterministic geometry tests cover clamp; no topology claim |
| Relaunch and re-register | `NOT_RUN` | required hotkey owner remained occupied |

Diagnostic screenshots using the synthetic sentinel remain outside Git at:

`D:\GitHub\workspace\lingolens-t12-system-repair\verification\`

The failed diagnostic screenshots were retained for audit and are not copied into
the Repository; they contain no personal text, but show the external test window.

## Required next action

Release or isolate the existing `Ctrl+Alt+Space` owner, then rerun only the manual
registration-success smoke and update this evidence. No code or system workaround
should bypass the required default hotkey contract.
