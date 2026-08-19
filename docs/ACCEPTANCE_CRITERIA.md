# Acceptance Criteria

Status: T-12_BLOCKED_ENVIRONMENT_MANUAL_HOTKEY

## T-06 Domain schemas and error contract (historical baseline)

- `AnalysisResult` 是 shared typed response envelope，包含 `schemaVersion`、`providerLabel`、`reading` 與 `expression`。
- T-06 baseline 使用 exact integer `1`；T-08 已授權並將目前 shared contract 升級為 exact integer `2`。
- `ReadingAnalysis` 與 `ExpressionAnalysis` 是 distinct typed nested objects，兩者均 required。
- `dart:convert` JSON encode／decode 必須 deterministic；required、型別與 unexpected-property validation 失敗均映射為 `INVALID_STRUCTURED_OUTPUT`。
- `providerLabel` 與每個 nested result string 必須在 `trim()` 後非空，且合法原始字串須保留。
- `maxAnalysisInputCharacters = 2000`；輸入先 `trim()`，再以 `normalizedInput.runes.length` 計算 Unicode scalar values。
- 空白輸入與超過 2,000 個 Unicode scalar values 的輸入必須在 provider invocation 前拒絕。
- Invalid input 不得寫入 History 或 Cache。
- Required error codes 使用 explicit wire values 與 user-safe Traditional Chinese messages；`PROVIDER_FAILED` 保持 backward compatibility。
- Parser、schema、provider、cancellation、persistence 與 unexpected failures 不得將 raw payload、raw exception text 或 stack trace 傳至 presentation state。
- Existing full-only Fake Provider、cancel、retry、latest-wins、stale-result rejection、dispose、History／Cache isolation 與 accessible UI behavior 必須維持通過。

## Scope exclusions

T-06 不包含 T-07 mode selection、automatic suggestion、manual override、UI expansion、real provider、progressive／streaming results、native platform integration、durable production persistence 或 dependency changes。

## T-07 Manual-input fake-provider MVP (accepted baseline)

- Manual input 由 Application 驗證、正規化並建立 immutable `AnalysisRequest`。
- Application 擁有 automatic mode suggestion、Reading／Expression manual override、`Use suggestion` 與 loading 期間的 mode-selection lock。
- `AnalysisMode` 必須存在於 request 與所有 session states；成功狀態保留 immutable input、mode 與 result snapshot。
- T-07 僅使用 full-only deterministic Fake Provider；不得加入 real AI、progressive／streaming provider 或 T-08／T-09 result fields。
- T-07 baseline 的 Reading 僅顯示 Translation 與 Reading note；T-08 supersedes this with the version-2 Reading contract below。Expression 仍僅顯示 Natural 與 Polite。
- Copy 經由 injected `ClipboardWriter` 與 infrastructure `FlutterClipboardWriter`；Widget 不得直接呼叫 `Clipboard`。
- Listen 經由 injected `SpeechAdapter`，只提供 `Listen（Fake）` 與 deterministic Fake adapter；不得加入 native TTS dependency。
- Save 必須是 explicit、request-scoped、immutable、idempotent，且僅寫入 in-memory session History；disabled History writes 必須 truthful。
- Favorite 只有在 Save 成功後可用，並透過 `PersistenceController` 以 in-memory session state 更新。
- Feedback 必須要求 reason；comment 選填；consent 預設 false；附加 input／mode-specific primary output 僅在 consent 時保存，且每個 RequestId 最多一次成功提交。
- UI 必須提供 accessible live regions、stable keys、loading／cancel／retry 與 mode-specific action state。

## T-07R Review remediation criteria

- Feedback reason、comment、consent、validation 與 submission state 必須在 `AnalysisSuccess.requestId` 改變時完整重設；舊 RequestId 的 UI callback 不得提交目前 request 的 Feedback。
- Feedback consent 僅能附加目前 RequestId 的 input 與 mode-specific primary output；每個 RequestId 最多一次成功提交。
- Mode Dropdown 必須由 Application 的 `effectiveMode` 控制；manual override、`Use suggestion`、visible selection 與 submitted `AnalysisSuccess.mode` 必須一致。
- Loading 期間 mode selection 與 `Use suggestion` 必須維持鎖定，Application state 是唯一 authoritative source。
- Copy、Listen、Save、Favorite 與 Feedback 的同一 RequestId async action 必須以 generation token 拒絕過時 completion／failure；reset、新 request、dispose 必須使舊 token 失效。
- T-07R 只修正 PR #10 review findings；T-08、T-09 及後續 task 仍未授權。

