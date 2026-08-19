# T-07R Regression Evidence

## Focused command

Command：`flutter test test/application/result_action_controller_test.dart test/widget_test.dart`

Working directory：`D:\GitHub\workspace\lingolens-audit\T-07-working`

Exit code：`0`

Result：`PASS`

stdout 摘要：`13 passed`，其中 7 個 application action tests 與 6 個 widget tests。

## Covered remediation behaviors

- Feedback：Request A 的 reason、comment、consent 不會跨越 Request B；Request B 未重新 consent 時不附加 input／output；同一 RequestId 最多一次成功提交。
- Mode：Dropdown 顯示 Application `effectiveMode`；Expression manual override 可見；`Use suggestion` 後 visible mode、effective mode 與 submitted `AnalysisSuccess.mode` 均為 Reading。
- Async：同一 RequestId 中較舊 Copy 的 success 或 failure 不得覆寫較新的 Listen success；跨 request stale completion 仍被拒絕。
- Existing lifecycle：Save idempotency、Favorite after Save、disabled History、mode-specific output、cancel、retry 與 widget result rendering 均維持通過。

## Focused test names

- `same-request older Copy cannot replace newer Listen success`
- `same-request older Copy failure cannot replace newer success`
- `T-07R Mode Dropdown tracks effective mode and submitted mode`
- `T-07R Feedback state resets at a new RequestId boundary`
