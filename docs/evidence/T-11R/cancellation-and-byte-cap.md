# T-11R Cancellation、Deadline 與 Body Limit Evidence

## Controlled cancellation

- Request 尚未建立：`HttpSession.close(force: true)` 由 cancellation listener 觸發；
  payload write count 為 `0`，結果為 typed `cancelled`。
- Request 已建立：listener 同時呼叫 `HttpRequestSession.abort()` 與 force-close；
  header callback 觸發 cancellation 後，payload write count 為 `0`。
- Cancellation／transport exception race：token 已取消時，socket／session exception
  優先映射為 typed `AnalysisHttpFailureKind.cancelled`。
- Body read 期間 cancellation：subscription 會被停止，底層 request 與 session 會
  關閉，舊 body 不會繼續寫入 application state。

## Overall deadline

`deadline = transportClock.now() + request.timeout` 在一次 provider execution 開始
時建立。Connect、request close 與 body read 每次只使用同一 deadline 的剩餘時間；
不會在各階段重新取得完整 `request.timeout`。Controlled test 以固定 `8 ms + 8 ms`
階段與 `10 ms` 整體 deadline 驗證 timeout，不依賴 live network。

## Response byte cap

`maxResponseBytes` 是有名稱且有文件說明的 hard cap，預設為 `1 MiB`。Body 以
streaming chunk 計數；`exact limit` 通過，`limit + 1 byte` 立即關閉 request／session
並回傳 sanitized typed `responseTooLarge` transport failure，Provider 再映射為
既有的 `INVALID_STRUCTURED_OUTPUT` user-safe error。Raw response 不進入 error、Log、
Telemetry 或 UI。
