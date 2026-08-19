# LingoLens Architecture Summary

Architecture status: ACCEPTED；七份 T-04 ADR 已由 Luke、Product Owner 接受，保留 non-blocking followups。

本文件摘要 accepted decisions，不取代 ADR。T-08、T-08R、T-08R2、T-09 與 T-10 已完成並合併；T-11 目前為 `REQUEST_CHANGES`，T-11R 為 `READY_FOR_REVIEW`，T-12 及後續仍未授權。

## Layer responsibilities

```text
Presentation
    ↓
Application
    ↓
Domain contracts
    ↑
Infrastructure／Platform Adapters
```

- `presentation`：Widgets、layout 與 state rendering；只提交 Application intent，不直接呼叫 provider、database、process 或 OS API。
- `application`：request lifecycle、`AnalysisSessionState`、mode suggestion／manual override、execution strategy、retry、cancel、stale-result rejection、mode-specific action controllers、request-scoped action generation guard 與 history-write decision。
- `domain`：framework-agnostic `AnalysisRequest`、`AnalysisResult`、`AnalysisPreview`、`ReadingAnalysis`、`ExpressionAnalysis`、`AnalysisError`、`RequestId`、repository contracts 與 cancellation contract。
- `infrastructure`：provider、repository、cache、telemetry、process runner、Flutter clipboard adapter 與 deterministic Fake speech adapter 等 concrete adapters；T-07 不建立 durable database runtime。
- `platform`：在獲授權的 task 中才實作 Windows／macOS hotkey、selected-text、clipboard、floating window、window activation、TTS 與 permission adapters。

## Domain versus Application state

```text
Domain:      AnalysisRequest | AnalysisResult | AnalysisPreview | AnalysisError | RequestId
Application: AnalysisSessionState | AnalysisPhase | AnalysisController | retry | override | stale rejection
```

Domain 不依賴 Riverpod、Flutter、Widget 或 Application lifecycle。Riverpod 若採用，限於 Application／composition wiring；`AsyncValue` 不得取代 explicit `AnalysisSessionState`。

## Provider boundary

所有 provider 都支援 full typed analysis：

```text
AnalysisProvider.analyzeFull(request, context)
    → Future<AnalysisResult>
```

Progressive 是 optional capability：

```text
ProgressiveAnalysisProviderCapability.analyzePreview(request, context)
    → Future<AnalysisPreview>
```

Application 選擇 `FullOnlyStrategy` 或 `TwoStageStrategy`；UI 不直接選 provider method。Unsupported preview 不得 fabricate partial，silent Mock fallback 禁止，provider failure 必須是 typed／observable error。

## Persistence boundary

History、Analysis Cache、Settings、Favorite 與 Feedback 有分離的 logical ownership。visible history limit `20` 是 UI／Domain selection policy，不代表 physical database retention `20`。Favorites 在 visible query 中優先選取，但仍計入總 returned records limit；不可因 visible limit 自動 physical eviction，也不可將 Favorites 排除在 query count 之外。

T-05R 已補上 repository interfaces、deterministic in-memory／fake implementations 與 contract tests；T-05R2 修正 visible query 的總 limit 與 deterministic ordering。此 remediation 仍不建立 Drift dependency、SQLite runtime、schema、migration harness 或 local database file。Drift／SQLite 仍是未來 durable proposal。

## Progressive result boundary

Progressive output 是產品需求，但 two-stage 是可替換的 Application strategy：

```text
T-05: FULL_ONLY_FAKE
Real-provider two-stage: DISABLED_BY_DEFAULT
```

Real-provider two-stage 只有在 latency、cost、usefulness、consistency、cancellation、stale rejection 與 partial failure evidence 完成，並取得 Product Owner approval 後才能 enable。Preview 必須標示 partial，不得寫入 full History 或補造缺少的 sections。

## T-10 execution strategy and state flow

