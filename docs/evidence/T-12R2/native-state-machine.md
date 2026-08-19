# T-12R2 Native Boundary Evidence

## Final exact-SHA automated verification

Implementation SHA：`218261d2f6b0a782a7dcd82fd5ad585da0461b8d`。既有 native
harness 於 `D:\\GitHub\\workspace\\T-12R2-integration-218261d.log` 記錄並以
exit code `0` 通過；Windows application build 亦以同一 SHA 編譯通過。

UIA bounded timeout 的 deterministic helper 覆蓋：`1500ms` 產生 `1500ms`、
sub-millisecond positive budget 最少產生 `1ms`、expired deadline rejected，
以及超大 duration bounded 到 `DWORD` 上限。Production `IUIAutomation2`
QueryInterface、`put_ConnectionTimeout`、`put_TransactionTimeout` wiring 由
Windows build compile-verified；實際 provider runtime、COM cancellation 與人工
UIA interaction 仍保留給 Windows manual QA。

## Clipboard post-Copy cleanup

`ClipboardFallbackStateMachine` 將 capture phase 與 post-Copy cleanup phase 分開。`SendInput(Ctrl+C)` 成功後，cleanup 會建立獨立且有限的 `750ms` deadline；capture timeout 或 cancellation 不會重用已過期的 capture deadline。Cleanup 仍會觀察 sequence、避免取消後讀取新內容，並在沒有 third-party modification 時進行 exact restore／verify。

Native harness 實際執行下列 state-machine scenarios，並以 exit code `0` 通過：

- cancellation after Copy before sequence change：不讀取 payload，等待 sequence，restore，cleanup 完成，結果 `cancelled`。
- timeout after Copy before sequence change：等待至整體 deadline，cleanup 完成，結果 `captureTimeout`。
- sequence change well before capture deadline：讀取 synthetic text、exact restore／verify，結果 `success`。
- sequence change immediately before capture deadline：仍在 capture phase 讀取 synthetic text，結果 `success`。
- sequence change after capture deadline but within cleanup deadline：不讀取新文字，仍 restore／verify，結果 `captureTimeout`。
- restore requires multiple retries after capture deadline：在 cleanup deadline 內完成 restore，結果維持 `captureTimeout`。
- cleanup deadline expires：不產生文字結果，cleanup 完成後回傳 `captureTimeout`。
- third-party sequence change：不覆蓋第三方內容，結果 `clipboardConcurrentModification`。
- restore failure：結果 `clipboardRestoreFailed`。
- shutdown during cleanup：request cancel 後完成 restore／cleanup，結果 `cancelled`。
- 每一個 state-machine execution 只產生一個 terminal response。

這些案例呼叫實際 `ClipboardFallbackStateMachine::Run`，不是只檢查 `NativeCaptureLifecycle` flags。Native command、SHA、時間與 exit code 詳見 [verification.md](verification.md)。

## UI Automation cancellation

`NativeCaptureOperation` 現在：

- 由 `NativeCaptureDeadlineWatchdog` 擁有 deadline、`condition_variable` 與 watchdog `std::thread`；沒有 detached thread。
- watchdog 在 worker completion、explicit cancellation、shutdown 或 deadline 到達時醒來；正常完成與 explicit cancellation 會立即終止等待。
- deadline 到達時，watchdog 先呼叫 `NativeCaptureLifecycle::RequestTimeout()`，再讀取 owned worker thread ID。
- 若 `CoEnableCallCancellation` 成功且 worker ID 有效，watchdog 以唯一 gate 呼叫實際 `CoCancelCall(worker_thread_id, 0)`。
- `CoCancelCall` 的結果會記錄為 `succeeded` 或 `failed`；失敗不會被宣稱為絕對取消，並可透過 typed response metadata 觀察錯誤碼。
- worker 與 watchdog 都由 operation 擁有並 join；shutdown 會要求 cancellation、嘗試 COM cancellation，再安全等待兩者完成。
- watchdog 不接觸 Flutter `MethodResult`；completion 仍透過 owner window message 在 platform thread 完成。
- 每個可能跨越 cancellation 的 UIA COM 呼叫完成後，重新檢查 generation／lifecycle／timeout。
- 若無法啟用 COM call cancellation，回傳 `uiaBoundednessBlocked`，Dart contract 映射為 `T-12R2_UIA_BOUNDEDNESS_BLOCKED`，不把未證明的 bounded cancellation 宣稱為成功。
- 建立 `IUIAutomation` 後先查詢 `IUIAutomation2`，依 `NativeCaptureLifecycle::deadline()` 計算剩餘 budget，設定 connection／transaction timeout 後才呼叫 `GetFocusedElement`。
- `QueryInterface`、任一 timeout setter 失敗時 fail closed 為 `uiaBoundednessBlocked`；deadline 在設定流程中失效時回傳 `captureTimeout`，不使用 UIA default timeout。
- `IUIAutomation2` interface 由統一 cleanup path Release，涵蓋成功與所有失敗／取消／timeout exit paths。

Native harness 覆蓋 work-before-deadline、deadline timeout、deadline callback exactly once、explicit cancel wake、completion wake、shutdown wake、deadline／cancel race、destruction safety 與 `CoCancelCall` failure classification。自動化測試證明 typed mapping 與不進入 clipboard fallback；實際 UIA provider／外部 COM server 是否支援 cancellation，以及人工取消與關閉測試，仍屬 Windows manual QA，尚未由 Codex desktop interaction 完成。

## Known native limitation

`CoCancelCall` 是對 COM call 的取消要求，不是對不支援取消的外部 provider 的強制 thread termination。若 provider 不支援 COM cancellation，runtime 會保留 `failed`／typed boundedness evidence，不宣稱絕對 bounded shutdown；此情境仍需 Windows manual QA 與平台 provider evidence。

## Security boundary

Native response、error status、harness 與 evidence 不包含 raw user input、raw Clipboard payload、API key、Authorization header 或完整 prompt。
