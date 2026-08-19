# T-12R3 Ethan Product Parity Contract

## 文件狀態

- Task：`T-12R3 — Ethan Product Parity Contract and Bounded Migration Plan`
- Status：`READY_FOR_REVIEW`
- Branch：`feat/t12-windows-integration`
- Draft PR：`#15`
- `T-12R2` Windows manual QA：`FAIL`
- Ethan functional parity：`FAIL`
- `SAFE_TO_MERGE`：`false`
- T-13 及後續：`NOT_AUTHORIZED`

本文件是 LingoLens 下一階段產品 realignment 的 authoritative contract。它只改變產品目標、功能 parity 與 migration decision，不代表本輪已完成任何 product code、native code、dependency、test 或 schema 實作。

## Product source of truth

Ethan product behavior and UX 是 LingoLens 的 Product Source of Truth，限於產品功能、資訊架構、主要互動流程與可觀察使用者體驗。這項決定不授權複製 Ethan 原始碼、native implementation、dependency graph、credential handling 或 repository 結構。

Pinned source：`D:\GitHub\temp\Merged Model 2`

Pinned commit：`df4f5424e8abfedc52f941c8c5c2f1a9463e8aac`

比對來源：`README.md`、`lib/main.dart`、`lib/ui/main_window/root_view.dart`、`lib/ui/main_window/dashboard_view.dart`、`lib/ui/floating_panel.dart`、`lib/services/floating_window_service.dart`、`lib/services/selected_text_service.dart`、`lib/services/hotkey_service.dart`、`pubspec.yaml`。

Ethan 是產品 parity source，不是 LingoLens 的 code reuse permission、架構 authority 或安全實作 source。LingoLens 仍必須遵守自身的 Domain／Application／Presentation／Infrastructure boundary、secure credential boundary 與 typed failure contract。

## Authoritative product decisions

1. LingoLens 的產品表面必須包含 Dashboard、History、Favorites、Review 與 Settings；目前僅有 `分析`／`設定` 的 shell 是 implementation gap，不是永久產品排除。
2. 產品必須保留 speech／pronunciation support、recent-query visibility 與 learning-state visibility。
3. Windows 的主要工作流程是：selected text → `Alt + S` → bounded synthetic Copy／Clipboard capture → exact ownership-aware Clipboard restoration → prewarmed `480x560` floating panel near cursor → `Topmost` activation → automatic analysis → Cache-First lookup／persistence → result rendering。
4. UI Automation 是 optional enhancement。它不得成為在支援的 Windows 環境中阻擋正常 bounded Clipboard workflow 的 mandatory gate。
5. Reading／Expression、structured analysis contracts、cancellation／timeout、secure credential storage、provider abstraction、observability、typed failures 與 automated tests 都是 LingoLens 必須保留的 enhancement。
6. Production providers 是 Codex CLI 與 OpenAI Responses API。Fake Provider 僅供 test／debug，不是 production fallback。
7. Provider selection 必須 explicit；不得 silent fallback。Codex CLI 使用本機已完成 authentication 的 installation；OpenAI 使用 OS secure storage 內的 BYOK credential。
8. 兩個 production providers 必須遵循相同的 Domain contract。Cache-First 必須發生在 provider execution 之前。
9. `Alt + S` 是 LingoLens 的 intentional hotkey decision，不改回 Ethan 的 `Ctrl + Space`。

## Product parity matrix