T-10 將 two-stage orchestration 保持在 Application layer：

```text
AnalysisController
    → FullOnlyStrategy／TwoStageStrategy
    → AnalysisProvider.analyzeFull
    → optional ProgressiveAnalysisProviderCapability.analyzePreview
    → AnalysisLoading／AnalysisPartial／AnalysisSuccess／AnalysisPartialFailure／AnalysisCancelled
```

`TwoStageStrategy` 只對明確宣告 Preview capability 的 deterministic Fake Provider 呼叫
`analyzePreview`；其他 provider 直接走 `FullOnlyStrategy` 行為。Preview 綁定
`AnalysisMode`、provider identity 與單一 primary output，Reading 使用 Translation，
Expression 使用 Natural。Preview 只供展示，不序列化為 schema version `3` 的完整
`AnalysisResult`，也不寫入 History、Favorite、Feedback 或 Cache。新 RequestId、cancel、
retry、dispose 與 stale completion 都由 Application context guard 管理；Presentation
只呈現 state，不選擇 provider method。

## T-11 provider and observability boundary

T-11 只新增一個 real provider adapter：`OpenAiResponsesAnalysisProvider`。
它實作 `AnalysisProvider.analyzeFull`，不實作
`ProgressiveAnalysisProviderCapability`，因此永遠由 Application 的
`FullOnlyStrategy` 執行；real-provider progressive mode 預設停用。App composition
仍以 deterministic Fake Provider 作為預設，remote provider 必須透過明確的 typed
selection 與 explicit model 設定 opt-in，沒有 provider picker UI。

```text
AnalysisProvider
    → OpenAiResponsesAnalysisProvider
    → AnalysisHttpTransport
    → HttpClientAnalysisHttpTransport
    → https://api.openai.com/v1/responses
```

OpenAI request 使用 `store: false`、`text.format.type: json_schema`、`strict: true`、
root 與 nested `additionalProperties: false`，並以分離的 system 與 user input items
傳送內容。`ProviderCredentialSource` 只提供 credential boundary；缺少 credential
時不會發出 HTTP request。UI 會顯示 remote disclosure，包含 remote transmission、
`store=false` 與不代表絕對 Zero Data Retention 的限制。

`AnalysisTelemetrySink` 僅接受 typed event／metric，預設為 bounded in-memory sink；
不寫入檔案、Console、資料庫或網路。Telemetry 不包含 raw input、prompt、output、
response body、clipboard、credential、Auth header 或 stack trace。T-11 只量測
`provider_setup_ms`、`response_read_ms`、`json_decode_ms` 與 `total_latency_ms`，
不捏造 first-token 或 model-generation timing。

## T-11R remediation boundary

`HttpClientAnalysisHttpTransport` 透過 injectable `HttpSessionFactory` 保持
request 尚未建立時的 cancellation control；token 取消時會 force-close session，
request 建立後則同時 abort request。Connect、request close 與 response body read
共用單一 deadline，response body 以 streaming byte count 套用命名的
`maxResponseBytes` 上限，超限時立即關閉連線並回傳 sanitized typed failure。

`AnalysisHttpResponse.responseReadDuration` 由 transport 在 response headers 取得
後開始、body bytes 完整讀取後結束時產生；Provider 不再以整個 `postJson()` 時間
代理 `response_read_ms`。Provider 只有在 HTTP、schema validation 與 typed decode
全部成功後才發出 `provider_completed`，失敗 execution 只發出一個 failure 或
cancellation terminal outcome。

## Platform boundary

T-07 manual-input flow 只透過 Application-owned ports 使用 injected Flutter clipboard adapter 與 deterministic Fake speech adapter；Widgets 不得 direct call Win32、PowerShell、AppleScript、Clipboard APIs、Process、repository 或 native plugins。

## T-12 Windows platform boundary

