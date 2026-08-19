# T-03 Capability Matrix

## 審查範圍

本矩陣以三個 frozen source HEAD 為基準，僅描述現有能力、測試證據與整合風險。它不是 production implementation authorization，也不代表任何 source code reuse 已獲核准。

| 能力 | Prototype | Merged Model 1 | Merged Model 2 | T-03 判定與證據 |
|---|---|---|---|---|
| Selected-text capture | macOS Accessibility 加 clipboard fallback；有 restoration tests | `GlobalSelectedTextReader` 以 clipboard、`osascript`、PowerShell `SendKeys` 取得文字；失敗時可能回傳舊 clipboard | Accessibility／clipboard abstraction；有長度上限檢查 | M2 架構較完整；M1 的 stale clipboard fallback 是 P2 privacy／correctness 風險。 |
| Global hotkey | Carbon `Option + Space`，有 registration／cleanup error handling | `_initHotkey()` 為空，hotkey 暫停 | `HotkeyService` 使用 `Ctrl + Space`、system scope；registration error 僅寫 Log | Prototype 行為參考較完整；M2 可作 integration candidate；M1 不可宣稱已具備。 |
| Floating panel | `NSPanel`、outside-click、Esc、multi-space | 未見等價穩定 abstraction | `FloatingWindowService` 含 Windows HWND、topmost、click-outside、self-heal | M2 有最多 desktop integration surface，但仍需隔離 platform service 與測試。 |
| Codex provider | typed error、JSON Schema、read-only sandbox、temporary files、60 秒 timeout | 無 `--output-schema`；process／解析錯誤全部回退 Mock | JSON Schema、safe argument array、temporary files、typed parse；可選 fallback | M1 silent fallback 會把失敗轉成偽成功；M2 schema path 較接近 contract。 |
| Latest request wins | generation、`Task.isCancelled`、stale／cancelled outcome | generation 防 stale state，但沒有 `Task.isCancelled` explicit check | generation 防 stale state；underlying process 僅 timeout kill | 三者皆需實作 request-scoped cancellation；M1/M2 目前未滿足完整 contract。 |
| Persistence | SwiftData durable repository | `InMemoryLearningRepository`，含 demo seed | Isar durable repository | M2 有可用 persistence skeleton；M1 只能作 UI／behavior reference。 |
| Cache／history separation | 目前共用 record lookup，未見獨立 cache store | cache 與 history 共用 in-memory structures | cache 與 history 共用 Isar records | 三者均未證明符合 MVP 的 cache separation contract。 |
| Visible history limit 20 | inspected repository 未見 eviction | 未見 limit | 未見 limit | 未驗證；不可在 T-03 自行補作。 |
| Favorite／review | SwiftData record fields、review event、scheduler | in-memory favorite／review／scheduler | Isar record／ReviewEvent／scheduler | domain behavior 可作參考；durability、migration 與 UI contract 仍待後續 task。 |
| Speech | injected `SpeechEngine`、stop-before-speak | `say`／PowerShell SAPI process | `flutter_tts` 加 PowerShell SAPI fallback | M2 abstraction 較清楚；PowerShell command construction 需 hardening。 |
| Observability | `QueryPerformanceTimer` 記錄 cache、Codex、save、state outcome | 主要為 `debugPrint` | `debugPrint` 記錄原文、prompt preview、stdout／stderr | Prototype 可作 observability reference；M2 logging 有 P2 privacy exposure。 |
| Tests | 多個 Swift unit tests 覆蓋 coordinator、Codex、clipboard、panel、speech、review | T-02 `flutter test` FAIL，且 source compile contract 不完整 | T-02 `flutter test` PASS 46，但 `flutter analyze` FAIL | 測試數量不是 production readiness；需保留 T-02 failure diagnostics。 |
| Platform coverage | macOS/Xcode only | Flutter desktop scaffold，Windows／macOS code paths | Flutter desktop scaffold，Windows／macOS code paths | Windows build 均受 host CMake discovery 阻擋；macOS 未在本機驗證。 |

## 結論

- Prototype 是 behavior、domain boundary、cancellation、testability 的 macOS reference。
- Merged Model 2 是 Flutter integration candidate，但仍有 analyzer failure、privacy logging、process cancellation 與 history contract 缺口。
- Merged Model 1 是 broad UI／feature reference，不是可直接採用的 production base；其 analyzer／test baseline 已失敗，且 runtime fallback 會隱藏 provider failure。
- T-03 不選定 base repository、不複製程式碼、不接受 ADR，也不開始 T-04 或 T-05。