## T-07R2 Feedback ownership remediation criteria

- Feedback persistence 必須具備 request-scoped operation ownership；stale Request A completion 不得清除 Request B 的 `_feedbackInFlight` 或 operation owner。
- 同一 RequestId 的第一個 Feedback persistence operation 尚未完成時，第二次 submission 不得啟動新的 repository write。
- stale success／failure completion 不得改變目前 Request 的 `feedbackSubmitted`、action phase 或 message。
- persistence success 必須將完成的 RequestId 加入 completed set，即使 UI 已切換到另一個 RequestId；persistence failure 只能清除相同 operation 的 ownership。
- `reset()`、new request 與 `dispose()` 必須使舊 Feedback completion 失效；既有 RequestId argument、consent policy、generation guard 與 immutable snapshot 必須保留。
- Controlled race tests 必須驗證 Request A／B success 與 failure、repository invocation count、record 數量與 final visible state。
- T-07R2 只修正 PR #10 Feedback race finding；T-08、T-09 及後續 task 仍未授權。

## T-07 exclusions

T-07 不包含 T-08／T-09 擴充欄位、real provider、durable persistence、native TTS、hotkey、selected-text capture、OCR、floating window、progressive result、dependency upgrade、Merge 或 Auto-merge。

## T-08 Reading mode

- `analysisSchemaVersion` 必須為 exact integer `2`；`ReadingAnalysis` 必須恰好包含 `translation`、`sentenceAnalysis`、`grammar`、`vocabulary`、`nuance` 五個 non-empty string fields，且不得包含 `note`。
- `ReadingAnalysis` 與 `ExpressionAnalysis` 維持 distinct typed nested objects；JSON encode／decode、required、型別與 unexpected-property validation 必須維持 deterministic，失敗映射為 `INVALID_STRUCTURED_OUTPUT`。
- Fake Provider 必須以相同 input deterministic 產生五個彼此不同且可辨識的 Reading field values；不得呼叫 real AI 或加入 progressive／streaming behavior。
- Reading UI hierarchy 必須依序呈現 Translation、Copy／Listen（Fake）、Sentence analysis、Grammar、Vocabulary、Nuance，再呈現 Save、Favorite、Feedback session actions。
- Reading sections 必須使用 reusable section rendering、stable keys、`SelectionArea`／`SelectableText`，長輸出在 desktop 與 narrow viewport 均可捲動且不得水平溢出。
- Copy 與 Listen（Fake）必須使用 Reading Translation；Save、Favorite、Feedback 必須維持 request-scoped session behavior，Feedback content 仍只有在 explicit consent 時附加。
- UI 必須提供可及性 labels、headers、live region、keyboard-compatible Material controls，且 action state rebuild 不得取代目前的 selection surface。
- Expression regression 必須維持 Natural、Copy／Listen（Fake）、Polite，且不得顯示 Reading 五個 sections。
- T-08 不包含 T-09 Expression 擴充欄位、real provider、progressive／streaming output、native TTS、durable persistence、hotkey、selected-text capture、OCR、floating window、dependency upgrade、Merge 或 Auto-merge。

## T-08R Team Review remediation

目前 T-08 因 Team Review finding 標記為 `REQUEST_CHANGES`；T-08R 僅處理 PR #11 的 accessibility 與 evidence remediation。

