# T-02 Build and Test Report

> Task: T-02 Disposable Source Baseline
> Result: READY_FOR_REVIEW
> Host: Windows 11 x64
> Flutter: 3.41.5 stable

## Environment

完整 command、exit code、stdout、stderr 與時間記錄於 `docs/evidence/T-02/environment.txt` 及 `docs/evidence/T-02/command-results.md`。

| Item | Evidence |
|---|---|
| Git | `git version 2.53.0.windows.1` |
| Flutter | `Flutter 3.41.5`, channel `stable` |
| Dart | `Dart SDK version: 3.11.3` |
| Flutter SDK | `C:\Users\luke2\flutter\bin\flutter.bat` |
| Dart SDK | `C:\Users\luke2\flutter\bin\dart.bat` |
| Shell | Git Bash via `mcp__git_bash__run` |
| Time zone | `Taipei Standard Time` |
| macOS verification | NOT_RUN；Windows host 不具備 macOS/Xcode execution environment |

## Disposable verification results

| Source | `flutter pub get` | `flutter analyze` | `flutter test` | `flutter build windows` |
|---|---|---|---|---|
| Prototype | NOT_APPLICABLE；非 Flutter project | NOT_APPLICABLE | NOT_APPLICABLE | NOT_APPLICABLE；Swift/macOS project |
| Merged Model 1 | PASS，exit 0 | FAIL，exit 1；63 issues，包含 undefined classes／identifiers 與 test compile error | FAIL，exit 1；`MyApp` constructor 不存在 | FAIL，exit 1；Flutter 找不到 `C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe` |
| Merged Model 2 | PASS，exit 0 | FAIL，exit 1；29 issues，主要為 generated Isar experimental warnings、unused imports 與 async-gap info | PASS，exit 0；`46` tests passed | FAIL，exit 1；同一個 missing CMake path |

## Interpretation

- `flutter analyze` 的 non-zero 結果是來源現況，不是 T-02 修改造成的 failure。
- Merged Model 2 的 test suite 在 disposable clone 通過，但 analyze 與 Windows build 尚未通過，因此不能宣稱完整 baseline green。
- Windows build failure 是 host toolchain／Flutter detection 問題：Flutter diagnostic 顯示 Visual Studio 17.12.0 與 Windows SDK 10.0.22621.0 可見，但 Flutter 執行時仍無法找到預期 CMake executable。T-02 不修改 host toolchain。
- 未在 Windows host 宣稱任何 macOS build 或 macOS PASS。
- 未執行 `dart run build_runner build`、`flutter pub outdated` 或任何 dependency update。

## Safety observations

- 未找到 `git:` 或 `path:` dependency。
- Merged Model 1 含 `debug_windows.ps1` 與 Dart `Process.start`／PowerShell 呼叫；T-02 未執行該 script，也未修改其內容。
- Merged Model 2 含 Dart `Process.start`／PowerShell 呼叫與 native Flutter plugins；僅在 disposable clone 執行 Flutter baseline。
- 未找到已追蹤的 `.exe`、`.dll`、`.dylib` 或 `.so` binary artifact。
- Source Repository 前後 `git status --short --branch` 均為 clean，未被修改。