| Ethan product capability | LingoLens target | Current state | Decision | Acceptance evidence |
|---|---|---|---|---|
| Dashboard | 首頁呈現 recent queries、學習狀態與主要分析入口 | 尚未存在於 current shell | `ADOPT` | Dashboard widget／manual evidence |
| History | 可瀏覽 recent records，且與 cache 分離 | 尚未存在於 current shell | `ADOPT` | History state、limit 與 persistence tests |
| Favorites | 可 pin／unpin saved records，不受 visible-history eviction 影響 | 尚未存在於 current shell | `ADOPT` | Favorite mutation 與 reusable record tests |
| Review | 從 learning state 進入 review workflow | 尚未存在於 current shell | `ADOPT` | Review navigation／state tests |
| Settings | Provider、privacy、security 與一般設定 | 已有 `設定` destination，但需擴充 | `ADAPT` | Widget、semantics 與 provider tests |
| Speech／pronunciation | 結果可 listen，保留平台差異的 typed failure | 產品目標尚未完整落地 | `ADAPT` | TTS capability／fallback evidence |
| Recent-query visibility | Dashboard 與 History 顯示最近查詢摘要 | 尚未存在 | `ADOPT` | Privacy-safe rendering tests |
| Learning-state visibility | Dashboard／Review 顯示可解釋的學習狀態 | 尚未存在 | `ADOPT` | Deterministic state tests |
| Floating panel | Prewarm、near-cursor、`480x560`、Topmost activation | Windows service 已有部分能力 | `ADAPT` | Native smoke／positioning evidence |
| Capture workflow | `Alt + S`、bounded Clipboard fallback、exact ownership-aware restore | Automated gates pass；manual QA pending | `ADAPT` | Windows manual QA |
| Automatic analysis | Capture 成功後自動開始 analysis | current controller 僅 captured draft，不自動送出 | `ADAPT` | Application flow tests與 manual evidence |
| Cache-First | Cache hit 先於 provider，miss 才執行 provider 並 persistence | 尚未完成 parity | `ADAPT` | Cache ordering／persistence tests |

## LingoLens enhancements to retain

| PR #15 component | Classification | Bounded direction |
|---|---|---|
| Domain analysis contracts | `KEEP` | 維持 typed `AnalysisResult`、Reading／Expression 與 schema contract |
| Reading／Expression | `KEEP` | 產品 parity 不得以 Ethan 的單一結果形狀取代 |
| OpenAI Responses API | `KEEP` | 保留 full-only typed adapter 與 explicit opt-in |
| Secure credential storage | `KEEP` | 保留 OS secure storage、typed failures 與不暴露 raw secret 的 boundary |
| Fake Provider | `ADAPT` | 限定 test／debug deterministic provider，不作 production fallback |
| Current main Analysis／Settings shell | `ADAPT` | 逐步擴展為 Ethan parity target，保留 LingoLens provider disclosure 與安全 UX |
| UIA-first mandatory capture | `REPLACE` | 改為 optional enhancement；bounded Clipboard workflow 必須是正常可用路徑 |
| Clipboard state machine | `KEEP` | 保留 capture deadline、cleanup deadline、sequence ownership、exact restore／verify |
| Native watchdog／timeout | `KEEP` | 保留 bounded timeout、owned shutdown、typed failure 與 latest-capture-wins |
| Floating window | `ADAPT` | 對齊 prewarm、`480x560`、near-cursor 與 Topmost，沿用 LingoLens service boundary |
| Persistence | `ADAPT` | Cache、visible History、Favorite 與 learning state 必須分離且可測試 |
| Dashboard／History／Favorites／Review | `REPLACE` | 依本契約加入正式 product surface，不再列為永久 exclusion |
| TTS | `ADAPT` | 保留 speech／pronunciation capability 與平台 typed failure，不複製 donor dependency 決策 |
| Tests／evidence | `KEEP` | 擴充 parity、capture、provider、privacy 與 manual gate evidence |

## Provider contract

| Provider | Production status | Credential boundary | Selection rule | Domain behavior |
|---|---|---|---|---|
| Codex CLI | `PRODUCTION` | 本機已 authentication 的 Codex CLI installation | 使用者 explicit selection；啟動或 execution failure 必須 typed failure | 遵循相同 analysis contract；Cache-First |
| OpenAI Responses API | `PRODUCTION` | OS secure storage 的 BYOK credential | 使用者 explicit selection；缺 credential 時回報 configuration failure | 遵循相同 analysis contract；Cache-First |
| Deterministic Fake Provider | `TEST_DEBUG_ONLY` | 不使用 production credential | 不得 silent fallback 成為 production provider | 只供 deterministic tests／debug failure controls |

不得加入 silent provider fallback、multi-account、automatic failover、custom endpoint、raw credential persistence 或 live OpenAI request authorization。本文件不授權 T-13。

## Windows interaction contract

### Required path