- Quick actions 與 session actions 必須由 typed `AnalysisMode` 產生 mode-aware stable keys 與 semantics labels；Reading 與 Expression identities 不得混用。
- Reading quick actions 必須以 Reading `Translation` 作為 Copy／Listen（Fake）主要輸出；Expression quick actions 必須以 Expression `Natural` 作為主要輸出。
- Result section body 必須提供單一明確的 accessible label，避免 `SelectableText` 造成重複 semantics；result action container 必須保留可辨識的 mode-aware label。
- Expression regression 必須驗證 Natural、Copy／Listen（Fake）、Polite、Expression action keys／labels，以及不得出現 Reading action identities 或五個 Reading sections。
- Mode switching regression 必須驗證新的 mode 不會保留舊 mode 的 action keys 或 labels。
- Visual evidence 必須誠實標示既有 screenshot 的文字可讀性為 `UNVERIFIED_IN_SCREENSHOT`，並以通過的 widget assertions 支援 accessibility contract；不得宣稱未產生的 raw runtime semantics dump。
- T-08R 不修改 schema、dependency、controller 的 primary-output ownership、`RequestId` guard、persistence contract 或 T-09 scope。

## T-08R2 Governance and delivery reconciliation

- Status: `READY_FOR_REVIEW`。
- Authorization: `IMPLEMENTATION_AUTHORIZED: T-08R2_PR11_GOVERNANCE_DELIVERY_ONLY`。
- T-08R2 只修正治理 task states、tested-commit traceability、既有 PR #11 body、T-08R2 evidence 與 frozen-commit verification。
- T-08R implementation commit：`f0956b11a0c0b39b3aa23c8968035ee75ead4bff`；原始 T-08 implementation commit：`ab6012f3b2a1a919eec9999cb2bfae9f1350d949`。
- T-09 及後續維持 `NOT_AUTHORIZED`；不得修改 production code、tests、schema、dependencies、platform files 或 Archived Handoff。

## T-09 Expression mode

- `analysisSchemaVersion` 必須為 exact integer `3`；top-level envelope 維持 `schemaVersion`、`providerLabel`、`reading`、`expression`。
- `ReadingAnalysis` 必須維持 exact fields `translation`、`sentenceAnalysis`、`grammar`、`vocabulary`、`nuance`；不得因 T-09 改變 Reading contract。
- `ExpressionAnalysis` 必須恰好包含 JSON order 的 `natural`、`polite`、`formal`、`context`、`tone` 五個 required non-empty string fields；missing、unexpected、wrong type、empty、whitespace 與 unsupported schema version 必須映射為 `INVALID_STRUCTURED_OUTPUT`。
- Deterministic Fake Provider 對同一 normalized input 產生五個彼此不同、可辨識且保留 Reading regression 的 Expression values；不得呼叫 real AI、network、SDK、fallback 或 progressive output。
- Expression UI hierarchy 必須依序呈現 Natural、Copy、Listen（Fake）、Polite、Formal、Context、Tone，再呈現 Save、Favorite、Feedback；必須保留 `SelectionArea`、reusable result sections、single accessible result body label、mode-aware semantics 與 stable keys `expression-natural`、`expression-polite`、`expression-formal`、`expression-context`、`expression-tone`。
- Copy、Listen（Fake）與 consent-attached Feedback 必須使用同一 RequestId 的 Expression `natural`；Save、Favorite、Feedback 與 action generation guard 必須維持 request-scoped 行為。
- Application-owned manual override、Use suggestion、loading lock、immutable submitted mode snapshot、retry mode、stale-result rejection、Reading mode與既有 T-07/T-08 regressions 必須維持通過。
- Required verification 必須涵蓋 domain/schema、Fake Provider、Expression widget/action/accessibility、consent、Save/Favorite、stale guard、long/narrow layout、mode switching、Reading regression、format、analyze、test、build 與 truthful visual/evidence artifacts。

## T-09 exclusions

T-09 不包含 T-10 progressive results、streaming、real AI/provider、network/SDK integration、durable persistence、native platform integration、dependency changes、Merge、Auto-merge 或任何 T-10 及後續工作。

## T-10 Progressive results and cancellation

