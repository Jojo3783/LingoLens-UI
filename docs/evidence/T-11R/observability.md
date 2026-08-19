# T-11R Observability Evidence

## Metric boundaries

| Metric | 實際 boundary |
|---|---|
| `provider_setup_ms` | `configuration.validate()`／credential retrieval／request construction 開始至 HTTP request 完成建構、尚未送出 |
| `response_read_ms` | transport 取得 HTTP response headers 後至 response body bytes 完整讀取結束；由 `AnalysisHttpResponse.responseReadDuration` 傳回 |
| `json_decode_ms` | `OpenAiResponseDecoder.decode()` 的 typed JSON／schema decode 區段 |
| `total_latency_ms` | 一次 provider analysis 從 request start 至成功或 typed failure terminal outcome |

Deterministic clock test 驗證精確值：`provider_setup_ms = 10 ms`、
`response_read_ms = 37 ms`、`json_decode_ms = 12 ms`、`total_latency_ms = 60 ms`。
`response_read_ms` 不再代理整個 `postJson()` round trip。

## Terminal event ordering

成功順序為：

```text
analysis_request_started
provider_started
schema_decode_completed
provider_completed
```

Invalid schema、refusal、timeout、transport failure 與 cancellation 都不會先發出
`provider_completed`；每次 execution 僅有一個 failure 或 cancellation terminal
outcome。Telemetry sink exception 會被隔離，不改變 application behavior。

## Privacy and provider identity

Typed telemetry 不記錄 raw input、raw response、API key、Authorization header、
完整 prompt、clipboard 或 stack trace。`AnalysisPage` 改用 provider-neutral
`手動輸入 → 模式選擇 → 分析結果`，實際 provider 由 disclosure card 單獨揭露；
Fake 與 OpenAI Remote 不會同時出現在同一個固定標題中。
