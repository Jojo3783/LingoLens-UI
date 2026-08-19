# T-12R Dart and Flutter Verification

每一筆 command 都在 disposable clone 執行，以避免把 dependency、build 或 test
artifact 寫入主 Repository。

## Required command records

Task: T-12R Flutter verification
Working directory: `D:\\GitHub\\workspace\\lingolens-t12r-final4`
Commands: `flutter pub get`；`dart format --output=none --set-exit-if-changed .`；`flutter analyze`；focused T-12R tests；`flutter test`；`flutter build windows`
Result: `PASS`
Exit codes: `0` for every command
Generated artifacts: `.dart_tool`、test/build output remain disposable
Git status before: clean disposable clone
Git status after: generated `pubspec.lock` and build artifacts remained only in disposable clone
Limitations: 不得以較早 commit 的結果代替 final candidate 的完整 verification。

## Focused coverage

Focused suite: 48 tests passed。涵蓋 Windows contracts、capture ordering、mode selection、provider settings、OpenAI credential failure、runtime switching、responsive navigation、provider disclosure 與 debug-only failure semantics。測試未發送網路請求。

## Full suite

Full `flutter test`: 144 tests passed，exit code `0`。
`flutter build windows`: exit code `0`，產物為 `build\\windows\\x64\\runner\\Release\\lingolens.exe`。