T-12 的 Application-owned contracts 為 `GlobalHotkeyService`、
`SelectedTextService`、`FloatingWindowService` 與 `WindowActivationService`。
`WindowsPlatformChannel` 是唯一 Windows native seam，負責 `RegisterHotKey`、
UI Automation focused-element selection、bounded clipboard fallback、DPI-aware
panel positioning 與 activation；Presentation 只訂閱 typed state，不直接接觸
native API。

Primary capture 透過 UI Automation text selection pattern 取得目前 focused
external element；只有 `noSelection` 或 `captureUnsupported` 才允許 bounded
clipboard fallback。Fallback 在 mutation 前保留所有可安全保存的 clipboard
formats，使用 sequence number 驗證 ownership，並在 concurrent modification 時
拒絕 restore，避免覆寫第三方新內容。

每次 capture 使用獨立 generation；新 hotkey event、cancel 或 dispose 都會使舊的
selected-text、clipboard、panel 或 activation completion 失效。Captured text 只
寫入 input boundary，不會自動觸發 analysis。Default Fake Provider 維持預設，
T-12 不啟用 live OpenAI API。

Current T-12 review state：`BLOCKED_ENVIRONMENT_MANUAL_HOTKEY`。Required default
`Ctrl+Alt+Space` 在本機已由既有 owner 占用；registration conflict 會轉成 typed
failure，manual input 仍保持可用。T-13 及後續：`NOT_AUTHORIZED`。

## Error and cancellation flow

```text
Platform／Provider／Persistence error
    → typed Domain／Application error
    → current request state
    → user-facing recovery action
```

```text
new request／user cancel
    → Application cancels request context
    → underlying provider work terminates where supported
    → stale result rejected by RequestId
    → cancelled state；不寫入 History
```

## Observability and privacy

`LatencyRecorder` 可記錄 stage timing、result source、exit category、schema decode、persistence outcome 與 cancellation outcome。Production default 不記錄 raw input、full prompt、translation、expression result、clipboard 或 credential；debug diagnostics 必須 opt-in、redacted 且具 retention boundary。

## T-07 executable flow

```text
Manual Input
    → Mode Suggestion／Manual Override
    → Application State
    → Fake Provider
    → Mode-specific Typed Result
    → Copy／Listen（Fake）／Save／Favorite／Feedback
    → Visible UI
```

此 flow 是 T-07 已授權的 executable vertical slice；actions 為 session-only in-memory behavior，目前仍不包含 real provider、durable persistence、native TTS 或後續 task integration。

T-07R 保持此 layer boundary：Feedback 與 mode selection 的可見狀態由 Application／RequestId 驅動，Presentation 只提交 intent；`AnalysisActionGuard` 使同一 RequestId 的較新 action 取代較舊 action，且 reset、新 request、dispose 會使舊 completion／failure 失效。此修正不改變 provider、persistence 或 platform adapter 邊界。

## T-08 Reading mode flow

```text
Manual Input
    → Application-owned mode snapshot
    → Full-only deterministic Fake Provider
    → schemaVersion 2 typed ReadingAnalysis
    → Translation
    → Copy／Listen（Fake）
    → Sentence analysis／Grammar／Vocabulary／Nuance
    → Save／Favorite／Feedback session actions
```

Reading schema version `2` 的五個 fields 是 `translation`、`sentenceAnalysis`、`grammar`、`vocabulary`、`nuance`；舊的 `note` 不再是目前 contract。Presentation 以 reusable `_ResultSection`、stable keys、`SelectionArea` 與 Material controls 呈現內容，並將 quick actions 放在 Translation 後、session actions 放在所有 Reading sections 後。Widgets 仍只提交 Application intent，不直接呼叫 Clipboard、Speech、provider 或 persistence。

T-08 不選擇 progressive／streaming strategy、不引入 real AI、native TTS、durable persistence 或 T-09 fields。Windows build evidence 目前受 disposable clone 缺少 CMake executable 阻擋；macOS verification 未執行。

