# T-03 Source Reuse Matrix

## 判定規則

只有同時滿足以下條件，才可標記為 production code reuse：

```text
Technical classification = DIRECT_REUSE_CANDIDATE
Permission status = APPROVED
License compatibility = COMPATIBLE
```

本輪三個來源均未達成完整條件；不複製 source code、不加入 donor dependency、不選定 production base。

## Repository-level matrix

| Source repository | Technical classification | Permission status | License compatibility | T-03 decision |
|---|---|---|---|---|
| `j-neyrox/LingoLens` | `BEHAVIOR_REFERENCE` | `UNKNOWN` | `NO_LICENSE_FOUND` | 僅供 Swift/macOS behavior、domain、testability 參考 |
| `Jojo3783/MVP-flutter-LingoLens` | `CONCEPT_ONLY` | `UNKNOWN` | `NO_LICENSE_FOUND` | 不直接重用；M1 analyzer/test baseline 已失敗 |
| `FUNDAI/Lingolens_flutter_test` | `CONCEPT_ONLY` | `UNKNOWN` | `NO_LICENSE_FOUND` | 不直接重用；可供 Flutter service seam 研究，仍需另行 permission/license decision |

## Module-level candidates

| Source path | Reused behavior | Technical classification | Permission | License | Destination | Decision |
|---|---|---|---|---|---|---|
| Prototype `LingoLens/Query/QueryCoordinator.swift:10-203` | generation guard、cache-first、typed failure、metrics | `BEHAVIOR_REFERENCE` | `UNKNOWN` | `NO_LICENSE_FOUND` | None | 不複製 |
| Prototype `LingoLens/Codex/CodexAnalysisService.swift:10-98` | schema、read-only CLI、temporary files、timeout | `BEHAVIOR_REFERENCE` | `UNKNOWN` | `NO_LICENSE_FOUND` | None | 重新設計，不搬移程式碼 |
| Prototype `LingoLens/Learning/SwiftDataLearningRepository.swift:8-138` | durable record／review model | `CONCEPT_ONLY` | `UNKNOWN` | `NO_LICENSE_FOUND` | None | 僅作 domain comparison |
| M1 `FlutterVersion/lib/lingolens_services.dart:334-386` | Flutter CLI integration shape | `CONCEPT_ONLY` | `UNKNOWN` | `NO_LICENSE_FOUND` | None | silent fallback 使其不適合直接重用 |
| M1 `FlutterVersion/lib/lingolens_services.dart:388-422` | desktop selected-text capture shape | `CONCEPT_ONLY` | `UNKNOWN` | `NO_LICENSE_FOUND` | None | stale clipboard behavior 必須先被重新設計 |
| M2 `lib/services/codex_analysis_service.dart:90-364` | process runner、schema、typed decode | `DIRECT_REUSE_CANDIDATE`（技術面暫定） | `UNKNOWN` | `NO_LICENSE_FOUND` | None | 未經 permission／license approval 不得複製 |
| M2 `lib/repositories/learning_repository.dart:47-268` | Isar transaction、review event | `DIRECT_REUSE_CANDIDATE`（技術面暫定） | `UNKNOWN` | `NO_LICENSE_FOUND` | None | 另需 contract、migration、privacy review |

## Evidence boundary

- Frozen source remote、HEAD、clean status 與 license-file search 記錄於 `docs/evidence/T-03/source-heads.txt` 與 `license-and-permission-evidence.md`。
- Public Git remote 可證明來源位置，不等於 permission grant，也不等於 license compatibility。
- 未發現 `LICENSE`、`COPYING` 或標準 `NOTICE` file；build-generated `NOTICES.Z` 不視為 repository license。
- T-03 不建立 ADR、不決定 provider／persistence／base repository，也不進入 production implementation。
