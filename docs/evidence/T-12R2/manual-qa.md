# T-12R2 Manual QA Gate

## Automated verification status

- Verified implementation SHA：`218261d2f6b0a782a7dcd82fd5ad585da0461b8d`
- Automated integration verification：`PASS`
- Clipboard deadline correction：`ACCEPTED`
- UIA bounded timeout correction：`ACCEPTED`
- GitHub checks：`NO_CHECKS_REPORTED`；Gate `NOT_APPLICABLE`，不視為 PASS 或 blocker。
- `T-12R2_READY_FOR_TEAM_REVIEW`：`false`
- `SAFE_TO_MERGE`：`false`
- Ethan functional parity：`FAIL`
- PR #15 product status：`T-12R3 product realignment in progress`

## Windows status

Result：`USER_ACTION_REQUIRED_T-12R2_WINDOWS_MANUAL_QA`
目前 QA 判定：application launch `PASS`；hotkey／activation observable `PASS`；selected-text workflow `FAIL`，實際 typed outcome 為 `uiaBoundednessBlocked`。這表示 UIA bounded path 仍阻塞目前 workflow；依 T-12R3 product contract，UIA 必須是 optional enhancement，正常 bounded Clipboard workflow 不得被此結果阻擋。Codex desktop session 沒有可用的可靠桌面互動通道，不能把 executable launch probe、Flutter widget tests 或 native harness 當成人工 QA。

請 Luke 在 Windows 上使用 final executable 完成：

1. 從 `build\\windows\\x64\\runner\\Release\\lingolens.exe` 啟動，確認啟動成功。
2. 確認 `Alt + S` registration 成功；若被其他程式占用，記錄實際 typed failure。
3. 在可控的測試文字編輯器選取 synthetic text，按 `Alt + S`。
4. 確認 UI Automation 或 truthful Clipboard fallback 被使用，且不自動送出 analysis。
5. 確認 panel show、window activation、draft update、mode update、focus 與 no-auto-submit 行為。
6. 確認 Clipboard 在 exact content、format 與 sequence ownership 下恢復；若第三方修改，確認不覆蓋第三方內容。
7. 觸發 Escape，確認 panel dismissal 與 registration 狀態正常。
8. 關閉並重新啟動，確認 `Alt + S` unregister／register 沒有 stale registration 或 detached worker。

請只回傳 sanitized screenshots／結果；不要貼 raw input、Clipboard payload、API key、Authorization header 或完整 log。

## macOS status

Additional blocker：`USER_ACTION_REQUIRED_T-12R2_MACOS_QA`
原因：目前 host 為 Windows，無法執行 macOS Flutter／Xcode runtime 或 secure-storage QA。
Eason 的 macOS build 結果僅分類為 `REPORTED_PASS_BY_EASON`，不是 formal PASS。
macOS formal evidence／secure-storage QA：`PENDING`。

請在 macOS host 執行：

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `flutter build macos`
5. 使用 synthetic non-secret value 驗證 secure-storage write、restart/read status、delete。

macOS 結果必須包含實際 command、exit code、host、build output 與 sanitized secure-storage evidence。

## Gate decision

在 Luke 回傳 Windows manual QA 與 macOS shared-code／secure-storage QA 前，本 Task 不得標記 `T-12R2_READY_FOR_TEAM_REVIEW`，也不得開始 T-13。Ethan functional parity 目前為 `FAIL`；PR #15 維持 `SAFE_TO_MERGE: false`。T-12R3 product realignment 已建立 contract，下一個 implementation node 為 `T-12R3-B`。
