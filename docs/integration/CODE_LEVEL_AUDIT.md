# T-03 Code-Level Audit

## frozen scope

| Source | Frozen HEAD | Application root |
|---|---|---|
| Prototype | `40e8d70e8e9bf336a2f66cf811736061831c2964` | `LingoLens/`，Swift/macOS Xcode project |
| Merged Model 1 | `76a3826ce69827456b7c305018b629f1c22f4bd6` | `FlutterVersion/` |
| Merged Model 2 | `df4f5424e8abfedc52f941c8c5c2f1a9463e8aac` | Repository root |

所有 source Repository 在審查前後均為 clean。Codebase Memory indexing 僅寫入 disposable clone 的 `.codebase-memory/` artifact，未寫入 `D:\GitHub\temp` 或官方 Repository。

## 主要 symbol 與控制流程

### Prototype

- `LingoLens/Query/QueryCoordinator.swift:10-203`：依賴 `SelectedTextReading`、`SentenceAnalyzing`、`LearningRepository` 與 `QueryState`；以 generation、`Task.isCancelled`、stale／cancelled outcome 實作 latest-request guard。
- `LingoLens/Codex/CodexAnalysisService.swift:10-98`：透過 injected runner／locator／schema；建立 temporary directory，使用 `--sandbox read-only`、`--output-schema`、`--output-last-message`，60 秒 timeout 後 decode typed response。
- `LingoLens/Learning/SwiftDataLearningRepository.swift:8-138`：以 SwiftData 儲存 query、favorite、note、review state 與 `ReviewEvent`；未見 visible history 20-record eviction 或獨立 cache store。
- `LingoLens/Query/GlobalHotkeyManager.swift:9-79`：Carbon registration，失敗會 throw，`stop`／`deinit` 會 unregister。
- `LingoLens/Panel/FloatingPanelController.swift:4-107`：NSPanel floating、Esc、outside-click 與 speech stop 行為。

### Merged Model 1

- `FlutterVersion/lib/lingolens_viewmodels.dart:306-407`：generation 可避免 stale state，但沒有 explicit `Task.isCancelled` check。
- `FlutterVersion/lib/lingolens_services.dart:334-386`：`RealCodexAnalysisService` 沒有 output schema；Codex executable missing、non-zero exit、decode failure 皆回傳 `MockCodexAnalysisService`，會將 operational failure 轉成 fabricated success。
- `FlutterVersion/lib/lingolens_services.dart:42-236`：`InMemoryLearningRepository` 在 constructor seed demo data；cache／records 都是 process-local memory，沒有 durable persistence。
- `FlutterVersion/lib/lingolens_services.dart:388-422`：`GlobalSelectedTextReader` 清空／讀取／復原 clipboard；25 次 polling 失敗時回傳原本 clipboard text，可能把非目前 selection 的資料送進 analysis。
- `FlutterVersion/lib/main.dart:137-181`：每 500ms monitor clipboard；遇到含 English 且長度 2-500 的文字自動 query，並以 `print` 輸出原文。`_initHotkey()` 為空。

### Merged Model 2

- `lib/services/query_coordinator.dart:7-167`：generation 防止 stale UI update，但 analyzer 的 underlying process 沒有 request-scoped cancellation handle。
- `lib/services/codex_analysis_service.dart:90-171`：`Process.start` 不使用 shell，stdout／stderr 持續 drain，timeout 會 kill process；runner API 沒有暴露 caller cancellation。
- `lib/services/codex_analysis_service.dart:173-364`：有 `additionalProperties: false` schema、safe argument array、temporary files 與 typed `SentenceAnalysis.fromJson`；但 debug Log 含 raw input、prompt preview、schema、stderr，fallback path 仍可能遮蔽非 typed exception。
- `lib/repositories/learning_repository.dart:47-268`：`IsarLearningRepository` 使用 durable Isar transaction 與 `ReviewEvent`；未見 cache／history separation 或 visible history 20-record cap。
- `lib/services/selected_text_service.dart:65-99`：Accessibility 失敗時 fallback clipboard，並以 `TextNormalizer.maximumCharacterCount` 驗證長度。
- `lib/services/speech_service.dart:13-103`：`SystemSpeechEngine` 在 Windows fallback 至 PowerShell SAPI；文字先做 quote replacement，但仍是動態 command string，需 boundary hardening。
- `lib/services/hotkey_service.dart:5-42`：system `Ctrl + Space`；註冊錯誤只寫 Log，未形成可見 recovery state。

