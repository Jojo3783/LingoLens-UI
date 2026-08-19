# T-04R Architecture Corrections Evidence

Task: T-04R Architecture Correction
Working directory: `D:\GitHub\LingoLens`

## Correction map

| File | Correction |
|---|---|
| `ADR-002-state-management.md` | 將 framework-agnostic Domain contracts 與 Application lifecycle／orchestration state 分離；Riverpod 僅限 Application／composition，`AsyncValue` 不取代 explicit session state。 |
| `ADR-003-persistence-boundary.md` | 將 T-05 限定為 interfaces、deterministic fakes 與 contract tests；Drift／SQLite、schema、migration harness 與 local database file 延後。 |
| `ADR-004-provider-boundary.md` | 定義 full-only `analyzeFull`、optional preview capability 與 Application-owned `AnalysisExecutionStrategy`；禁止 fabricated partial 與 silent Mock fallback。 |
| `ADR-005-progressive-results.md` | 將 two-stage 改為可替換 strategy；T-05 使用 `FULL_ONLY_FAKE`，real-provider two-stage `DISABLED_BY_DEFAULT`，以 evidence 與 Product Owner approval 為 enablement gate。 |
| `ADR-007-platform-boundary.md` | 保留 Platform Adapter 與 security rules；T-05 不建立 speculative unused OS interfaces 或 runtime integration。 |
| `T-04_RISK_REGISTER.md` | 使用四類 gate taxonomy，分開 ADR acceptance、T-05 skeleton 與 future production integration。 |
| `docs/ARCHITECTURE.md` | 同步 Domain／Application、provider、persistence、progressive、platform 與 risk gate summary；保留第一條 manual-input flow。 |
| `handoff.md` | 記錄 PR #4 merged、T-04 `REVISION_REQUIRED`、T-04R authorized、T-05 blocked 與無 production authorization。 |

## Non-goals

本次沒有修改 source Repository、Application Code、Flutter implementation、依賴、donor production code、任何 ADR status，也沒有開始 T-05。
