# T-03 Findings

## 結果摘要

`T-03` 已完成 read-only code-level capability audit。結果為 `READY_FOR_REVIEW`，不是 production implementation approval，也不是 base-repository selection。

## Findings

| ID | Severity | Confidence | Finding | Affected source |
|---|---|---|---|---|
| F-001 | P1 | HIGH | provider／process／decode failure 靜默回傳 Mock，可能產生 fabricated success 並隱藏真正錯誤 | M1 `FlutterVersion/lib/lingolens_services.dart:334-386` |
| F-002 | P2 | HIGH | raw user text、prompt preview、CLI stdout／stderr 進入 debug／console Log | M1 `FlutterVersion/lib/main.dart:137-153`; M2 `lib/services/codex_analysis_service.dart:263-315`, `:90-171` |
| F-003 | P2 | HIGH | generation guard 只丟棄 stale result，沒有把 latest-request wins 完整傳遞至 underlying process cancellation | M1 `FlutterVersion/lib/lingolens_viewmodels.dart:306-407`; M2 `lib/services/query_coordinator.dart:7-167` |
| F-004 | P2 | HIGH | M1 自動 clipboard monitor 與 stale clipboard fallback 可能未經明確 scope 就分析資料，且可能分析錯誤內容 | M1 `FlutterVersion/lib/main.dart:137-181`; `lingolens_services.dart:388-422` |
| F-005 | P2 | MEDIUM | M2 PowerShell SAPI command 由動態文字組成，現有 quote replacement 尚未充分證明可抵抗所有 parser edge cases | M2 `lib/services/speech_service.dart:13-103` |
| F-006 | P1 | HIGH | 未有 source 同時證明 cache/history separation、visible history limit 20 與 favorites non-eviction | Prototype `SwiftDataLearningRepository.swift:8-138`; M1 `:42-236`; M2 `learning_repository.dart:47-268` |
| F-007 | P1 | HIGH | M1 T-02 analyze/test 已暴露 undefined symbol 與 widget test contract mismatch；不可視為可直接整合 base | M1 T-02 evidence |
| F-008 | P1 | HIGH | 三個 source 未找到標準 License file；permission 與 license compatibility 均未核准 | 三個 source Repository |

## Positive evidence

- Prototype 的 `QueryCoordinator` 有 actor isolation、generation、`Task.isCancelled` 與 outcome metrics。
- Prototype 有 clipboard restoration、Codex service、repository、panel、speech、review 等多層測試。
- M2 的 process runner 使用 argument array、非 shell execution、stdout／stderr drain、timeout kill 與 schema decode。
- M2 的 Isar repository 使用 transaction，review record 與 `ReviewEvent` 同 transaction 更新。
- Credential-pattern scan 與 history credential scan 在三個 frozen source 均無命中；這是 bounded scan evidence，不是完整安全保證。

## Required follow-up gate

下列事項必須在後續獲授權 Task 以獨立 evidence 處理：

1. 明確定義 live provider failure 與 fallback result 的 typed state。
2. 移除 raw input／raw provider output from default logs，並保留可控的 redacted diagnostics。
3. 讓 request cancellation 可終止 underlying process／stream，並補 race tests。
4. 定義 clipboard consent、scope、restore、stale data rejection 與 auto-monitor behavior。
5. 以不組合動態 shell command 的方式 harden TTS boundary，並補 parser/security tests。
6. 決定 cache/history schema、20-record limit、favorite eviction exception 與 migration。
7. 取得明確 permission、license evidence 與 source provenance 後，才可評估任何 code reuse。

本輪不實作以上修正，不進入 T-04 或 T-05。
