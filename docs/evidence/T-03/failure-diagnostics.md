# T-03 Failure Diagnostics

## Source of baseline results

T-03 沿用 `docs/evidence/T-02/command-results.md` 的 frozen disposable clone results；本輪沒有重新執行任何 Flutter command。

| Source | Command | Exit | Observed evidence | Classification |
|---|---|---:|---|---|
| Merged Model 1 | `flutter pub get` | 0 | `Got dependencies!` | PASS，僅代表 dependency resolution 完成 |
| Merged Model 1 | `flutter analyze` | 1 | 63 issues；undefined `LearningLibraryController`、`ReviewController`、`AppSection`、`LearningRecord`、`SentenceAnalysis`、`ReviewRating`、`MyApp` 等 | `SOURCE_CODE_DEFECT` |
| Merged Model 1 | `flutter test` | 1 | `test/widget_test.dart:16:35: Error: Couldn't find constructor 'MyApp'.` | `TEST_DEFECT`／source-test mismatch |
| Merged Model 1 | `flutter build windows` | 1 | 找不到 Visual Studio `cmake.exe` | `TOOLCHAIN_ENVIRONMENT` |
| Merged Model 2 | `flutter pub get` | 0 | `Got dependencies!` | PASS，僅代表 dependency resolution 完成 |
| Merged Model 2 | `flutter analyze` | 1 | 29 issues；async gap、generated Isar warnings、unused imports | `SOURCE_CODE_DEFECT`，含 generated／lint noise |
| Merged Model 2 | `flutter test` | 0 | `All tests passed!`; 46 tests | PASS，但非完整 quality gate |
| Merged Model 2 | `flutter build windows` | 1 | 找不到相同 Visual Studio `cmake.exe` | `TOOLCHAIN_ENVIRONMENT` |
| Prototype | Flutter commands | NOT_RUN | 無 `pubspec.yaml`，為 Swift/macOS Xcode project | NOT_APPLICABLE；macOS/Xcode 未在 Windows 驗證 |

## Diagnostic interpretation

1. Merged Model 1 的 analyzer 與 widget test error 是 source／test wiring defect，不是單一 host toolchain 問題。
2. Merged Model 2 的 `flutter test` PASS 不能抵銷 analyzer failure，也不能證明 Windows build readiness。
3. 兩個 Flutter Windows build failure 都指向 host-side CMake discovery；T-03 不修改 host toolchain，也不在 source Repository 重跑 build。
4. 這些 failure diagnostics 是 integration selection evidence，不是 T-03 implementation task。
