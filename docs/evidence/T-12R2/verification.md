# T-12R2 Immutable Verification

## Final exact-SHA integration verification

本輪完整 receipt 於 verification command 執行前建立，所有 automated command 均在
fresh disposable clone 執行，tested SHA 為
`218261d2f6b0a782a7dcd82fd5ad585da0461b8d`：
`D:\\GitHub\\workspace\\lingolens-t12r2-verify-218261d`。

完整 receipt：`D:\\GitHub\\workspace\\T-12R2-integration-218261d.log`。

環境：Flutter `3.41.5`、Dart `3.11.3`、Git `2.53.0.windows.1`、Windows
`10.0.26200.8973`。

### Exact command records

| Command | UTC start | UTC end | Exit code | Result | Relevant output |
|---|---|---:|---:|---|---|
| `git rev-parse HEAD` | `2026-07-30T08:21:43Z` | `2026-07-30T08:21:44Z` | `0` | `PASS` | exact SHA `218261d2f6b0a782a7dcd82fd5ad585da0461b8d` |
| `flutter pub get` | `2026-07-30T08:21:53Z` | `2026-07-30T08:21:57Z` | `0` | `PASS` | `Got dependencies!` |
| `git diff --exit-code -- pubspec.lock` | `2026-07-30T08:22:10Z` | `2026-07-30T08:22:10Z` | `0` | `PASS` | tracked lockfile unchanged |
| `dart format --output=none --set-exit-if-changed .` | `2026-07-30T08:22:21Z` | `2026-07-30T08:22:23Z` | `0` | `PASS` | `Formatted 64 files (0 changed)` |
| `flutter analyze` | `2026-07-30T08:22:33Z` | `2026-07-30T08:23:09Z` | `0` | `PASS` | `No issues found!` |
| established T-12R2 focused `flutter test` command | `2026-07-30T08:23:22Z` | `2026-07-30T08:23:36Z` | `0` | `PASS` | `+23: All tests passed!` |
| `flutter test` | `2026-07-30T08:23:45Z` | `2026-07-30T08:23:55Z` | `0` | `PASS` | `+150: All tests passed!` |
| existing MSVC native watchdog／UIA timeout／Clipboard harness | `2026-07-30T08:24:11Z` | `2026-07-30T08:24:15Z` | `0` | `PASS` | `cl.exe` compiled and harness exited successfully |
| `flutter build windows` | `2026-07-30T08:24:25Z` | `2026-07-30T08:25:23Z` | `0` | `PASS` | Windows Release executable built |
| `git diff --check 10f2d3da98d1fdbdfd2e0abbb39d758a396a6183..HEAD` | `2026-07-30T08:25:34Z` | `2026-07-30T08:25:34Z` | `0` | `PASS` | no output |
| `git status --short` | `2026-07-30T08:25:45Z` | `2026-07-30T08:25:45Z` | `0` | `PASS` | only generated untracked `native-build/`; no tracked modification |

`native-build/` was generated only in the disposable clone and removed after the
final status record. The tracked clone state, including `pubspec.lock`, was not
modified.

### GitHub checks classification

Command：`gh pr checks 15 --repo OPluke11-abula/LingoLens`
UTC：`2026-07-30T08:26:38Z`–`2026-07-30T08:26:39Z`
Exit code：`1`
Output：`no checks reported on the 'feat/t12-windows-integration' branch`

- GitHub checks：`NO_CHECKS_REPORTED`
- Gate：`NOT_APPLICABLE`
- PASS：`false`
- Integration blocker：`false`

### Final T-12R2 decision

- Verified implementation SHA：`218261d2f6b0a782a7dcd82fd5ad585da0461b8d`
- Clipboard deadline correction：`ACCEPTED`
- UIA bounded timeout correction：`ACCEPTED`
- Automated integration verification：`PASS`
- Windows manual QA：`PENDING`
- macOS build：`REPORTED_PASS_BY_EASON`，非正式 PASS
- macOS formal evidence／secure-storage QA：`PENDING`
- `T-12R2_READY_FOR_TEAM_REVIEW`：`false`
- `SAFE_TO_MERGE`：`false`

## Prior implementation receipt (historical reference)

以下內容保留作為先前 implementation verification 參考；本節不取代上方
218261d exact-SHA receipt。

所有 command 均在 fresh disposable clone
`D:\GitHub\workspace\lingolens-t12r2-final-verify-c7db72a` 執行，tested SHA 為
`c7db72ad7f47f45ebd783392d64de44605761248`。UTC 時間、exit code 與相關 stdout／stderr
取自同一次 command receipt：
`D:\GitHub\workspace\T-12R2-final-native-correction-c7db72a.log`。

### 1. Dependency resolution

Task：T-12R2 lockfile verification
Command：`flutter pub get`
Working directory：fresh disposable clone
Start：`2026-07-29T19:28:44Z`
End：`2026-07-29T19:28:47Z`
Exit code：`0`
Result：`PASS`
Relevant stdout：`Got dependencies!`；7 個套件有較新但不符合目前 constraints 的版本。
Git status after：clean；`git diff -- pubspec.lock` 為空。
Limitations：這是 fresh clone 驗證；主 Repository 的 generated lockfile 已由 Luke 明確授權提交。

### 2. Format

