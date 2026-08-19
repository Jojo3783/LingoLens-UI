# ADR-003 Persistence Boundary

Title: Persistence Boundary
Status: ACCEPTED
Date: 2026-07-27
Decision owners: Luke、Team Review、Codex 提案

## Context

T-03 顯示 History、Cache、Settings、Favorite 與 Feedback 有不同的 privacy、retention 與 mutation semantics。M1、M2 與 Prototype 的 durable repository 可作 behavior reference，但不能在 T-05 尚未核准時推導出 Drift、SQLite 或 schema implementation。

## Decision

Domain 先定義最小 persistence interfaces，Application 定義可觀察的 mutation policy，Infrastructure 未來再提供 durable adapter。

T-05 persistence scope 僅限於：

- `HistoryRepository` 與必要的最小 repository interfaces。
- deterministic in-memory 或 fake implementations。
- interface tests 與 repository contract tests。
- History、Cache、Settings、Favorite、Feedback 的 isolation 與 consent semantics。

T-05 明確不包含：

- Drift dependency。
- SQLite runtime。
- local database file。
- database schema。
- migration harness。
- durable storage adapter。

Drift／SQLite 仍是未來可提出的 durable implementation proposal，不是本 ADR 對 T-05 的授權。

### Logical ownership and retention

```text
HistoryRecord       visible query history and favorite state
AnalysisCache       provider/model/schema/prompt-version keyed cache
Settings            local preferences and history-write toggle
Feedback            structured reason and explicitly consented payload
```

visible history limit `20` 是 UI／Domain retention policy，不等同於 physical database retention limit `20`。本 ADR 不授權 destructive physical eviction policy。Favorite record 受保護，不因 visible-history limit 自動 eviction；user-triggered delete 與 cache clear 必須維持分離。

## Architecture boundaries

- `domain` 定義 repository interfaces 與 record contract，不依賴 Drift、SQLite 或 Isar。
- `application` 決定 history-write toggle、user-triggered delete、favorite pinning 與 cache／history isolation。
- `infrastructure` 未來才可放 durable adapter、schema、migration 與 transaction implementation。
- `presentation` 不得直接 import database package 或 raw query。

## Consequences

- T-05 可用 deterministic fake 驗證 contract，不需要 dependency restore 或 local database state。
- Durable implementation 的 schema、migration、locking、backup 與 clear policy 可在獨立 ADR 中提出。
- visible history limit 與 physical retention 不會被錯誤綁定。
- Cache 不會因為 reuse record model 而自動變成 visible History。

## Testing and validation strategy

- 驗證 History、Cache、Settings、Favorite 與 Feedback 的 isolation。
- 驗證 visible history limit `20`、favorite non-eviction、history-write toggle 與 user-triggered delete。
- 驗證 feedback payload 只有在明確 consent 後才附帶 input/output。
- T-05 只使用 in-memory／fake contract tests；不得以 Drift runtime 或 SQLite file 作為測試前提。

## Migration plan

1. 定義 Domain repository interfaces 與 deterministic fake。
2. 以 contract tests 鎖定 isolation、favorite 與 retention semantics。
3. 未來另行提出 durable storage ADR，再決定 Drift／SQLite 或其他實作、schema 與 migration。

## Rollback plan

若 durable storage proposal 未獲接受，保留 Domain interfaces 與 fake implementations，替換 infrastructure adapter。不得為了繞過 review 而加入 SQLite runtime 或 schema。

## T-05 implications

T-05 只建立 interfaces、deterministic fakes 與 contract tests。T-05 不得建立 Drift dependency、SQLite runtime、schema、migration harness 或 local database file。T-05 也不得將 visible history `20` 解讀為 physical database retention `20`。

## Approval

Status: ACCEPTED
Accepted by: Luke, Product Owner
Acceptance source: explicit ChatGPT project instruction
Acceptance date: 2026-07-28
Architecture Review disposition: ACCEPTED_WITH_NON_BLOCKING_FOLLOWUPS
