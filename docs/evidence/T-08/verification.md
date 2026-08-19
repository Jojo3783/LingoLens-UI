# T-08 Verification Summary

## Frozen disposable clone

- Path：`D:\GitHub\workspace\lingolens-audit-t08`
- Commit：`ab6012f3b2a1a919eec9999cb2bfae9f1350d949`
- Base：`3203d3b4b134ea4a91d4229ca447fef51eb58804`
- Repository working tree：formal Repository 在 evidence commit 前另行記錄；disposable clone 僅供驗證與產生暫存 visual harness

## Command records

| Command | Exit code | Result | Relevant stdout／stderr |
|---|---:|---|---|
| `flutter --version` | 0 | `PASS` | Flutter `3.41.5`、Dart `3.11.3` |
| `dart --version` | 0 | `PASS` | Dart SDK `3.11.3` |
| `flutter pub get` | 0 | `PASS` | `Got dependencies!`；未修改 manifest |
| `dart format --output=none --set-exit-if-changed .` | 0 | `PASS` | `Formatted 33 files (0 changed)` |
| `flutter analyze` | 0 | `PASS` | `No issues found!` |
| `flutter test test/domain/analysis_models_test.dart` | 0 | `PASS` | `15 passed` |
| `flutter test test/infrastructure/fake_analysis_provider_test.dart` | 0 | `PASS` | `1 passed` |
| `flutter test test/widget_reading_mode_test.dart` | 0 | `PASS` | `7 passed` |
| `flutter test test/application/analysis_controller_test.dart test/application/result_action_controller_test.dart` | 0 | `PASS` | `19 passed` |
| `flutter test test/widget_test.dart` | 0 | `PASS` | `6 passed` |
| `flutter test` | 0 | `PASS` | clean frozen commit：`89 passed` |
| `git diff --check` | 0 | `PASS` | stdout empty |
| `flutter build windows` | 1 | `BLOCKED` | Flutter 找不到 `C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe` |

每個 command 的 Start／End：`2026-07-28`；MCP command wrapper 未提供細部時間戳。Dependency resolution 的 stderr 僅為可更新但受現有 constraints 限制的套件提示。

## Platform limitations

- Windows build：`BLOCKED`，原因是環境缺少 Flutter 要求的 CMake executable；未修改 build tooling 或 dependency。
- macOS build／runtime：`NOT_RUN`，目前 host 為 Windows。
- GitHub checks：建立 Draft PR 後才可查詢；目前尚未宣稱任何 remote check 結果。
