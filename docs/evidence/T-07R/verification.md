# T-07R Verification Evidence

## Command records

所有 Flutter／Dart 會產生 dependency 或 build state 的命令均在 disposable clone 執行：
`D:\GitHub\workspace\lingolens-audit\T-07-working`。

### Format

Command：`dart format --output=none --set-exit-if-changed .`

Exit code：`0`

Result：`PASS`

stdout：`Formatted 29 files (0 changed) in 0.08 seconds.`

### Analyze

Command：`flutter analyze`

Exit code：`0`

Result：`PASS`

stdout：`No issues found! (ran in 1.6s)`

### Complete test suite

Command：`flutter test`

Exit code：`0`

Result：`PASS`

stdout：`All tests passed!`；總計 `79 passed`。

### Dependency state

`flutter pub get` 由 `flutter analyze` 與 `flutter test` 的 Flutter command lifecycle 執行並成功；未修改正式 Repository 的 dependency manifest 或 lockfile。既有 dependency constraints 回報 4 個可更新但不相容版本；本輪未升級相依套件。

## Limitations

- macOS build／runtime：`NOT_RUN`；目前 host 為 Windows。
- Windows build：見 `build.md`，因 disposable clone 缺少 CMake executable 而為 `BLOCKED`。
- GitHub checks：`NONE_REPORTED`；未將本地驗證冒充 GitHub CI 結果。
