# T-11 Provider Contract and Security Evidence

## Implemented boundary

```text
AnalysisProvider
    → OpenAiResponsesAnalysisProvider
    → AnalysisHttpTransport
    → HttpClientAnalysisHttpTransport
    → https://api.openai.com/v1/responses
```

- `OpenAiResponsesAnalysisProvider` 僅實作 full-only `analyzeFull`。
- Remote selection 使用 `FullOnlyStrategy`；default composition 使用 deterministic Fake Provider 與 `TwoStageStrategy`。
- Endpoint 為固定 HTTPS URL；model 必須由 explicit configuration 提供，raw input 不會控制 endpoint、header 或 model。
- Credential 透過 `ProviderCredentialSource`；缺少 configuration 或 credential 時，transport invocation count 為零。
- Request 使用 `store: false`、strict JSON Schema、root／nested `additionalProperties: false`，沒有 tools、web、file、conversation 或 background 欄位。
- Decoder 只接受 exact `reading` 與 `expression` model fields，並由 adapter 注入 schema version `3` 與 `OpenAI Responses API` label。
- Refusal、incomplete、malformed、empty、unexpected fields 都維持 typed failure，不回傳 fabricated success。

## Typed error mapping

| Boundary | Error code |
|---|---|
| missing model／invalid bounded config | `PROVIDER_CONFIGURATION_REQUIRED` |
| missing credential／401／403 | `PROVIDER_AUTHENTICATION_FAILED` |
| 429 | `PROVIDER_RATE_LIMITED` |
| refusal | `PROVIDER_REFUSED` |
| timeout | `PROVIDER_TIMEOUT` |
| user／new-request cancellation | `REQUEST_CANCELLED` |
| malformed structured output | `INVALID_STRUCTURED_OUTPUT` |
| 5xx／other transport failure | `PROVIDER_FAILED` |

## Security scan

```text
Task: T-11 credential and sensitive-data boundary
Command: grep -RInE "OPENAI_API_KEY|sk-[A-Za-z0-9]|Bearer |api[_-]?key|raw input|response body" --exclude-dir=.git --exclude-dir=.dart_tool --exclude-dir=build .
Working directory: D:\GitHub\LingoLens
Exit code: 0
Result: PASS_WITH_EXPECTED_BOUNDARY_MATCHES
Relevant stdout:
lib/infrastructure/openai/openai_request_builder.dart: Authorization header construction
lib/infrastructure/openai/provider_credentials.dart: OPENAI_API_KEY environment lookup
test/infrastructure/openai_responses_analysis_provider_test.dart: controlled-credential fixture
Relevant stderr: empty
Limitations: 以上為預期 adapter boundary 與 non-live test fixture；沒有 live API key、secret value、raw input、raw response 或 private log。
```

## Archive and dependency checks

```text
Task: T-11 integrity boundary
Command: git diff -- pubspec.yaml pubspec.lock; sha256sum docs/archive/handoffs/project-handoff-v1.1-43f77552.md
Working directory: D:\GitHub\LingoLens
Exit code: 0
Result: PASS
Relevant stdout:
43f77552800dfbc68b983da603b3b5483217e7c8bea2ba04fdce03fee1135279 *docs/archive/handoffs/project-handoff-v1.1-43f77552.md
Relevant stderr: empty
```
