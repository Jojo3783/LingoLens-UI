# T-07R2 Controlled Race Test Evidence

## Tests

- `late Feedback success cannot clear newer RequestId ownership`
- `late Feedback failure cannot clear newer RequestId ownership`

兩項測試均使用可獨立控制 Request A／B completion 的 `_ControlledFeedbackRepository`，並驗證：

- A／B persistence invocation count。
- B pending 時重複 submission 不會增加 repository invocation count。
- A late success／failure 不會清除 B in-flight ownership。
- B final visible state 屬於 B，且只有一次 B record。
- success variant 產生恰好一筆 A 與一筆 B record。
- failure variant 只產生一筆 B record，B 最終為 `feedbackSubmitted = true`。
