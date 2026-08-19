# T-05R Verification Command Receipts

所有 command 均於 `D:\GitHub\LingoLens` 執行。Git status before／after 均為同一個 remediation 工作樹，沒有 command 產生非預期 Repository 修改。

## `flutter pub get`

- Task：T-05R dependency verification
- Command：`flutter pub get`
- Working directory：`D:\GitHub\LingoLens`
- Start time：`2026-07-28T01:05:25+08:00`
- End time：`2026-07-28T01:05:26+08:00`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`Got dependencies!`; `4 packages have newer versions incompatible with dependency constraints.`
- Relevant stderr：空白
- Generated artifacts：無；`pubspec.lock` 未產生差異
- Git status before：`fix/t05r-remediation` 加本輪預期修改
- Git status after：與 before 相同
- Limitations：未執行 dependency upgrade。

## `dart format --output=none --set-exit-if-changed .`

- Task：T-05R formatting verification
- Command：`dart format --output=none --set-exit-if-changed .`
- Working directory：`D:\GitHub\LingoLens`
- Start time：`2026-07-28T01:05:34+08:00`
- End time：`2026-07-28T01:05:35+08:00`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`Formatted 14 files (0 changed) in 0.06 seconds.`
- Relevant stderr：空白
- Generated artifacts：無
- Git status before：`fix/t05r-remediation` 加本輪預期修改
- Git status after：與 before 相同
- Limitations：無。

## `flutter analyze`

- Task：T-05R static analysis
- Command：`flutter analyze`
- Working directory：`D:\GitHub\LingoLens`
- Start time：`2026-07-28T01:05:45+08:00`
- End time：`2026-07-28T01:05:50+08:00`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`Analyzing LingoLens...`; `No issues found! (ran in 2.5s)`
- Relevant stderr：空白
- Generated artifacts：無
- Git status before：`fix/t05r-remediation` 加本輪預期修改
- Git status after：與 before 相同
- Limitations：Flutter tool 先解析 dependencies，但未修改 `pubspec.yaml` 或 `pubspec.lock`。

## `flutter test`

- Task：T-05R full test verification
- Command：`flutter test`
- Working directory：`D:\GitHub\LingoLens`
- Start time：`2026-07-28T01:05:57+08:00`
- End time：`2026-07-28T01:06:02+08:00`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`00:00 +19: All tests passed!`
- Relevant stderr：相依套件解析只回報 4 個受 constraint 限制的較新版本；無測試錯誤。
- Generated artifacts：無
- Git status before：`fix/t05r-remediation` 加本輪預期修改
- Git status after：與 before 相同
- Limitations：未執行 macOS runtime。
