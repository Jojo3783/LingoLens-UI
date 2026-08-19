# T-07 Verification Results

## Environment

- Disposable clone：`D:\GitHub\workspace\lingolens-audit\T-07-working`
- Flutter：`3.41.5`
- Dart：`3.11.3`
- Dependencies：`flutter pub get` 成功；未修改 `pubspec.yaml` 或 dependency constraints

## Command receipts

### `flutter --version`

- Exit code：`0`
- Result：`PASS`
- Relevant output：Flutter `3.41.5`、Dart `3.11.3`

### `dart --version`

- Exit code：`0`
- Result：`PASS`
- Relevant output：Dart SDK `3.11.3 (stable)`

### `flutter pub get`

- Exit code：`0`
- Result：`PASS`
- Limitation：工具提示有 4 個受 constraints 限制的可更新 package；本任務未升級 dependency。

### `dart format .`

- Exit code：`0`
- Result：`PASS`
- Relevant output：`Formatted 28 files (0 changed)`（final clone check）

### `dart format --output=none --set-exit-if-changed .`

- Exit code：`0`
- Result：`PASS`
- stdout／stderr：無 formatting issue

### `flutter analyze`

- Exit code：`0`
- Result：`PASS`
- Relevant output：`No issues found!`

### Focused T-07 test command

```text
flutter test test/application/mode_selection_test.dart test/application/result_action_controller_test.dart test/application/analysis_controller_test.dart test/widget_test.dart
```

- Exit code：`0`
- Result：`PASS`
- Tests：`22 passed`

### `flutter test`

- Exit code：`0`
- Result：`PASS`
- Tests：`74 passed`

### `git diff --check`

- Working directory：`D:\GitHub\LingoLens`
- Exit code：`0`
- stdout／stderr：empty
- Result：`PASS`

## Unverified or blocked

- Windows `flutter build windows`：見 `build-results.md`，結果為 `BLOCKED`。
- macOS build／runtime：`NOT_RUN`，Windows host 無法驗證。
