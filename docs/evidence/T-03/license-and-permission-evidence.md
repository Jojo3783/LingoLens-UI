# T-03 License and Permission Evidence

## Repository metadata

| Source | Remote | Frozen HEAD | Source status | Standard license search |
|---|---|---|---|---|
| Prototype | `https://github.com/j-neyrox/LingoLens` | `40e8d70e8e9bf336a2f66cf811736061831c2964` | clean | no tracked `LICENSE`／`COPYING`／`NOTICE` |
| Merged Model 1 | `https://github.com/Jojo3783/MVP-flutter-LingoLens` | `76a3826ce69827456b7c305018b629f1c22f4bd6` | clean | no tracked `LICENSE`／`COPYING`／`NOTICE` |
| Merged Model 2 | `https://github.com/FUNDAI/Lingolens_flutter_test` | `df4f5424e8abfedc52f941c8c5c2f1a9463e8aac` | clean | no tracked `LICENSE`／`COPYING`／`NOTICE` |

Remote URL 只能確認 public repository location，不能取代作者 permission 或 license grant。Merged Model 1／2 disposable build output 中出現 `NOTICES.Z`，但該檔案不是 tracked standard license file。

## Reuse decisions

| Source/module | Technical classification | Permission status | License compatibility | Allowed use in T-03 |
|---|---|---|---|---|
| Prototype query／Codex／SwiftData／panel modules | `BEHAVIOR_REFERENCE` 或 `CONCEPT_ONLY` | `UNKNOWN` | `NO_LICENSE_FOUND` | 只讀、記錄 behavior 與 boundary |
| Merged Model 1 service／view model modules | `CONCEPT_ONLY` | `UNKNOWN` | `NO_LICENSE_FOUND` | 只讀能力盤點；不複製 |
| Merged Model 2 Codex／Isar／desktop service modules | 技術面可列 `DIRECT_REUSE_CANDIDATE`，但尚未核准 | `UNKNOWN` | `NO_LICENSE_FOUND` | 僅記錄候選；不複製 |

## Required provenance before any reuse

任何未來 copied or materially adapted module 必須補齊：source repository、source commit、source path、original author、destination、behavior reused、code changes、permission evidence、license status、tests reused／rewritten、verification result。T-03 未產生任何 destination code，也沒有 source copy。
