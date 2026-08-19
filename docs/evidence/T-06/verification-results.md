# T-06 Verification Evidence

## T-06R supersession

本文件保留 T-06 原始 verification receipts。T-06R 的測試集合已移除兩個
不成立的 persistence assertions 並加入實際 repository boundary coverage，
因此此處的 `53 PASS` 是 T-06 pre-remediation 歷史結果；目前 PR #9 的最終
結果請以 `docs/evidence/T-06R/` 為準。

所有 Flutter／Dart verification 均在 disposable clone 執行，避免正式 Repository 產生 `.dart_tool` 或 dependency state。

## Toolchain

- Command：`flutter --suppress-analytics --version`
- Working directory：`D:\GitHub\workspace\lingolens-audit\T-06-final-de4da2c`
- Exit code：`0`
- Result：`PASS`
- Relevant output：Flutter `3.41.5`；Dart `3.11.3`；DevTools `2.54.2`

- Command：`dart --suppress-analytics --version`
- Working directory：`D:\GitHub\workspace\lingolens-audit\T-06-final-de4da2c`
- Exit code：`0`
- Result：`PASS`
- Relevant output：Dart SDK `3.11.3 (stable)`

- Command：`git --version`
- Working directory：`D:\GitHub\workspace\lingolens-audit\T-06-final-de4da2c`
- Exit code：`0`
- Result：`PASS`
- Relevant output：Git `2.53.0.windows.1`

## Dependency restore

- Command：`flutter --suppress-analytics pub get`
- Working directory：`D:\GitHub\workspace\lingolens-audit\T-06-final-de4da2c`
- Exit code：`0`
- Result：`PASS`
- Relevant output：`Got dependencies!`；4 packages newer but incompatible with constraints
- Generated artifacts：只在 disposable clone

## Format

- Command：`dart --suppress-analytics format --output=none --set-exit-if-changed .`
- Working directory：`D:\GitHub\workspace\lingolens-audit\T-06-final-de4da2c`
- Exit code：`0`
- Result：`PASS`
- Relevant output：`Formatted 17 files (0 changed) in 0.13s`

## Analyze

- Command：`flutter --suppress-analytics analyze`
- Working directory：`D:\GitHub\workspace\lingolens-audit\T-06-final-de4da2c`
- Exit code：`0`
- Result：`PASS`
- Relevant output：`No issues found! (ran in 3.0s)`

## Complete test suite

- Command：`flutter --suppress-analytics test`
- Working directory：`D:\GitHub\workspace\lingolens-audit\T-06-final-de4da2c`
- Exit code：`0`
- Result：`PASS`
- Relevant output：`00:02 +53: All tests passed!`

## Receipt limitation

以上 command output 未由 timestamp wrapper 捕捉 Start／End time；未捏造時間。Exit code 與完整 relevant output 已保留。
