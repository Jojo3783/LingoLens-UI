# T-12R2 Evidence

本目錄記錄既有 PR #15 的最後一輪窄幅 remediation。所有自動化結果均以 exact
implementation SHA 記錄；人工 Windows 與 macOS 關卡維持未完成狀態，不以
native harness 或 Windows host 結果代替。

## Immutable candidate

- Repository：`D:\GitHub\LingoLens`
- Branch：`feat/t12-windows-integration`
- Existing PR：`#15`，Base `main`，維持 `OPEN`、Draft
- Required base：`10f2d3da98d1fdbdfd2e0abbb39d758a396a6183`
- Starting HEAD：`218261d2f6b0a782a7dcd82fd5ad585da0461b8d`
- Verified implementation SHA：`218261d2f6b0a782a7dcd82fd5ad585da0461b8d`
- Evidence／delivery commit：本輪 documentation commit，SHA 於 delivery 後記錄
- Lockfile Commit：`79790667d694aa40d0fe48dcb75d0c17fd805e2b`
- Verification clone：`D:\GitHub\workspace\lingolens-t12r2-verify-218261d`
- Verification receipt：`D:\GitHub\workspace\T-12R2-integration-218261d.log`
- Native direct harness：Visual Studio `cl.exe`；CMake／MSBuild configure 另有 SDK discovery blocker，未以 blocker 結果取代 direct harness。

## Evidence index

- [verification.md](verification.md)：每個 required command 的 SHA、UTC 時間、exit code、相關輸出與 status。
- [native-state-machine.md](native-state-machine.md)：Clipboard fallback state machine、UI Automation cancellation boundary 與 native harness coverage。
- [provider-boundaries.md](provider-boundaries.md)：startup hydration、secure storage、secret boundary 與 Save and Apply。
- [manual-qa.md](manual-qa.md)：Windows 與 macOS 必須由使用者／對應平台完成的測試步驟。

## Scope and limitations

- Clipboard post-Copy cleanup：`PASS`，capture deadline 與獨立 `750ms` cleanup deadline 由實際 fallback state machine harness 驗證；不只檢查 lifecycle flags。
- UI Automation boundedness：`PASS_WITH_TYPED_BLOCK`。owned watchdog 在 deadline 到達時主動要求 timeout 並呼叫實際 `CoCancelCall`；若無法啟用或取消 COM call，runtime 保留 `T-12R2_UIA_BOUNDEDNESS_BLOCKED`／truthful failure metadata，不宣稱絕對取消。
- Clipboard deadline correction：`ACCEPTED`。
- UIA bounded timeout correction：`ACCEPTED`。
- Automated integration verification：`PASS`，focused `23 PASS`、full `150 PASS`、native harness、format、analyze、Windows build 與 immutable diff check 均以 verified implementation SHA 通過。
- GitHub checks：`NO_CHECKS_REPORTED`；Gate `NOT_APPLICABLE`，不視為 PASS，也不視為 integration blocker。
- Startup provider hydration、secret boundary、secure-storage failure、atomic Save and Apply：`PASS`，由 focused／full tests 覆蓋。
- Live OpenAI API、real API key：`NOT_RUN`、未授權。
- Windows desktop manual interaction：`USER_ACTION_REQUIRED_T-12R2_WINDOWS_MANUAL_QA`。
- macOS build：`REPORTED_PASS_BY_EASON`，非正式 PASS。
- macOS formal evidence／secure-storage QA：`PENDING`，`USER_ACTION_REQUIRED_T-12R2_MACOS_QA`。
- `T-12R2_READY_FOR_TEAM_REVIEW`：`false`；`SAFE_TO_MERGE`：`false`。
- Archived Handoff 未修改；hash 維持 `43f77552800dfbc68b983da603b3b5483217e7c8bea2ba04fdce03fee1135279`。
- T-13 及後續：`NOT_AUTHORIZED`。