- `AnalysisProvider.analyzeFull` 維持所有 provider 的最低 contract；`ProgressiveAnalysisProviderCapability.analyzePreview` 是 optional capability。
- Application 擁有 `FullOnlyStrategy` 與 `TwoStageStrategy` 選擇；Presentation 不直接選擇 provider method。
- `TwoStageStrategy` 對 deterministic Fake Provider 執行 Preview → Full；沒有 Preview capability 的 provider 必須只執行 Full-only，且不得 fabricate partial 或 silent fallback。
- Preview 必須 bound to `AnalysisMode`、保留 provider identity、提供非空 primary output；Reading primary 是 Translation，Expression primary 是 Natural；Preview 不得序列化為完整 `AnalysisResult`。
- Preview 階段必須可觀察地呈現 `Preview／部分結果`，不得顯示 Full actions；Preview、cancelled、stale、failed 階段不得寫入 full History、Favorite、Feedback 或 Cache。
- Preview failure 必須是 typed error 且可繼續 Full；Full failure 必須保留可用 Preview 並呈現 typed Full error；沒有可用 Preview 時不得產生 partial state。
- New request、cancel、retry 與 dispose 必須取消或失效舊 RequestContext；舊 Preview、Full、cancel 或 error completion 不得覆寫目前 state；retry 必須建立新 RequestId。
- Required regression tests 必須涵蓋 two-stage、full-only、preview failure、partial preservation、cancel during preview/full、stale A/B completion、retry、dispose、Preview identity/accessibility 與 no-action/no-repository boundary。
- T-10 不包含 real provider、network、SDK、CLI、streaming parser、durable persistence、dependency changes、native platform integration、Merge、Auto-merge、T-12 或後續 task。

## T-11 Provider adapters and observability

- `OpenAiResponsesAnalysisProvider` 是唯一新增的 real provider，僅實作 `AnalysisProvider.analyzeFull`；不實作 `ProgressiveAnalysisProviderCapability`，由 `FullOnlyStrategy` 執行。
- 預設 composition 必須使用 deterministic Fake Provider 並保持零 HTTP request；remote provider 只有在 explicit typed configuration、explicit model 與 credential source 同時提供時才啟用，沒有 provider picker UI。
- OpenAI endpoint 固定為 `https://api.openai.com/v1/responses`；request 必須使用 `POST`、Bearer credential、`store: false`、無 tools／web／file／conversation／background 設定，以及 strict JSON Schema Structured Outputs。
- Schema root 與 nested objects 必須設定 `additionalProperties: false`、`strict: true`，required fields 必須完整涵蓋 Reading 與 Expression contract；adapter 固定注入 schema version `3` 與 provider label。
- raw input 只能位於 user input item；system instruction 與 user content 分離。endpoint、Auth header 與 model 不得由 raw input 控制。
- 缺少 configuration 或 credential 時必須在 transport invocation 前回傳 typed error 且不發出 HTTP request；不得靜默 fallback。
- 401／403 映射 `PROVIDER_AUTHENTICATION_FAILED`、429 映射 `PROVIDER_RATE_LIMITED`、refusal 映射 `PROVIDER_REFUSED`、timeout 映射 `PROVIDER_TIMEOUT`、取消映射 `REQUEST_CANCELLED`、malformed／empty／unexpected structured output 映射 `INVALID_STRUCTURED_OUTPUT`，其餘 HTTP／transport failure 映射 `PROVIDER_FAILED`。
- cancellation 必須傳遞至 controlled transport；late success／failure 不得覆寫 Application current RequestId state；T-10 late Preview success、late Preview failure 與 late Full success 都必須有 regression test。
- telemetry 只接受 typed event／metric，default sink 為 bounded in-memory；不得記錄 raw input、prompt、output、response body、clipboard、credential、Auth header、stack trace 或 arbitrary exception。只量測 `provider_setup_ms`、`response_read_ms`、`json_decode_ms`、`total_latency_ms`。
- remote UI disclosure 必須說明 active provider、輸入會傳送至 remote provider、`store=false` 不等於絕對 Zero Data Retention；Fake Provider 必須明確顯示不會發出網路請求。
- T-11 不執行 live paid API、不引入 dependency、不變更 schema version、不進入 T-12 或後續 task、不 Merge、不啟用 Auto-merge。

## T-11 verification boundary

Required evidence 必須記錄 focused tests、完整 `flutter test`、format、analyze、Windows build limitation、Windows host 上 macOS `NOT_RUN`、archive hash、乾淨的 source Repository status 與 Draft PR metadata，且不得包含 raw payload 或 credential。

## T-11R remediation criteria

