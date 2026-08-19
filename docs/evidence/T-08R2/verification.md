# T-08R2 Frozen-Commit Verification

Verification clone: `D:\GitHub\workspace\lingolens-audit-t08r2`
Tested commit: `931c4c9fc43da1e077e728fa39c34a100ea55729`

| Command | Exit code | Result | Observed evidence |
|---|---:|---|---|
| `flutter pub get` | 0 | PASS | Dependencies resolved; no `pubspec.yaml` or `pubspec.lock` change. |
| `dart format --output=none --set-exit-if-changed .` | 0 | PASS | `Formatted 32 files (0 changed)`. |
| `flutter analyze` | 0 | PASS | `No issues found!`. |
| `flutter test test/widget_reading_mode_test.dart test/widget_test.dart` | 0 | PASS | 16 tests passed. |
| `flutter test` | 0 | PASS | 90 tests passed; `All tests passed!`. |
| `git diff --check` | 0 | PASS | No output. |
| `flutter build windows` | 1 | BLOCKED | Missing `C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe`. |
| macOS build／runtime | N/A | NOT_RUN | Windows host; no macOS environment. |

The Windows build result is recorded as `BLOCKED`, not PASS. The clone generated dependency and Flutter build state only in the disposable workspace. The formal Repository was not used for Flutter verification.

## Bounded governance checks

The state-matrix command exited `0` and verified all required T-00 through T-15 states plus the active marker. The protected-path diff from starting HEAD to governance correction commit was empty:

```text
git diff --name-only c3d9a751bf2bef1f992eddc3c2bb6b54487ac2c8..931c4c9fc43da1e077e728fa39c34a100ea55729 -- lib/ test/ pubspec.yaml pubspec.lock windows/ macos/
```

Exit code: `0`; stdout: empty.
