# ADR-005 Progressive Results

Title: Progressive Results
Status: ACCEPTED
Date: 2026-07-27
Decision owners: Luke、Team Review、Codex 提案

## Context

Progressive output 是產品需求，但實作 mechanism 尚未由 accepted ADR 決定。Two-stage request、streaming structured output、hybrid parsing 與 full-only response 各有 latency、cost、consistency、cancellation 與 test surface trade-off。Provider 不應被迫承擔 Application orchestration。

## Decision

Progressive result 以可替換的 Application-owned `AnalysisExecutionStrategy` 支援。`TwoStageStrategy` 是 optional strategy，不是每個 provider 的必要假設；`FullOnlyStrategy` 是任何 provider 都能使用的安全路徑。

### Enablement policy

```text
T-05 default: FULL_ONLY_FAKE
Real-provider two-stage mode: DISABLED_BY_DEFAULT
```

Real-provider two-stage 只有在下列 evidence 具備，且取得 Product Owner 明確核准後，才可透過 feature flag 或等價的 strategy selection boundary enable：

- provider latency
- request／token cost
- Stage 1 usefulness
- Stage 1／Stage 2 consistency
- cancellation behavior
- stale-result rejection
- partial failure behavior

本 ADR 不捏造 benchmark threshold。Architecture 可先支援 partial state，但不能把尚未證實的 real-provider two-stage 宣稱為 production-ready。

### Result semantics

```text
loading
  → partial（明確標示 preview）
  → success（完整 typed AnalysisResult）
```

- Preview 必須明確標記為 partial。
- Preview 不得以缺少的 sections fabricated 成完整結果。
- Preview 不得寫入 full History。
- 沒有 preview capability 的 provider 必須走 `FullOnlyStrategy`。
- Full-only fallback 不得被回報為 progressive success。
- Stage 1 失敗、Stage 2 失敗、cancel 或 stale result 都必須是可觀察的 typed Application state。

## Architecture boundaries

- `domain` 定義 `AnalysisPreview`、完整 typed result 與 partial semantics，不知道 feature flag 或 provider SDK。
- `application` 選擇 strategy、控制 stage ordering、request identity、cancellation、retry、partial state 與 persistence timing。
- `AnalysisProvider` 至少支援 `analyzeFull`；`analyzePreview` 僅是 ADR-004 定義的 optional capability。
- `presentation` 只呈現 Application state，不直接決定 provider method 或 stage。
- `persistence` 只保存合約允許的 full result；preview cache 若未來授權，必須與 visible History 分離。

## Consequences

- 可以先交付 deterministic full-only fake flow，再以 evidence 決定是否 enable real progressive strategy。
- Strategy 可替換，避免 provider contract、UI 與 persistence 被 two-stage implementation 綁死。
- Two-stage 可能增加 latency、cost 與 consistency risk；這些風險在 real-provider enablement 前必須重新驗證。

## Testing and validation strategy

- `FULL_ONLY_FAKE` 的 loading → success 與 typed failure。
- Two-stage strategy 的 preview → full success、Stage 2 failure、cancel、stale rejection 與 partial failure。
- 無 preview capability 時只執行 full-only path。
- Preview 不寫入 full History，且不能偽裝完整 success。
- feature flag／strategy boundary 的預設值與禁用行為。

## Migration plan

T-05 若獲授權，先實作 `FULL_ONLY_FAKE` 與 explicit Application state。未來在 evidence 與 Product Owner approval 後，才加入 real provider 的 optional preview capability 與 `TwoStageStrategy` enablement。

## Rollback plan

關閉 feature flag 或將 strategy selection 回到 `FullOnlyStrategy`。保留完整 typed result contract 與 partial state model；不得以 JSON fragment、fabricated section 或 silent fallback 取代失敗。

## T-05 implications

T-05 預設只走 `FULL_ONLY_FAKE`。T-05 不要求 real-provider two-stage、streaming parser、provider benchmark、cost threshold 或 durable preview cache。

## Approval

Status: ACCEPTED
Accepted by: Luke, Product Owner
Acceptance source: explicit ChatGPT project instruction
Acceptance date: 2026-07-28
Architecture Review disposition: ACCEPTED_WITH_NON_BLOCKING_FOLLOWUPS
