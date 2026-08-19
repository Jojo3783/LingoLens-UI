# ADR-004 Provider Boundary

Title: Provider Boundary
Status: ACCEPTED
Date: 2026-07-27
Decision owners: Luke、Team Review、Codex 提案

## Context

T-03 的 Prototype、M1 與 M2 都顯示 provider 需要 typed request／result、schema decode、timeout、cancellation、observability 與 failure mapping。原本單一 `analyze` contract 無法清楚表達 full-only provider 與 optional progressive capability 的差異，也容易把 orchestration 責任推給每個 provider。

## Decision

每個 provider 都必須支援 full typed analysis；progressive preview 是明確的 optional capability。Application 擁有 execution strategy，UI 不得直接選擇 provider method。

```text
AnalysisProvider
  analyzeFull(request, context) -> Future<AnalysisResult>

ProgressiveAnalysisProviderCapability（optional）
  analyzePreview(request, context) -> Future<AnalysisPreview>

AnalysisExecutionStrategy（Application-owned）
  FullOnlyStrategy
  TwoStageStrategy
```

`AnalysisResult` 使用 shared envelope，並包含 distinct typed `ReadingAnalysis` 與 `ExpressionAnalysis`；`AnalysisError` 必須保留 provider not found、timeout、cancelled、invalid structured output、provider failed 與 configuration error 等可觀察分類。

### Contract invariants

- Full-only 是所有 provider 的共同最低 contract。
- Preview capability 必須明確宣告；沒有 capability 的 provider 必須走 full-only path。
- Unsupported preview 不得 fabricate partial output。
- Provider 不得靜默 fallback 到 Mock success；任何 fallback 都必須是明確、可觀察且另經核准的 policy。
- Provider failure 必須以 typed error 回到 Application，不能轉成 false success。
- UI 只提交 intent 並觀察 Application state，不直接呼叫 `analyzeFull` 或 `analyzePreview`。

## Architecture boundaries

- `domain` 定義 `AnalysisRequest`、`AnalysisResult`、`AnalysisPreview`、`AnalysisError` 與相關 contracts。
- `application` 選擇 `AnalysisExecutionStrategy`、管理 request lifecycle、partial semantics、retry、cancel 與 stale-result rejection。
- `infrastructure/provider` 實作 Fake、Codex CLI、Remote API 或 Local adapters，並處理 typed decode、timeout 與 redacted telemetry。
- `ProcessRunner` 位於 infrastructure seam；raw user input 不得進入 shell command string。

## Consequences

- Full-only provider 可在沒有 progressive implementation 時交付一致 contract。
- Two-stage 只需要在有 capability 且 Application 選擇該 strategy 時執行。
- Provider adapter 不必為了產品 progressive requirement 複製相同的 stage orchestration。
- Contract tests 必須覆蓋 full-only、optional preview、typed failure、unsupported capability 與 cancellation。

## Testing and validation strategy

- `FakeAnalysisProvider` 的 full result、typed failure、timeout 與 cancellation。
- 有 preview capability 與無 capability provider 的 strategy routing。
- Unsupported preview 不產生 partial result；silent Mock fallback 會被測試拒絕。
- Provider failure、schema decode、bounded output、redacted Log 與 stale-result rejection。

## Migration plan

先建立 full-only Domain contract 與 deterministic Fake Provider，再由 Application 加入 strategy seam。只有具備證據且獲得授權的 provider adapter 才可加入 progressive capability；M1／M2 implementation 僅作 behavior reference。

## Rollback plan

若 progressive capability 不穩定，Application 回到 `FullOnlyStrategy`；保留 full typed contract，不以 fabricated preview 或 silent Mock fallback 填補缺口。

## T-05 implications

T-05 只建立 full-only `FakeAnalysisProvider` 與可測試的 Application strategy seam。T-05 不建立 real CLI、Remote API、Local model、credential flow 或 provider-specific progressive implementation。

## Approval

Status: ACCEPTED
Accepted by: Luke, Product Owner
Acceptance source: explicit ChatGPT project instruction
Acceptance date: 2026-07-28
Architecture Review disposition: ACCEPTED_WITH_NON_BLOCKING_FOLLOWUPS
