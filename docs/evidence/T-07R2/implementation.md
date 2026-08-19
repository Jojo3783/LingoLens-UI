# T-07R2 Implementation Evidence

## Finding

原本 Feedback completion 會直接清除全域 `_feedbackInFlight`。當 Request A completion 晚於 Request B 開始時，會錯誤解除 B 的 ownership。

## 修正

- `AnalysisActionController` 新增 `_feedbackOperation`，以 `ActionToken` 綁定目前 Feedback persistence operation。
- 只有相同 operation owner 的 success／failure completion 才能清除 `_feedbackInFlight` 與 owner。
- persistence success 先將完成的 `RequestId` 加入 `_completedFeedback`，即使目前 UI 已切換至其他 request。
- stale completion 不會更新目前 request 的 `feedbackSubmitted`、action phase 或 message。
- `reset()`、new request、`dispose()` 會使舊 owner 失效。
- 保留既有 `RequestId` argument、consent policy、generation guard、immutable snapshot、repository contract 與 dependency。
