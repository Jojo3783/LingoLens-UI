# T-07 Result Action Tests

## Command

```text
flutter test test/application/result_action_controller_test.dart
```

- Working directory：`D:\GitHub\workspace\lingolens-audit\T-07-working`
- Exit code：`0`
- Result：`PASS`
- Tests：`5 passed`

## Covered assertions

- Reading Copy／Fake Listen 使用 `translation`；Expression 使用 `natural`。
- Save 是 explicit、idempotent，且 Favorite 在 Save 前不可用。
- disabled History writes 產生 truthful failure 且不新增 record。
- Feedback consent 控制 immutable input／mode-specific primary output 附件，並限制單一成功提交。
- 舊 request 的 delayed action completion 不得覆寫新 request state。
