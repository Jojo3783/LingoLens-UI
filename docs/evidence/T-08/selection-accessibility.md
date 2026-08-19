# T-08 Selection and Accessibility Evidence

Task：`T-08`
Working directory：`D:\GitHub\workspace\lingolens-audit-t08`
Tested commit：`ab6012f3b2a1a919eec9999cb2bfae9f1350d949`
Result：`PASS`

Commands：

- `flutter test test/widget_reading_mode_test.dart`
- `flutter test test/widget_test.dart`
- `git diff --check`

Results：

- Exit code：`0` for all commands
- Reading widget tests：`7` passed
- Existing widget regression：`6` passed
- `git diff --check` stdout empty，exit code `0`

Verified：Reading result 使用 `SelectionArea` 與 `SelectableText`；sections、quick actions、session actions 使用 stable keys；section headings 使用 header semantics；Copy／Listen 使用明確 semantics labels；Material buttons、Dropdown、Checkbox 與 live-region status 保持 keyboard-compatible；long output 在 desktop／narrow viewport 可捲動且無測試例外。

Limitation：本證據為 Flutter widget／golden backend；未宣稱 macOS VoiceOver 或 Windows Narrator 實機驗證。
