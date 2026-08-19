# T-03 Security and Privacy Observations

## Bounded scan result

- 三個 frozen source 的 credential-pattern scan：無命中；`git grep` exit code `1` 為無匹配的預期結果。
- 三個 source 的 history credential scan：exit code `0`、stdout empty、stderr empty。
- 三個 source 的標準 `LICENSE`／`COPYING`／`NOTICE` inventory：無 tracked standard license file。
- Process／clipboard／logging surface scan 命中位置詳見 `audit-commands.txt`。

## Findings

### P1：M1 silent fallback 造成分析結果完整性風險

`FlutterVersion/lib/lingolens_services.dart:334-386` 在 Codex executable missing、non-zero exit、result missing、JSON decode failure 時回傳 `MockCodexAnalysisService`。這不是單純 UX fallback，因為結果會被包裝成正常 `SentenceAnalysis`，使使用者、測試與 telemetry 無法辨識資料來源。

### P2：raw text 與 CLI output logging

- M1 `FlutterVersion/lib/main.dart:137-153` 以 clipboard monitor 直接 `print` 原文。
- M2 `lib/services/codex_analysis_service.dart:263-315` 記錄 raw text、prompt preview、stderr。
- M2 `lib/services/codex_analysis_service.dart:90-171` 記錄每段 stdout／stderr。

這些 Log 可能含使用者輸入、翻譯內容、provider response、local path 或 error context。Default Log 應採 redaction、sampling 與 opt-in diagnostics；本輪不修改 source。

### P2：selection scope 與 stale clipboard

M1 `FlutterVersion/lib/lingolens_services.dart:388-422` 在 copy event 未取得新文字時返回舊 clipboard text；M1 `main.dart:137-181` 會自動掃描 clipboard 並觸發 query。這是資料 scope 與 correctness boundary，需後續 Product／Privacy decision。

### P2：latest-request cancellation 不完整

M1/M2 以 generation 方式阻止 stale state，但 `QueryCoordinator` 沒有讓新 request 取得並取消 underlying Codex process／stream 的 handle。M2 runner 只在 60 秒 timeout 時 kill process。

### P2 hardening：PowerShell SAPI

M2 `lib/services/speech_service.dart:55-72` 將 `sanitizedText` 內插至 `-Command`。目前未確認 exploitable RCE，但 command construction 依賴 ad-hoc quote replacement，應改成更安全的 argument／script boundary 並以 adversarial input tests 驗證。

## Scope limitation

上述是 bounded static observations，不是 penetration test、dependency vulnerability audit、macOS runtime audit 或完整 secret assurance。T-03 未執行 Flutter、未建立 process、未接觸使用者 clipboard，也未修改任何來源 Repository。