Task：T-12R2 Dart format
Command：`dart format --output=none --set-exit-if-changed .`
Working directory：fresh disposable clone
Start：`2026-07-29T19:28:47Z`
End：`2026-07-29T19:28:48Z`
Exit code：`0`
Result：`PASS`
Relevant stdout：`Formatted 64 files (0 changed) in 0.20 seconds.`

### 3. Analyze

Task：T-12R2 Flutter static analysis
Command：`flutter analyze`
Working directory：fresh disposable clone
Start：`2026-07-29T19:28:48Z`
End：`2026-07-29T19:28:55Z`
Exit code：`0`
Result：`PASS`
Relevant stdout：`No issues found! (ran in 3.2s)`

### 4. Focused tests

Task：T-12R2 focused regression tests
Command：`flutter test test/application/provider_settings_controller_test.dart test/application/windows_capture_controller_test.dart test/infrastructure/windows_platform_services_test.dart test/widget_t12r_startup_test.dart test/widget_t12r_ui_test.dart test/widget_windows_capture_test.dart`
Working directory：fresh disposable clone
Start：`2026-07-29T19:28:55Z`
End：`2026-07-29T19:29:01Z`
Exit code：`0`
Result：`PASS`
Relevant stdout：`00:01 +23: All tests passed!`
Coverage：23 tests，含 startup hydration、secret boundary、secure-storage error、Save and Apply、UIA typed boundedness failure、latest-capture-wins 與 Windows capture UI。

### 5. Full tests

Task：T-12R2 full Flutter regression suite
Command：`flutter test`
Working directory：fresh disposable clone
Start：`2026-07-29T19:29:01Z`
End：`2026-07-29T19:29:12Z`
Exit code：`0`
Result：`PASS`
Relevant stdout：`00:06 +150: All tests passed!`
Coverage：150 tests。

### 6. Native harness

Task：T-12R2 Windows state-machine harness
Command：Visual Studio `cl.exe` `/std:c++17` 編譯並執行 `lingolens_native_platform_harness.exe`
Working directory：fresh disposable clone
Start：`2026-07-29T19:29:12Z`
End：`2026-07-29T19:29:16Z`
Exit code：`0`
Result：`PASS`
Relevant stdout：MSVC `cl.exe` 編譯完成，harness executable 正常結束。
Coverage：owned watchdog deadline／cancel／completion／shutdown wake、race、destruction safety、`CoCancelCall` failure classification，以及 capture／cleanup phase scenarios。
Generated artifacts：只在 disposable clone 的 `build/native-receipt/`。

### 7. Windows build

Task：T-12R2 Windows application build
Command：`flutter build windows`
Working directory：fresh disposable clone
Start：`2026-07-29T19:29:16Z`
End：`2026-07-29T19:29:25Z`
Exit code：`0`
Result：`PASS`
Relevant stdout：`√ Built build\\windows\\x64\\runner\\Release\\lingolens.exe`

### 8. Git diff check

Task：T-12R2 immutable diff check
Command：`git diff --check 10f2d3da98d1fdbdfd2e0abbb39d758a396a6183..HEAD`
Working directory：fresh disposable clone
Start：`2026-07-29T19:29:26Z`
End：`2026-07-29T19:29:26Z`
Exit code：`0`
Result：`PASS`
Relevant stderr：empty。

## Lockfile assertions

- `pubspec.yaml` 在 lockfile Commit 前後均無未授權變更。
- Direct dependency：`flutter_secure_storage 10.3.1`。
- Required platform packages：`flutter_secure_storage_darwin 0.3.2`、`flutter_secure_storage_linux 3.0.1`、`flutter_secure_storage_platform_interface 2.0.2`、`flutter_secure_storage_web 2.1.1`、`flutter_secure_storage_windows 4.2.2`。
- 其他新增項目均為該 dependency graph 的 hosted transitive package 或 Flutter SDK package。
- `source` 僅為 `hosted` 或 `sdk`；無 path／Git dependency、private registry、credential、username 或 machine-specific path。
- Fresh clone 執行 `flutter pub get` 後，tracked `pubspec.lock` 未變更，Git working tree clean。

## Native boundedness assertions

- UIA deadline watchdog：deadline 到達時主動執行 `RequestTimeout()`，再以 worker thread ID 嘗試一次 `CoCancelCall`；不由另一個 capture 或 explicit cancel 才觸發。
- Worker／watchdog lifecycle：owned、可喚醒、可 join；watchdog 不呼叫 Flutter `MethodResult`，owner thread 才完成 response。
- `CoCancelCall` failure：分類為 `failed` 並保留 HRESULT-derived error metadata；不宣稱 absolute cancellation。
- Clipboard capture deadline：由 operation timeout 控制；SendInput 前與 capture observation 使用此 deadline。
- Clipboard cleanup deadline：SendInput 成功後建立獨立 `750ms` budget；restore／verification 使用 cleanup deadline。
- Cancellation／capture timeout 後：不啟動新的 text read；仍完成 request-owned observation 與安全 restore，third-party sequence 不覆寫。
- Manual Windows interaction 與 macOS shared-code／secure-storage QA 未執行，不能由這些 automated results 代替。
- CMake／MSBuild standalone harness configure 曾受 `GetLatestSDKTargetPlatformVersion` discovery error 阻擋；本次 native harness 以相同 MSVC `cl.exe` toolchain 直接編譯執行並通過，Windows application build 亦通過。
