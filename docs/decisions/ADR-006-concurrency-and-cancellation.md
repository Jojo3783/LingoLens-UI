# ADR-006 Concurrency and Cancellation

Title: Concurrency and Cancellation
Status: ACCEPTED
Date: 2026-07-27
Decision owners: Luke、Team Review、Codex 提案

## Context

T-03 F-003 指出 M1／M2 只有 generation guard，沒有完整終止 underlying process；M2 `CodexProcessRunner` 只在 timeout 時 kill process。Prototype 的 `QueryCoordinator` 有 `requestGeneration`、`Task.isCancelled` 與 stale／cancelled outcomes，但仍需將完整鏈路落到 Flutter Interface。

## Evidence

- Prototype `LingoLens/Query/QueryCoordinator.swift:10-203`：generation、`Task.isCancelled`、cancelled／stale outcomes。
- M1 `FlutterVersion/lib/lingolens_viewmodels.dart:306-407`：generation guard。
- M2 `lib/services/query_coordinator.dart:7-167`：generation guard；`lib/services/codex_analysis_service.dart:90-171`：timeout kill，但無 caller cancellation handle。
- T-03 F-003：`docs/quality/T-03_FINDINGS.md`；security scope：`docs/evidence/T-03/security-observations.md`。

## Decision drivers

- latest-request-wins 必須包含 UI state、application request、provider、network／CLI／process。
- User Cancel、timeout、provider failure、app close 必須可區分。
- 舊結果不得覆寫目前 state；cancelled／partial result 不得誤寫 History。
- Race condition 與 process termination 必須能以 fake／controlled Adapter 驗證。

## Considered options

1. **Request-scoped `CancellationHandle` + generation guard（推薦）**：application 持有 handle，provider／runner 實作真正 cancel。
2. **只有 generation token**：可防 stale UI，但底層 process 繼續執行，正是 T-03 已發現的缺口。
3. **Global cancel flag**：實作簡單，但多 request／多 window 會互相干擾。
4. **Queue all requests**：可保留順序，但違反 latest-request-wins 與增加 outdated work。

## Proposed decision

每個 request 建立不可重用的 `RequestContext`：

```text
RequestId
CancellationHandle
deadline
stage
```

`AnalysisController` 保存目前 request 的 generation 與 handle。新 request 到達時，先 cancel 舊 handle，再建立新 RequestId；任何 async continuation 在更新 state 或 persistence 前，必須驗證 request ID 仍為 current。

Cancellation chain：

```text
UI cancel/new request
→ AnalysisController.cancel(context)
→ AnalysisProvider.cancel(context)
→ Network request cancel / ProcessRunner.kill(context)
→ stream drain close
→ cancelled state
```

Timeout 是 provider／process 的 deadline outcome；User Cancel 是 user intent；兩者都不得被轉成一般 provider failure。Retry 永遠建立新的 RequestId 與新的 handle。Partial result 在取消後可留在 ephemeral UI state，但不寫入 History。

## Architecture boundaries

- Presentation 只發 `cancel`／new intent。
- Application 擁有 request lifecycle、generation、state transition、persistence gate。
- Domain 定義 `RequestId`、`CancellationHandle`、`AnalysisError.REQUEST_CANCELLED`／`PROVIDER_TIMEOUT`。
- Provider Adapter 必須接收 context，並將 cancel 傳給 Network／Process。
- `ProcessRunner` 必須回傳可 kill 的 handle，並定義 kill、exit code、stdout／stderr close、timeout cleanup。

## Consequences

- 可真正停止 CLI／HTTP work，降低 outdated cost 與 side effects。
- Adapter interface 需要 cancellation support，fake runner 也要模擬 delayed／killable behavior。
- App close 需要管理 active handles，避免 background process 殘留。

## Trade-offs

Request context 比單純 generation integer 複雜，但能把 correctness guard 與 resource cancellation 同時驗證。若某 platform 不支援真正 cancel，Adapter 必須回報 capability／limitation，不得宣稱完全取消。

## Risks

- Cancel race 可能在 persistence write 前後發生，需以 transaction gate 與 current check 保護。
- Process kill 後 stdout／stderr stream completion 順序不固定，runner 必須只完成一次。
- 多 floating window 共用 controller 時，request scope 可能誤互相取消；scope 需明確決定。

## Security／privacy implications

Cancel 後應清理 provider prompt、raw output buffer 與 temporary result file；不可讓 cancelled request 進入 default Log。Process termination 需限制在由該 RequestContext 建立的 process，不能 kill 非本 request process。

## Testing／validation strategy

- Race condition：slow old request 與 fast new request。
- Stale result rejection：old preview／full result 不更新新 state。
- Latest-request-wins：new request 先 cancel old handle。
- Provider timeout：deadline 與 user cancel 分開驗證。
- User cancellation：runner receives cancel，process termination observable。
- Process termination：fake／controlled runner 驗證 kill、stream close、single completion。
- Partial success：preview 可留 ephemeral，但不能 persistence。
- App close：all active handles cancelled，無 process leak。

## Migration plan

先在 Fake Provider／Fake ProcessRunner 建立 RequestContext 與 tests，再把 Codex Adapter 接上可 kill process。Existing generation guard 只能作 transitional stale check，不作 final cancellation contract。

## Rollback plan

若某 provider 暫時不能取消，停用該 Adapter 或將 capability 明確標示為 unsupported；不得退回宣稱 true cancellation 的假實作，也不得允許其進入 T-05 default flow。

## Open questions

- App close 的 cancel grace period 是否由 Product Owner 指定？
- 多 window 是否共用一個 AnalysisController，或每個 window 各自 request scope？
- Provider timeout 的預設 deadline 是否固定 60 秒，或依 stage／provider 設定？

## T-05 implications

T-05 只建立 fake cancellation abstraction 與 state tests；不得啟動 real CLI／HTTP process。此 ADR 已接受，T-05 仍受本次明確 scope 限制。

## Approval

Status: ACCEPTED
Accepted by: Luke, Product Owner
Acceptance source: explicit ChatGPT project instruction
Acceptance date: 2026-07-28
Architecture Review disposition: ACCEPTED_WITH_NON_BLOCKING_FOLLOWUPS
