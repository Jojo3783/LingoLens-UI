# T-05R2 Verification Command Receipts

所有 command 均於 `D:\GitHub\LingoLens` 執行。

## Version Commands

### `flutter --version`

- Task：T-05R2 toolchain verification
- Command：`flutter --version`
- Working directory：`D:\GitHub\LingoLens`
- Start time：`2026-07-28T01:28:01+08:00`
- End time：`2026-07-28T01:28:02+08:00`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`Flutter 3.41.5`; `Tools • Dart 3.11.3 • DevTools 2.54.2`
- Relevant stderr：空白
- Generated artifacts：無
- Git status before／after：相同，為本輪預期修改
- Limitations：無。

### `dart --version`

- Task：T-05R2 toolchain verification
- Command：`dart --version`
- Working directory：`D:\GitHub\LingoLens`
- Start time：`2026-07-28T01:28:06+08:00`
- End time：`2026-07-28T01:28:06+08:00`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`Dart SDK version: 3.11.3 (stable)`
- Relevant stderr：空白
- Generated artifacts：無
- Git status before／after：相同，為本輪預期修改
- Limitations：無。

### `git --version`

- Task：T-05R2 toolchain verification
- Command：`git --version`
- Working directory：`D:\GitHub\LingoLens`
- Start time：`2026-07-28T01:28:10+08:00`
- End time：`2026-07-28T01:28:10+08:00`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`git version 2.53.0.windows.1`
- Relevant stderr：空白
- Generated artifacts：無
- Git status before／after：相同，為本輪預期修改
- Limitations：無。

## `flutter pub get`

- Task：T-05R2 dependency verification
- Command：`flutter pub get`
- Working directory：`D:\GitHub\LingoLens`
- Start time：`2026-07-28T01:28:27+08:00`
- End time：`2026-07-28T01:28:28+08:00`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`Got dependencies!`; `4 packages have newer versions incompatible with dependency constraints.`
- Relevant stderr：空白
- Generated artifacts：無；未修改 `pubspec.yaml` 或 `pubspec.lock`
- Git status before／after：相同，為本輪預期修改
- Limitations：未執行 dependency upgrade。

## Formatting Receipts

### 初次 check

- Task：T-05R2 formatting verification
- Command：`dart format --output=none --set-exit-if-changed .`
- Working directory：`D:\GitHub\LingoLens`
- Start time：`2026-07-28T01:27:29+08:00`
- End time：`2026-07-28T01:27:30+08:00`
- Exit code：`1`
- Result：`FAIL`
- Relevant stdout：`Changed lib\application\persistence_controller.dart`; `Changed test\application\persistence_controller_test.dart`
- Relevant stderr：空白
- Generated artifacts：無；formatter 將兩個檔案格式化
- Git status before／after：相同的本輪修改集合
- Limitations：依規則執行 formatter correction 後重跑。

### Formatter correction

- Task：T-05R2 formatting correction
- Command：`dart format .`
- Working directory：`D:\GitHub\LingoLens`
- Start time：`2026-07-28T01:28:47+08:00`
- End time：`2026-07-28T01:28:48+08:00`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`Formatted lib\application\persistence_controller.dart`; `Formatted test\application\persistence_controller_test.dart`
- Relevant stderr：空白
- Generated artifacts：無
- Git status before／after：相同的本輪修改集合
- Limitations：只格式化本輪兩個 Dart 檔案。

### Final check

- Task：T-05R2 formatting verification
- Command：`dart format --output=none --set-exit-if-changed .`
- Working directory：`D:\GitHub\LingoLens`
- Start time：`2026-07-28T01:28:58+08:00`
- End time：`2026-07-28T01:28:58+08:00`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`Formatted 14 files (0 changed) in 0.06 seconds.`
- Relevant stderr：空白
- Generated artifacts：無
- Git status before／after：相同，為本輪預期修改
- Limitations：無。

## `flutter analyze`

- Task：T-05R2 static analysis
- Command：`flutter analyze`
- Working directory：`D:\GitHub\LingoLens`
- Start time：`2026-07-28T01:29:08+08:00`
- End time：`2026-07-28T01:29:12+08:00`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`Analyzing LingoLens...`; `No issues found! (ran in 2.0s)`
- Relevant stderr：空白
- Generated artifacts：無
- Git status before／after：相同，為本輪預期修改
- Limitations：相依套件解析回報 4 個受 constraint 限制的較新版本，未升級。

## Full `flutter test`

- Task：T-05R2 full regression verification
- Command：`flutter test`
- Working directory：`D:\GitHub\LingoLens`
- Start time：`2026-07-28T01:29:19+08:00`
- End time：`2026-07-28T01:29:24+08:00`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`00:00 +24: All tests passed!`
- Relevant stderr：相依套件解析回報 4 個受 constraint 限制的較新版本；無測試錯誤。
- Generated artifacts：無
- Git status before／after：相同，為本輪預期修改
- Limitations：未執行 macOS runtime。

## Focused `flutter test`

- Task：T-05R2 visible-history policy verification
- Command：`flutter test test/application/persistence_controller_test.dart`
- Working directory：`D:\GitHub\LingoLens`
- Start time：`2026-07-28T01:29:37+08:00`
- End time：`2026-07-28T01:29:40+08:00`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`00:00 +10: All tests passed!`
- Relevant stderr：相依套件解析回報 4 個受 constraint 限制的較新版本；無測試錯誤。
- Generated artifacts：無
- Git status before／after：相同，為本輪預期修改
- Limitations：只涵蓋 persistence policy file；完整 regression 已由 full `flutter test` 覆蓋。
