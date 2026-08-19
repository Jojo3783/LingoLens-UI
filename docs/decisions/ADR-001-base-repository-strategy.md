# ADR-001 Base Repository Strategy

Title: Base Repository Strategy
Status: ACCEPTED
Date: 2026-07-27
Decision owners: Luke、Team Review、Codex 提案

## Context

T-02 顯示 Prototype 是 Swift/macOS Xcode project；Merged Model 1 與 Merged Model 2 是 Flutter candidates，但兩者的完整 baseline 都未達 green。T-03 也顯示 Merged Model 1 有 source／test wiring defects 與 silent Mock fallback，Merged Model 2 有 analyzer、privacy logging、cancellation、history contract 與 platform hardening 缺口。三個 source 均未找到標準 License file，permission status 為 `UNKNOWN`。

## Evidence

- Source metadata：`docs/integration/SOURCE_BASELINES.md`、`docs/evidence/T-02/metadata.txt`。
- T-02 results：`docs/integration/BUILD_AND_TEST_REPORT.md`、`docs/evidence/T-02/command-results.md`。
- T-03 findings：`docs/quality/T-03_FINDINGS.md`，F-001、F-006、F-007、F-008。
- T-03 reuse boundary：`docs/reuse/SOURCE_REUSE_MATRIX.md`。
- Frozen source commits：Prototype `40e8d70e8e9bf336a2f66cf811736061831c2964`；M1 `76a3826ce69827456b7c305018b629f1c22f4bd6`；M2 `df4f5424e8abfedc52f941c8c5c2f1a9463e8aac`。

## Decision drivers

- 先建立可驗證、可回滾的 Flutter layer，而不是先搬移 donor application。
- 將 permission／license uncertainty 與 production code scope 分離。
- 保留 Prototype 的 behavior evidence 與 M2 的 interface ideas，但不複製 implementation。
- 讓 T-05 可在官方 Repository 內由小範圍 fake-provider skeleton 開始。

## Considered options

1. **Clean Flutter Skeleton（推薦）**：在官方 Repository 建立新的最小 Flutter structure；donor 只作 behavior／concept reference。
2. **Merged Model 2 作為 base**：保留 Isar、desktop plugins、service files，再逐步修正。
3. **Merged Model 1 作為 base**：保留 broad UI 與 Swift-aligned names，再補齊遺失 symbol。
4. **Prototype 作為 base**：不符合 Flutter Desktop implementation target，只能作 macOS behavior reference。

## Proposed decision

推薦 **Clean Flutter Skeleton**。T-05 只在此方案獲 Team Review 確認後，建立最小 layer 與 fake provider flow。任何 donor module 必須另有 provenance record，並同時符合：

```text
DIRECT_REUSE_CANDIDATE + APPROVED + COMPATIBLE
```

目前沒有任何 donor code 達成這三項條件，因此 T-05 scope 不預先包含 donor production code。

## Architecture boundaries

官方 Repository 的初始 structure 應採：`presentation → application → domain`；`infrastructure` 與 `platform` Adapter 只透過 domain／application Interface 被使用。Donor source 位於 boundary 外，不能被 runtime import。

## Consequences

- Initial implementation cost 較高，因為需要重新建立 composition root、typed domain contracts 與 tests。
- Rework risk 較低，因為不必先拆解 M1/M2 的 existing architecture debt。
- Provenance cost 較低，因為 reference notes 不會被誤當成 copied code。
- Testing impact 較正面，可從 fake provider 與 Interface test 開始。
- Cross-platform impact 較可控，Windows／macOS Adapter 由同一組 Interface 約束。

## Trade-offs

犧牲短期 UI reuse 速度，換取明確 dependency direction、較小 rollback surface 與 permission safety。M2 的 durable persistence 與 desktop behavior 不會自動帶入，後續需依 ADR-003、ADR-007 重新設計。

## Risks

- T-05 若未先明確記錄 skeleton structure，可能再次出現 application root 或 composition root 漂移。
- 若 Product Owner 後續核准 donor reuse，仍需逐 module 重新做 license／permission／provenance review。

## Security／privacy implications

Clean skeleton 可避免把 M1/M2 的 raw logging、silent fallback、PowerShell command construction 帶入新 runtime。T-05 不得將使用者原文、credential、local database 或 donor generated artifact 帶入 Repository。

## Testing／validation strategy

- 驗證官方 Repository 沒有 donor import 或 donor path dependency。
- 以 fake provider 驗證 manual input → typed result → UI state。
- 以 static search 確認 Widgets 沒有直接呼叫 platform／process／persistence。
- 保留 source commit 與 provenance evidence，不宣稱 donor runtime verification。

## Migration plan

1. 建立 empty Flutter skeleton 與 layer directories。
2. 先建立 domain／application Interface，再以 fake Adapter 驗證。
3. 只有取得明確 reuse permission／license evidence 後，才評估 selective adaptation。

## Rollback plan

刪除 T-05 skeleton branch 或 revert 該 branch 的 documentation／code commits；不需修改任何唯讀 source。若 donor permission 未解決，維持 clean skeleton 並移除候選 import。

## Open questions

- Product Owner 是否接受 Clean Flutter Skeleton 作為 T-05 base strategy？
- 是否有可補充的 source permission 或 license evidence？
- 是否需要由 Team Review 指定一個 donor 只作 behavior benchmark？

## T-05 implications

本 ADR 已接受。T-05 採用 Clean Flutter Skeleton；本次 implementation 僅限於已授權的 manual-input vertical slice。

## Approval

Status: ACCEPTED
Accepted by: Luke, Product Owner
Acceptance source: explicit ChatGPT project instruction
Acceptance date: 2026-07-28
Architecture Review disposition: ACCEPTED_WITH_NON_BLOCKING_FOLLOWUPS
