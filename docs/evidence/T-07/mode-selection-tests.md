# T-07 Mode Selection Tests

## Command

```text
flutter test test/application/mode_selection_test.dart
```

- Working directory：`D:\GitHub\workspace\lingolens-audit\T-07-working`
- Exit code：`0`
- Result：`PASS`
- Tests：`3 passed`

## Covered assertions

- Application-owned suggestion and manual override。
- `Use suggestion` clears the override。
- Submitted mode is captured in `AnalysisRequest` and `AnalysisSuccess`。
- Retry preserves the last submitted mode while creating a new `RequestId`。
- Loading state rejects mode changes。