1. 使用者在支援的 Windows application 中選取文字並按 `Alt + S`。
2. Application 建立唯一 capture generation；新的 capture 取消並淘汰舊 capture。
3. UI Automation 可先嘗試，但不是 mandatory gate；若 UIA unavailable、unsupported 或 boundedness blocked，必須進入 bounded synthetic Copy／Clipboard fallback。
4. Clipboard fallback 以單一 overall capture deadline 運作，記錄原始 ownership／sequence，送出 synthetic Copy，讀取 bounded payload，並在 ownership 仍屬於本次 operation 時 exact restore。第三方在 operation 期間修改 Clipboard 時不得覆寫第三方內容。
5. Capture 成功後顯示已 prewarm 的 `480x560` floating panel，定位在 cursor 附近，完成 Topmost activation。
6. Panel show 與 activation 成功後才提交 draft／focus；接著依 Cache-First 執行 automatic analysis 並 persistence。
7. Panel 顯示結果時，必須保留 Reading／Expression、provider identity、typed failure、cancellation／timeout 與可觀察狀態。

### Current gate interpretation

`uiaBoundednessBlocked` 代表目前 UIA path 的 bounded operation 未完成，不代表產品可以要求 UIA-first mandatory capture。T-12R2 的 manual QA 仍是 `FAIL`，下一個實作節點必須證明 bounded Clipboard fallback 在同一支援範圍內可正常完成。

## Acceptance criteria

- Dashboard、History、Favorites、Review、Settings 的 product surface 與 navigation contract 有明確入口。
- Recent-query 與 learning-state visibility 不記錄 raw input 到 telemetry，並符合 visible-history 與 Favorite policy。
- Windows `Alt + S` 主要流程在 UIA unavailable／boundedness blocked 時仍可透過 bounded Clipboard workflow 完成。
- Clipboard restore 只在 operation 仍擁有原始 sequence 時執行，且不得覆蓋第三方修改。
- Floating panel、automatic analysis、Cache-First、persistence 與 result rendering 有 deterministic tests／manual evidence。
- Codex CLI 與 OpenAI Responses API 都遵循相同 Domain contract，provider selection explicit，缺 credential 不 silent fallback。
- Reading／Expression、secure credential storage、typed failures、cancellation／timeout、observability 與 privacy evidence 維持通過。
- Windows manual QA 與 macOS formal evidence 完成前，`T-12R3_READY_FOR_TEAM_REVIEW` 與 `SAFE_TO_MERGE` 都必須是 `false`。

## Branch strategy evaluation

### A. Continue restructuring PR #15

- 優點：保留已完成的 T-12R2 native boundedness、secure-storage、provider 與 lockfile 工作；不必重新搬移 verified code；migration cost 最低。
- 風險：PR #15 已同時包含現有 shell 與 native remediation，若不切出 parity slices，review surface 會持續偏大；commit history clarity 較弱。

### B. New replacement branch from `main` and selectively port reusable PR #15

- 優點：可重新組織產品 parity 與 native foundation，commit history clarity 最佳，且能避免把已判定為錯誤的 UIA-first mandatory assumption 一併帶入。
- 風險：需要重新驗證並選擇性移植 Windows、provider、secure-storage、lockfile 與 evidence；migration cost 高，且 porting regression risk 也高。

### Recommendation

推薦 **A：Continue restructuring PR #15**。理由是 PR #15 已有可重用且具自動化證據的 Windows boundedness、provider 與 secure-storage foundation；以小型、可 review 的 T-12R3-B parity slices 逐步調整，總 regression risk 與 migration cost 低於重新移植。每個 slice 必須保留獨立 evidence，並把產品 parity 與 native correction 分開驗證。此推薦不代表本輪建立新 branch、建立新 PR 或開始 T-12R3-B。

## Unresolved decisions

- Dashboard／History／Favorites／Review 的 exact data model 與可見歷史 UI，待 T-12R3-B 的 bounded implementation plan。
- Cache persistence technology 與既有 provider／secure-storage composition 的整合方式，待 implementation ADR／review。
- Windows native UIA enhancement 的可選啟用條件與 capability disclosure，待實機 evidence。
- macOS speech、capture 與 secure-storage formal QA 尚未完成；不得由 Windows evidence 推論。

## Scope boundary

本輪只建立產品 parity contract、salvage matrix、migration strategy 與 evidence correction。不得修改 `lib/`、`windows/`、`macos/`、`test/`、`pubspec.yaml`、`pubspec.lock` 或任何 source repository。不得執行 Flutter／Dart command，不得執行 live OpenAI request，不得 Merge、Auto-merge、Ready for Review 或進入 T-13。
