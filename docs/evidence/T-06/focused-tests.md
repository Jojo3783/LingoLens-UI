# T-06 Focused Test Evidence

## T-06R supersession

本文件保留 T-06 red／green phase 的歷史 receipts。T-06R 移除了未連接
coordinator 的 History／Cache assertion 與 provider-simulated persistence
mapping test，並新增 repository boundary raw-failure coverage；因此本文件的
`28 PASS` 僅代表 T-06 原始 green phase，不代表目前 PR #9 的最終測試數量。
目前交付結果請以 `docs/evidence/T-06R/` 為準。

## Red phase

- Command：`flutter --suppress-analytics test test/domain/analysis_models_test.dart test/application/analysis_input_boundary_test.dart test/application/error_contract_test.dart`
- Working directory：`D:\GitHub\workspace\lingolens-audit\T-06-red-e0aa6c1`
- Exit code：`1`
- Result：`FAIL`，預期的 TDD red phase
- Relevant output：缺少 `AnalysisResult.fromJsonText`、`analysisSchemaVersion`、新增 error codes、`maxAnalysisInputCharacters` 與 typed exception constructors
- Reason：production contract 尚未實作；測試自身 fixture 修正後失敗集中於缺少 production symbols

## Green phase

- Command：`flutter --suppress-analytics test test/domain/analysis_models_test.dart test/application/analysis_input_boundary_test.dart test/application/error_contract_test.dart`
- Working directory：`D:\GitHub\workspace\lingolens-audit\T-06-final-de4da2c`
- Exit code：`0`
- Result：`PASS`
- Relevant output：`00:00 +28: All tests passed!`
- Coverage：schema、error、input boundary、emoji scalar counting、provider invocation、History／Cache invariants
