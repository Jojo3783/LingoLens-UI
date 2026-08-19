# T-06 Error Contract Evidence

## Explicit wire values and messages

| Wire value | Sanitized message |
|---|---|
| `EMPTY_INPUT` | `請輸入要分析的文字。` |
| `INPUT_TOO_LONG` | `輸入文字不可超過 2000 個 Unicode code points。` |
| `SELECTION_UNAVAILABLE` | `無法取得選取的文字。` |
| `ACCESSIBILITY_PERMISSION_REQUIRED` | `需要輔助使用權限才能取得選取的文字。` |
| `PROVIDER_NOT_FOUND` | `找不到可用的分析服務。` |
| `PROVIDER_TIMEOUT` | `分析逾時，請重試。` |
| `PROVIDER_FAILED` | `分析服務失敗，請重試。` |
| `REQUEST_CANCELLED` | `分析已取消。` |
| `INVALID_STRUCTURED_OUTPUT` | `分析服務回傳了無效格式。` |
| `PERSISTENCE_FAILED` | `無法儲存分析結果。` |
| `UNKNOWN_ERROR` | `分析失敗，請稍後重試。` |

## Mapping

- Input validation failure → matching typed `AnalysisInputException`。
- Known provider timeout／missing provider／provider failure → typed `AnalysisProviderException` mapping。
- Schema/parser failure → `AnalysisProviderException` with `INVALID_STRUCTURED_OUTPUT`。
- Cancellation → `REQUEST_CANCELLED`。
- Repository write failure contract → `AnalysisPersistenceException` with `PERSISTENCE_FAILED`。
- Unexpected exception → sanitized `UNKNOWN_ERROR`。
- `AnalysisApplicationException.toString()` exposes only the wire value；不包含 raw payload、parser detail、exception text 或 stack trace。
