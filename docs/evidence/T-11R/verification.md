# T-11R Verification

## Command record template

下列每一項均應記錄完整 command、working directory、start／end time、exit code、
stdout／stderr、generated artifacts、Git status before／after 與 limitation。正式
Repository 不執行會產生 dependency／build state 的 Flutter command；這些 command
在 disposable clone `D:\GitHub\workspace\lingolens-t11r-verify-*` 執行。

## Required sequence

1. `flutter pub get`
2. `dart format --output=none --set-exit-if-changed .`
3. `flutter analyze`
4. T-11R focused tests
5. 完整 `flutter test`
6. `git diff --check`

## Final disposable clone

Working directory：`D:\GitHub\workspace\lingolens-t11r-verify-RmAKDD`

每個 command 都是獨立執行；完整 stdout／stderr 以原始檔保存於
`docs/evidence/T-11R/commands/`。下表的 exit code 是實際 tool result，不是推測值。

為了讓 evidence 本身通過 Repository `git diff --check`，`analyze.stdout` 的
terminal progress padding 與 `build-windows.stdout` 的 terminal 空白行已移除；
其餘內容維持原文，原始 disposable clone 仍位於上述 working directory。

| 順序 | Command | Exit code | Result | 完整輸出 |
|---:|---|---:|---|---|
| 1 | `flutter pub get` | `0` | `PASS` | `commands/flutter-pub-get.stdout`、`commands/flutter-pub-get.stderr` |
| 2 | `dart format --output=none --set-exit-if-changed .` | `0` | `PASS` | `commands/format.stdout`、`commands/format.stderr` |
| 3 | `flutter analyze` | `0` | `PASS`；`No issues found!` | `commands/analyze.stdout`、`commands/analyze.stderr` |
| 4 | `flutter test test/infrastructure/http_client_analysis_transport_test.dart test/infrastructure/openai_responses_analysis_provider_test.dart test/widget_provider_disclosure_test.dart` | `0` | `PASS`；16 tests | `commands/focused.stdout`、`commands/focused.stderr` |
| 5 | `flutter test` | `0` | `PASS`；123 tests | `commands/full-test.stdout`、`commands/full-test.stderr` |
| 6 | `git diff --check` | `0` | `PASS` | `commands/diff-check.stdout`、`commands/diff-check.stderr` |

Windows build 額外執行：

| Command | Exit code | Result | Limitation |
|---|---:|---|---|
| `flutter build windows` | `1` | `BLOCKED_ENVIRONMENT` | Flutter 找不到 Visual Studio CMake executable；完整輸出在 `commands/build-windows.stdout` 與 `commands/build-windows.stderr`，crash log 僅存在 disposable clone。 |

未執行 live OpenAI API；所有 provider 測試均使用 controlled transport／fixed clock。
