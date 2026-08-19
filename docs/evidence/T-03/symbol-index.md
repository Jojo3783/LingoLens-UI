# T-03 Symbol Index

本索引由 Codebase Memory `search_graph`、`get_code_snippet`、`search_code` 與 `get_architecture` 產生；下列行號以 frozen disposable clone 為準。

## Prototype

| Symbol | Path and lines | Role |
|---|---|---|
| `QueryCoordinator` | `LingoLens/Query/QueryCoordinator.swift:10-203` | query state、cache、analysis、persistence、generation、cancellation |
| `CodexAnalysisService` | `LingoLens/Codex/CodexAnalysisService.swift:10-98` | CLI、schema、temporary files、timeout、typed decode |
| `SwiftDataLearningRepository` | `LingoLens/Learning/SwiftDataLearningRepository.swift:8-138` | durable records、favorites、notes、review events |
| `GlobalHotkeyManager` | `LingoLens/Query/GlobalHotkeyManager.swift:9-79` | Carbon hotkey register/unregister |
| `FloatingPanelController` | `LingoLens/Panel/FloatingPanelController.swift:4-107` | NSPanel、outside-click、Esc、speech stop |
| `SpeechService` | `LingoLens/Speech/SpeechService.swift:12-37` | injected speech engine、stop-before-speak |

## Merged Model 1

| Symbol | Path and lines | Role |
|---|---|---|
| `QueryCoordinator` | `FlutterVersion/lib/lingolens_viewmodels.dart:306-407` | generation guard、cache、analysis、save |
| `InMemoryLearningRepository` | `FlutterVersion/lib/lingolens_services.dart:42-236` | demo seed、process-local cache/history、favorite/review |
| `MockCodexAnalysisService` | `FlutterVersion/lib/lingolens_services.dart:239-299` | fabricated local result |
| `RealCodexAnalysisService` | `FlutterVersion/lib/lingolens_services.dart:334-386` | Codex process and silent Mock fallback |
| `GlobalSelectedTextReader` | `FlutterVersion/lib/lingolens_services.dart:388-422` | clipboard and OS-level copy simulation |
| `TextToSpeechService` | `FlutterVersion/lib/lingolens_services.dart:425-467` | `say`／PowerShell process |
| `_startClipboardMonitor` | `FlutterVersion/lib/main.dart:137-153` | automatic clipboard-triggered query and raw print |

## Merged Model 2

| Symbol | Path and lines | Role |
|---|---|---|
| `QueryCoordinator` | `lib/services/query_coordinator.dart:7-167` | generation guard、cache、analysis、save、floating update |
| `CodexProcessRunner` | `lib/services/codex_analysis_service.dart:90-171` | process start、stream drain、timeout kill |
| `CodexAnalysisService` | `lib/services/codex_analysis_service.dart:173-364` | schema、prompt、CLI、typed decode、fallback |
| `IsarLearningRepository` | `lib/repositories/learning_repository.dart:47-268` | durable Isar records and review events |
| `SelectedTextService` | `lib/services/selected_text_service.dart:65-99` | accessibility／clipboard fallback and max length |
| `HotkeyService` | `lib/services/hotkey_service.dart:5-42` | global `Ctrl + Space` registration |
| `SystemSpeechEngine` | `lib/services/speech_service.dart:13-103` | `flutter_tts` and PowerShell SAPI fallback |
| `FloatingWindowService` | `lib/services/floating_window_service.dart:13-344` | desktop window lifecycle and click-outside |

## Architecture summary

- Prototype：Swift actor／protocol boundaries，測試覆蓋最完整。
- Merged Model 1：大量行為集中於兩個 library file，且 composition root 使用 in-memory／demo data。
- Merged Model 2：Flutter service／repository 分檔較清楚，具 Isar、desktop service 與 tests，但尚未滿足分析、privacy、cancellation 與 history contracts。
