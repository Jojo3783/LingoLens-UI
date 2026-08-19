# T-07 Widget Tests

## Command

```text
flutter test test/widget_test.dart
```

- Working directory：`D:\GitHub\workspace\lingolens-audit\T-07-working`
- Exit code：`0`
- Result：`PASS`
- Tests：`4 passed`

## Covered assertions

- Manual input 成功結果與 typed failure／retry。
- Loading 可取消並顯示 cancelled state。
- Expression override 只顯示 mode-specific `Natural`，並提供 `Listen（Fake）`、Session-only Save、Favorite 與 Feedback controls。
- 使用 stable keys：`analysis-input`、`submit-analysis`、`cancel-analysis`、`retry-analysis`、`mode-selector`、`copy-result`、`listen-fake`、`save-result`、`favorite-toggle`、`feedback-submit`。
