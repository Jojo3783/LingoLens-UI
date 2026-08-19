# T-08R Verification Evidence

All Flutter commands that can generate dependency or build state ran only in the disposable clone `D:\GitHub\workspace\lingolens-audit-t08r`, tied to the frozen starting implementation. The formal Repository was not used as a build workspace.

| Command | Exit code | Result | Evidence |
|---|---:|---|---|
| `flutter pub get` | 0 | PASS | Dependencies resolved; no manifest change. |
| `dart format --output=none --set-exit-if-changed .` | 0 | PASS | `32 files (0 changed)`. |
| `flutter analyze` | 0 | PASS | `No issues found!`. |
| `flutter test test/widget_reading_mode_test.dart test/widget_test.dart` | 0 | PASS | `16 tests passed`. |
| `flutter test` | 0 | PASS | `90 tests passed`; `All tests passed!`. |
| `git diff --check` | 0 | PASS | No whitespace errors; only line-ending warnings were emitted. |
| `flutter build windows` | 1 | BLOCKED | Missing `C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe`. |
| macOS build／runtime | N/A | NOT_RUN | Windows host; no macOS environment available. |

The initial disposable-clone file-wiring attempt copied files to an incorrect location; that result was discarded and is not used as evidence. The corrected clone copied only the four changed source/test files to their exact paths before verification.

The Flutter build blocker is environmental and is not represented as a pass. No `flutter pub get`, `flutter analyze`, `flutter test`, or `flutter build` command ran in any read-only source Repository.
