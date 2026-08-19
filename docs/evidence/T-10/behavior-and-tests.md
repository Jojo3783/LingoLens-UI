# T-10 Behavior 與 Test 驗證證據

Task: T-10 Progressive results and cancellation

Working directory: `D:\\GitHub\\workspace\\lingolens-audit-t10-red`

Focused command:

```text
flutter test test/application/analysis_execution_strategy_test.dart test/widget_progressive_results_test.dart test/application/analysis_controller_test.dart test/application/mode_selection_test.dart test/widget_test.dart test/widget_reading_mode_test.dart
```

Exit code: `0`

結果：`PASS`

相關 stdout：`All tests passed!`，共 `41` tests。

Focused suite 驗證：

- Preview → Full success，以及未呼叫 Preview 的 Full-only routing；
- typed Preview failure 後繼續 Full success；
- Full-stage failure 保留可用的 partial Preview；
- Preview 與 Full 階段的 cancellation；
- 拒絕 Request A 相對於 Request B 的 stale Preview／Full completion；
- 使用新 `RequestId` 的 retry 與 dispose cancellation boundary；
- Reading Preview Translation 與 Expression Preview Natural identity；
- accessible `Preview／部分結果` marker；
- partial 階段不顯示 Full actions 且不寫入 History。

完整 command：

```text
flutter test
```

Exit code: `0`

Result: `PASS`

相關 stdout：`All tests passed!`，共 `104` tests。

Generated artifacts：Flutter test 相依套件與 tool state 只產生於 disposable
audit Clone。Verification 未在 LingoLens Repository 寫入 dependency file 或
generated artifact。