## Findings by code path

### F-001：silent Mock fallback 破壞 provider failure integrity

`Merged Model 1` 在 executable missing、process failure、result missing 或 JSON decode failure 時回傳 `MockCodexAnalysisService`。UI 可能顯示看似成功的分析，卻未告知使用者真實 provider failure；這也使測試與 telemetry 無法區分 live result 與 fallback result。

### F-002：raw input／provider output 進入 debug Log

`Merged Model 1` 的 clipboard monitor 直接輸出 `$text`；`Merged Model 2` 的 `CodexAnalysisService` 輸出 raw text、prompt preview、stderr，`CodexProcessRunner` 輸出每段 stdout／stderr。這些內容可能含使用者原文、provider response、檔案路徑或診斷資料。

### F-003：latest-request wins 尚未等於 underlying cancellation

三個 reference 都有 generation/stale guard；Prototype 還檢查 `Task.isCancelled`。M1/M2 的 generation 只阻止舊結果更新 state，沒有保證 CLI process、stream 或 HTTP work 在新 request 到達時停止，因此仍可能浪費資源並保留 side effect。

### F-004：clipboard scope 與 stale data semantics 不安全

M1 會自動監視 clipboard 並觸發 query；capture failure 時返回舊 clipboard text。這同時造成 unannounced data capture 與 correctness/privacy risk。Prototype 的 clipboard restoration tests 顯示較成熟的 restoration boundary，但仍不能直接轉成 Flutter code。

### F-005：PowerShell TTS command 需要 boundary hardening

M2 使用 `Process.start('powershell', ['-Command', psCommand])` 並把使用者文字內插至 PowerShell command；quote replacement 是部分 escaping，尚未證明可涵蓋 PowerShell parsing edge cases。此審查將其標為 hardening finding，不宣稱已證實可利用的 RCE。

### F-006：MVP persistence contract 未被任何 source 完整證明

M1 是 in-memory；M2 與 Prototype 是 durable record store，但 inspected code 均未證明 cache 與 visible history 分離，也未證明 visible history limit 20 且 favorites 不被 eviction。這是 contract gap，不是 T-03 允許修正的範圍。

## T-02 failure root-cause mapping

| Source | Command | Observed result | Root-cause classification | 信心 |
|---|---|---|---|---|
| Merged Model 1 | `flutter analyze` | 63 issues；多個 undefined symbol | `SOURCE_CODE_DEFECT`，含 stale／incomplete feature wiring | HIGH |
| Merged Model 1 | `flutter test` | `test/widget_test.dart` 找不到 `MyApp` constructor | `TEST_DEFECT`／test-to-source contract mismatch | HIGH |
| Merged Model 1 | `flutter build windows` | 找不到 Visual Studio CMake executable | `TOOLCHAIN_ENVIRONMENT` | HIGH |
| Merged Model 2 | `flutter analyze` | 29 issues；async gap、generated Isar warnings、unused imports | `SOURCE_CODE_DEFECT`，部分為 generated／lint configuration noise | MEDIUM |
| Merged Model 2 | `flutter test` | 46 tests passed | `PASS`，但不等於 analyze/build 全部通過 | HIGH |
| Merged Model 2 | `flutter build windows` | 找不到相同 CMake executable | `TOOLCHAIN_ENVIRONMENT` | HIGH |

T-03 沒有重新執行 Flutter commands；上述結果沿用 T-02 evidence。