- `HttpClientAnalysisHttpTransport` 在 request 尚未建立與 request 已建立兩個階段都必須能立即停止工作；取消後不得寫入或傳送 raw user input，transport exception race 必須映射為 typed cancellation。
- Connect、request close 與 response body read 共用一個 provider deadline；不得因分階段重新取得完整 timeout 而倍增總等待時間。
- `maxResponseBytes` 必須以 streaming byte count 限制 response body；exact limit 通過，limit + 1 byte 必須以 sanitized typed failure 結束並關閉連線。
- `provider_setup_ms` 必須涵蓋 configuration validation、credential retrieval 與 request construction 到送出前；`response_read_ms` 必須直接來自 response headers 取得後至 body bytes 完整讀取；`json_decode_ms` 僅涵蓋 typed decode；`total_latency_ms` 涵蓋整次 provider execution。
- `provider_completed` 只能在 HTTP、schema validation 與 typed `AnalysisResult` decode 成功後發出；失敗只能有一個 terminal outcome，且不得先發出 completion。
- Telemetry sink failure 不得改變 application behavior，任何 telemetry／error／UI 都不得包含 raw input、raw response、API key、Authorization header 或完整 prompt。
- `AnalysisPage` 必須顯示 provider-neutral identity；Fake 與 OpenAI Remote disclosure 不得同時宣稱兩種 provider。
- T-11R 僅修正既有 PR #14；T-12 及後續維持 `NOT_AUTHORIZED`，不得執行 live OpenAI API、Merge、Auto-merge 或建立新 PR。

## T-12 Windows desktop integration

- Authorization: `IMPLEMENTATION_AUTHORIZED: T-12`。
- T-11: `ACCEPTED_AND_MERGED`；merge SHA：`10f2d3da98d1fdbdfd2e0abbb39d758a396a6183`。
- T-12 implementation includes Windows global hotkey、UI Automation selected-text
  capture、bounded clipboard fallback、existing-window panel activation、DPI-aware
  work-area clamping、typed failure states、latest-capture-wins guards 與 manual input
  preservation。
- Widgets 不得直接呼叫 Win32、PowerShell、Clipboard API 或 native channel。
- Required default hotkey：`Ctrl+Alt+Space`；registration conflict 必須呈現 typed
  failure 且不得終止 App。
- `flutter pub get`、`dart format`、`flutter analyze`、focused tests、full tests、
  `flutter build windows` 與 `git diff --check` 必須有 exact evidence。
- Required manual registration-success smoke 目前因 host 既有 hotkey owner 為
  `BLOCKED_ENVIRONMENT_MANUAL_HOTKEY`；在該 blocker 未解除前，T-12 不得標示
  `READY_FOR_REVIEW`。
- T-13 及後續：`NOT_AUTHORIZED`；不得執行 live OpenAI API、Merge、Auto-merge 或
  Ready for Review。

## T-12R PR #15 expanded remediation criteria

- `Alt + S` registration 使用明確的 native contract；registration、owner-thread、activation 與 capture failure 均以 typed status 呈現，且不終止 App。
- Native capture 使用 owned operation；不得使用 detached worker。Cancellation、timeout、UI Automation、clipboard fallback 與 cleanup 共用可驗證的生命週期及單一 deadline。
- Clipboard fallback 必須在取消或 timeout 後完成必要 restore／close cleanup；captured draft 只在 panel show 與 activation 成功後更新並取得 focus，失敗不得清除 draft 或錯誤要求 focus。
- Desktop shell 只提供 `分析` 與 `設定`；wide 使用 `NavigationRail`，compact 使用 `NavigationBar`，provider disclosure 必須反映實際選擇。
- Default Provider 為 deterministic Fake。OpenAI 只允許 explicit opt-in，僅有一個 `openai-default` profile；credential 儲存使用 OS secure storage，environment 只作受控後備，不得將 raw key 放入 profile、UI status、telemetry 或 Repository。
- Provider switching 必須由 Application 擁有，保留 draft／mode、取消 active work，並阻擋 late completion 覆寫目前狀態。
- T-12R 不包含 live OpenAI API、T-13、multi-account、failover、custom endpoint、schema v4、無關 dependency upgrade、Merge 或 Auto-merge。
