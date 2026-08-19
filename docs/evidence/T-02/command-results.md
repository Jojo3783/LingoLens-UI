# T-02 Command Results

本文件保留 baseline command 的工作目錄、時間、exit code、結果與 stdout／stderr 摘要。原始 Flutter tool output 中的 English、Path、diagnostic 與 third-party text 保留原文；完整長輸出由同次 command response 保留於工作階段證據。

## Merged Model 1

Working directory: `D:\GitHub\workspace\lingolens-audit\merged-model-1\FlutterVersion`

### `flutter pub get`

- Start: `2026-07-26T23:52:45+08:00`
- End: `2026-07-26T23:52:52+08:00`
- Exit code: `0`
- Result: PASS
- stdout: `Resolving dependencies...`; `Downloading packages...`; `Got dependencies!`; `18 packages have newer versions incompatible with dependency constraints.`
- stderr: empty

### `flutter analyze`

- Start: `2026-07-26T23:52:53+08:00`
- End: `2026-07-26T23:53:29+08:00`
- Exit code: `1`
- Result: FAIL
- stdout: `Analyzing FlutterVersion...`; errors include undefined `LearningLibraryController`, `ReviewController`, `AppSection`, `LearningRecord`, `SentenceAnalysis`, `ReviewRating`, `MyApp`; infos include unnecessary imports, deprecated members, and `avoid_print`.
- stderr: `63 issues found. (ran in 34.2s)`

### `flutter test`

- Start: `2026-07-26T23:53:30+08:00`
- End: `2026-07-26T23:53:41+08:00`
- Exit code: `1`
- Result: FAIL
- stdout: test loading failed for `test/widget_test.dart`.
- stderr: `test/widget_test.dart:16:35: Error: Couldn't find constructor 'MyApp'.`

### `flutter build windows`

- Start: `2026-07-26T23:53:41+08:00`
- End: `2026-07-26T23:53:48+08:00`
- Exit code: `1`
- Result: FAIL
- stdout/stderr: Flutter reported `ProcessException: Failed to find "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\Common7\\IDE\\CommonExtensions\\Microsoft\\CMake\\CMake\\bin\\cmake.exe"`; a crash report was written to `D:\\GitHub\\workspace\\lingolens-audit\\merged-model-1\\FlutterVersion\\flutter_01.log`.

## Merged Model 2

Working directory: `D:\GitHub\workspace\lingolens-audit\merged-model-2`

### `flutter pub get`

- Start: `2026-07-26T23:54:01+08:00`
- End: `2026-07-26T23:54:12+08:00`
- Exit code: `0`
- Result: PASS
- stdout: `Resolving dependencies...`; `Downloading packages...`; `Got dependencies!`; `21 packages have newer versions incompatible with dependency constraints.`
- stderr: empty

### `flutter analyze`

- Start: `2026-07-26T23:54:12+08:00`
- End: `2026-07-26T23:54:21+08:00`
- Exit code: `1`
- Result: FAIL
- stdout: `Analyzing merged-model-2...`; one async-gap info, generated Isar experimental-member warnings, unused imports, and unnecessary import info.
- stderr: `29 issues found. (ran in 5.8s)`

### `flutter test`

- Start: `2026-07-26T23:54:21+08:00`
- End: `2026-07-26T23:54:36+08:00`
- Exit code: `0`
- Result: PASS
- stdout: `All tests passed!`; final count `46`.
- stderr: empty

### `flutter build windows`

- Start: `2026-07-26T23:54:36+08:00`
- End: `2026-07-26T23:54:41+08:00`
- Exit code: `1`
- Result: FAIL
- stdout/stderr: Flutter reported the same missing CMake executable path and wrote `D:\\GitHub\\workspace\\lingolens-audit\\merged-model-2\\flutter_01.log`.

## Non-Flutter source

`D:\GitHub\workspace\lingolens-audit\prototype` 不含 `pubspec.yaml`，且是 Swift/macOS Xcode project。此來源的 Flutter baseline commands 為 NOT_RUN；Windows host 的 macOS/Xcode verification 為 NOT_RUN。

## Post-command status

- Source Repository status: clean for all three source paths.
- Disposable Clone HEADs: unchanged and equal to source HEADs.
- Disposable Clone generated state: limited to `.dart_tool`、`build`、regenerated plugin registrants、and Flutter crash logs.

## Root lockfile ignore verification

在目前 Git 版本中，`git check-ignore -v --no-index pubspec.lock` 會列出最後命中的 negation rule `!.gitignore:4:!/pubspec.lock` 並回傳 exit code `0`；這不是 `pubspec.lock` 仍被 ignore 的證據。相同 path 執行不帶 `-v` 或帶 `-q` 時均為 exit code `1` 且 stdout empty，表示沒有 ignore rule 命中：

```text
Command: git check-ignore -v --no-index pubspec.lock
Exit code: 0
stdout: .gitignore:4:!/pubspec.lock\tpubspec.lock

Command: git check-ignore --no-index pubspec.lock
Exit code: 1
stdout: empty

Command: git check-ignore -q --no-index pubspec.lock
Exit code: 1
stdout: empty
```
