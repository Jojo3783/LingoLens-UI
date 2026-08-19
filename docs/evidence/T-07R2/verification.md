# T-07R2 Verification Evidence

所有 Flutter／Dart command 均在 final frozen-commit disposable clone 執行：
`D:\GitHub\workspace\lingolens-audit\T-07R2-final-d0a7652`。

## Required command records

### `flutter pub get`

Working directory：`D:\GitHub\workspace\lingolens-audit\T-07R2-final-d0a7652`

Exit code：`0`

Result：`PASS`

Relevant output：`Got dependencies!`；4 個版本更新因 dependency constraints 不相容，未升級相依套件。

### `dart format --output=none --set-exit-if-changed .`

Exit code：`0`

Result：`PASS`；`Formatted 29 files (0 changed)`。

### `flutter analyze`

Exit code：`0`

Result：`PASS`；`No issues found! (ran in 2.5s)`。

### Focused action tests

Command：`flutter test test/application/result_action_controller_test.dart`

Working directory：`D:\GitHub\workspace\lingolens-audit\T-07R2-final-d0a7652`

Exit code：`0`

Result：`PASS`；`9 passed`。

### Focused widget tests

Command：`flutter test test/widget_test.dart`

Working directory：`D:\GitHub\workspace\lingolens-audit\T-07R2-final-d0a7652`

Exit code：`0`

Result：`PASS`；`6 passed`。

### Complete tests

Command：`flutter test`

Working directory：`D:\GitHub\workspace\lingolens-audit\T-07R2-final-d0a7652`

Exit code：`0`

Result：`PASS`；`81 passed`。

### Diff check

Command：`git diff --check`

Working directory：`D:\GitHub\workspace\lingolens-audit\T-07R2-final-d0a7652`

Exit code：`0`

Result：`PASS`；stdout／stderr 均為空。

## Limitations

- Windows build：`BLOCKED`，找不到 `C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe`。
- macOS build／runtime：`NOT_RUN`，host 為 Windows。
- GitHub checks：無回報時記錄為 `NONE_REPORTED`。
