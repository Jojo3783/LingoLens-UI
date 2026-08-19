# LingoLens Living Operational Handoff

## Current Task

`F-001 / T-14 — Manual Save, Favorite Flow, UI Hardening & Local Disk Persistence`

## Task Status

- `T-14`: `READY_FOR_REVIEW`
- `F-001 Presentation`: `COMPLETED`
- `F-001 Persistence`: `COMPLETED`
- Authorization: `IMPLEMENTATION_AUTHORIZED: F-001 / T-14`

## Current Branch and Commit

- Branch: `feat/ui-design-course-hardening`
- Remote: `origin/feat/ui-design-course-hardening`
- Current Commit: `3e1584d`
- PR URL: `https://github.com/j-neyrox/LingoLens/pull/new/feat/ui-design-course-hardening`
- PR state: `OPEN`、Base `main`

## Recent Changes

- **F-001 UI 互動對齊**：
  - 移除 `AnalysisActionPanel` 之自動儲存 History 行為（`_autoSaveHistory()`）。
  - 新增手動儲存按鈕（`save-action`），點擊後寫入 History 並顯示已儲存標籤（`saved-badge`）。
  - 實作直接點擊最愛（`favorite-toggle`）時「一鍵儲存並加入最愛」流程。
  - 在 `HistoryPage` 與 `FavoritesPage` 實作刪除確認 Dialog（`delete-confirm-dialog`），並在刪除最愛項目時提供連帶移除警告。
  - 在 `FavoritesPage` 點擊取消最愛時，僅自最愛清單移除，History 紀錄完整保留。
  - 儲存、最愛、刪除失敗時加入 SnackBar 錯誤提示反饋。
- **本機持久化整合**：
  - 整合 `LocalFilePersistence`，支援 History、Favorites、Settings、Cache 之本機檔案持久化儲存。
  - 解除重開 App 後資料遺失問題，維持四層架構邊界。
- **程式碼品質與測試**：
  - 修復 `analysis_input_section.dart` 與 `navigation_shell.dart` 之未使用的 Import 與變數，`flutter analyze` 達成 0 Warning。
  - 新增 8 組 F-001 專屬 Widget 測試案例（`widget_t14_history_favorites_test.dart`）。
  - 全數 32 個 Widget 測試與持久化測試 100% 通過。
- **架構與規格對齊**：
  - 將 `LingoLensSurface` 從 `Container(decoration: BoxDecoration(...))` 修正為 `Material` 畫布元件。
  - F-001 個人學習記憶與 F-002 AI 分析核心／統一結果已由草稿升級為 `FORMAL_IMPLEMENTATION_SPEC`。

## Verification Evidence

- Evidence directory: `docs/evidence/T-12R2/`
- Reference decision matrix: `docs/evidence/T-12R/reference-decisions.md`
- Archive SHA-256 必須維持：`43f77552800dfbc68b983da603b3b5483217e7c8bea2ba04fdce03fee1135279`
- T-12R2 verified implementation SHA `218261d2f6b0a782a7dcd82fd5ad585da0461b8d`：fresh-clone pub get、lockfile immutability、format、analyze、focused `23 PASS`、full `150 PASS`、native watchdog／UIA timeout／Clipboard state-machine harness、Windows build、diff check 均 `PASS`。
- Verification receipt：`D:\GitHub\workspace\T-12R2-integration-218261d.log`。
- Fresh clone 執行 `flutter pub get` 後 tracked `pubspec.lock` 未變更，working tree clean。
- Native harness 實際覆蓋 Clipboard post-Copy cleanup；不再以 lifecycle flags 單獨宣稱 cleanup pass。
- Native watchdog 實際覆蓋 deadline-triggered `RequestTimeout`、唯一 `CoCancelCall` gate、completion／cancel／shutdown wake、race 與 destruction safety。
- Windows manual Alt+S／selected-text／panel interaction：`USER_ACTION_REQUIRED_T-12R2_WINDOWS_MANUAL_QA`，不得視為 manual smoke pass。
- Live OpenAI API: `NOT_RUN`
- 使用 synthetic credential tests；未將 credential、raw input、raw response 或完整 prompt 寫入 Repository。

## Blockers

- Windows manual smoke、Clipboard exact restoration、Alt+S registration、selected-text capture 與 panel activation 仍待 Luke 人工桌面互動；目前分類為 `USER_ACTION_REQUIRED_T-12R2_WINDOWS_MANUAL_QA`。
- macOS shared-code、macOS build 與 secure-storage QA 無法在 Windows host 執行；分類為 `USER_ACTION_REQUIRED_T-12R2_MACOS_QA`，不得宣稱 macOS pass。
- GitHub checks 實際結果為 `NO_CHECKS_REPORTED`；Gate `NOT_APPLICABLE`，不視為 PASS，也不構成 integration blocker。
- Clipboard deadline correction：`ACCEPTED`；UIA bounded timeout correction：`ACCEPTED`。
- Automated integration verification：`PASS`；`T-12R2_READY_FOR_TEAM_REVIEW: false`；`SAFE_TO_MERGE: false`。
- macOS build：`REPORTED_PASS_BY_EASON`；macOS formal evidence／secure-storage QA：`PENDING`。
- Ethan functional parity：`FAIL`；T-12R3 product realignment：`READY_FOR_REVIEW`；下一個 implementation node：`T-12R3-B`。

## Risk／Plan Corrections

- Fake Provider 維持預設；OpenAI 只在 explicit selection 下使用，缺少 credential 時維持 OpenAI selection 並回傳 typed configuration failure，不靜默 fallback。
- 單一 profile contract 不授權 multi-account、failover、budget、cost routing、其他 provider、custom endpoint 或 credential persistence 以外的 durable data。
- 不執行 live OpenAI API，不使用真實 API key，不修改 `D:\GitHub\temp` source repositories，不在 `D:\GitHub\temp` 建置。

## Next Authorized Task

等待 Luke review T-12R3 product parity contract；下一個 implementation node 是 `T-12R3-B`，需另外取得明確 authorization。Windows manual QA 與 macOS QA 仍是 merge gate；T-13 及後續目前沒有授權。

## Explicitly Unauthorized Work

- Merge、Auto-merge、Ready for Review、刪除 branch、建立新 PR、直接 push `main`。
- T-13 native macOS hotkey、accessibility、NSPanel 或 window activation。
- Live OpenAI API、multi-account、failover、budget、cost routing、其他 provider、custom endpoint。
- T-12R3-B product code implementation、schema v4、無關 dependency upgrade 或 source repository 修改；History、Favorites、Review 不再是永久產品排除，但在 bounded implementation authorization 前不得開始實作。

## Source-of-Truth Precedence

1. Luke 最新明確指令
2. Accepted ADR
3. `AGENTS.md`
4. Root `handoff.md`
5. `agent_tasks.md`
6. Archived Handoff
7. README 與其他文件
8. Existing Code Behavior

Archived Handoff 僅供 historical background，通常唯讀，不代表目前 task status，且不得覆寫 Root `handoff.md`。