## T-09 Expression mode flow

```text
Manual Input
    → Application-owned mode snapshot
    → Full-only deterministic Fake Provider
    → schemaVersion 3 typed AnalysisResult
    → Natural
    → Copy／Listen（Fake）
    → Polite／Formal／Context／Tone
    → Save／Favorite／Feedback session actions
```

T-09 upgrades the shared schema to exact version `3` while preserving the
top-level envelope and exact Reading fields. `ExpressionAnalysis` is a
distinct typed object with exactly `natural`, `polite`, `formal`, `context`,
and `tone`, all required non-empty strings in that JSON order. Presentation
uses the existing reusable result section, `SelectionArea`, mode-aware stable
keys, a single accessible result body label, and Application-owned action
ports. Copy, Listen（Fake）, and consent-attached Feedback all use Expression
`natural`. T-09 does not select a progressive strategy or add provider,
network, persistence, platform, or dependency behavior.

## T-08R accessibility remediation

T-08R 保持既有 layer boundary 與 typed result contract：

- `AnalysisQuickActions` 接收 typed `AnalysisMode`，由該 mode 產生 quick-action stable key、container semantics label，以及 Reading／Expression 對應的 Copy／Listen label。
- `AnalysisActionPanel` 從 immutable `AnalysisSuccess.mode` 產生 session-action stable key 與 semantics label，避免 action identity 固定為 Reading。
- `AnalysisActionController` 仍是 mode-specific primary output 的唯一 owner：Reading 使用 `Translation`，Expression 使用 `Natural`；Presentation 只傳遞 action intent。
- reusable result section body 使用 `excludeSemantics: true` 的 selectable content，並提供單一明確的 section label，避免 nested semantics 重複宣告。
- T-08R 只新增 accessibility／Expression regression tests 與 truthful evidence；不修改 schema、dependency、`RequestId` guard、persistence、provider 或 T-09 scope。

## Risk gate distinctions

Risk Register 使用四類 gate：

```text
BLOCKS_ADR_ACCEPTANCE
BLOCKS_T05_SKELETON
BLOCKS_FUTURE_PRODUCTION_INTEGRATION
NON_BLOCKING_FOLLOWUP
```

Base strategy 與 architecture contract 會阻擋 ADR acceptance；T-05R 已以 contract tests 驗證最小 persistence contract 與 deterministic cancellation fake；silent Mock、real process cancellation、clipboard、PowerShell、Windows／macOS evidence 與 two-stage latency／cost 仍主要阻擋未來 production integration。這些 gate 不會被本摘要自行解除。

## T-12R platform and settings boundary

T-12R 保持 `Presentation → Application → Domain ← Infrastructure`。Flutter
Widgets 只透過 Application controller 與 typed interfaces 使用 provider、
Windows capture、clipboard、window activation 與 secure credential storage；
不直接呼叫 Win32、MethodChannel、Clipboard API 或 secure storage。

Windows native capture 的 operation ownership、cancellation、timeout、clipboard
restore 與 owner-thread completion 屬於 Infrastructure boundary。`Alt + S` 是
唯一本輪要求的 hotkey。Native failure 先轉為 typed platform failure，再由
Application 決定 draft、focus 與 UI state；不可由 native layer 直接修改 Widget。

Provider settings 使用一個 `openai-default` `ProviderProfile` 與 opaque
`CredentialReference`。Application 負責選擇 provider、建立 runtime composition、
取消 active analysis 並拒絕 late completion；Infrastructure 負責 secure storage
與環境變數讀取。缺少 OpenAI credential 時維持明確的 OpenAI selection 並回傳
typed configuration failure，不靜默切回 Fake。

T-12R 的 desktop information architecture 僅包含 `分析` 與 `設定`；wide layout
使用 `NavigationRail`，compact layout 使用 `NavigationBar`。macOS native
integration 不在本輪邊界內。
