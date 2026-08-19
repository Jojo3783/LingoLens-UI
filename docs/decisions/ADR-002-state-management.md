# ADR-002 State Management

Title: State Management
Status: ACCEPTED
Date: 2026-07-27
Decision owners: Luke、Team Review、Codex 提案

## Context

T-03 的 Prototype、M1 與 M2 都顯示 request generation、cancellation、typed outcome、progressive result 與 stale-result rejection 需要明確的生命週期協調。這些責任不能由 Widget local state、provider SDK 或 persistence adapter 分散承擔。

## Decision

採用分層的 state ownership。Domain 定義 framework-agnostic 的業務契約；Application 定義 request lifecycle 與 orchestration；Riverpod 僅可作為 Application／composition wiring 的實作選擇。

### Domain contracts

Domain 可包含下列不依賴 Flutter、Riverpod 或 Widget lifecycle 的型別與契約：

```text
AnalysisRequest
AnalysisResult
ReadingAnalysis
ExpressionAnalysis
AnalysisError
RequestId
cancellation contract（例如可取消的 request context 或 cancellation handle）
```

`AnalysisResult` 使用 shared envelope，並保留 distinct typed `ReadingAnalysis` 與 `ExpressionAnalysis`。Domain 不持有 loading、partial、retry 或目前 Widget 的狀態。

### Application lifecycle

Application 擁有目前 request 的 orchestration state，例如：

```text
AnalysisSessionState
AnalysisPhase: idle | loading | partial | success | failure | cancelled
AnalysisController
current RequestId
retry
manual mode override
automatic mode suggestion
stale-result rejection
```

`AsyncValue` 不得取代這份 explicit application session state。Application 必須能表達 partial、cancelled、stale rejection、manual override 與 typed failure 等產品契約；Riverpod 的 provider lifecycle 或 `AsyncValue` 只能承載或組合這些狀態，不能重新定義 Domain contract。

## Architecture boundaries

- `presentation` 只提交 user intent 並觀察 `AnalysisSessionState`，不得直接選擇 provider method。
- `application` 建立 request、選擇 `AnalysisExecutionStrategy`、管理 request lifecycle、retry、cancel 與 stale-result rejection。
- `domain` 保持 framework-agnostic typed models、errors、request identity 與 cancellation contract。
- `infrastructure` 實作 provider、persistence 與 process 等 adapters。
- Riverpod 若採用，位置限於 Application／composition wiring；Domain 不得 import Riverpod。

## Consequences

- Domain contract 可在沒有 Flutter framework 的情況下進行 unit 與 contract test。
- Application lifecycle 可測試 loading、partial、success、failure、cancelled、retry、override 與 stale-result race。
- Provider、repository 與 platform adapter 的替換不會迫使 Domain 知道 framework。
- Riverpod scope、disposal 與 cross-window state isolation 仍需要 Application 層測試。

## Testing and validation strategy

- 驗證 automatic suggestion 與 manual override 的優先順序。
- 驗證 request phase transitions、typed failure、cancelled state 與 retry。
- 驗證較舊 `RequestId` 的結果不能覆寫目前 session。
- 驗證 Domain tests 不需要 Riverpod 或 Widget。
- 驗證 Riverpod wiring 只覆蓋 Application／composition seam，不把 framework 型別帶入 Domain。

## Migration plan

先定義 framework-agnostic Domain contracts，再由 Application 建立 `AnalysisController` 與 explicit `AnalysisSessionState`。Riverpod Notifier 或其他 composition wiring 只負責連接 Application 與 Presentation。M1／M2 state code 僅作 behavior reference，不直接複製。

## Rollback plan

若 Team Review 不接受 Riverpod，保留 Domain 與 Application contract，替換 Application／composition wiring。不得將 framework lifecycle state 搬回 Domain，也不得以 Widget local state 取代 session contract。

## T-05 implications

T-05 若獲得後續授權，僅建立 framework-agnostic Domain models、Application session state、deterministic Fake Provider 與相關 tests。T-05 不得因 Riverpod 選擇而把 Riverpod import 放入 Domain，也不得提前建立未授權的 platform 或 durable persistence implementation。

## Approval

Status: ACCEPTED
Accepted by: Luke, Product Owner
Acceptance source: explicit ChatGPT project instruction
Acceptance date: 2026-07-28
Architecture Review disposition: ACCEPTED_WITH_NON_BLOCKING_FOLLOWUPS
