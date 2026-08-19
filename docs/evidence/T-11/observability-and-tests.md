# T-11 Observability and Test Evidence

## Observability contract

Allowed event types:

```text
analysis_request_started
provider_started
provider_completed
schema_decode_completed
analysis_request_failed
analysis_request_cancelled
```

Measured metrics:

```text
provider_setup_ms
response_read_ms
json_decode_ms
total_latency_ms
```

`InMemoryAnalysisTelemetrySink` 預設容量為 200，採 oldest eviction；sink failure
會被隔離，不會改變 provider outcome。Telemetry 欄位不含 raw input、prompt、output、
response body、clipboard、credential、Auth header、stack trace 或 arbitrary exception。

## Focused verification

```text
Task: T-11 focused regression verification
Command: flutter test test/infrastructure/openai_responses_analysis_provider_test.dart test/application/t10_strategy_late_completion_test.dart test/widget_provider_disclosure_test.dart test/application/analysis_execution_strategy_test.dart test/application/analysis_controller_test.dart
Working directory: D:\GitHub\workspace\lingolens-audit-t11-verify6
Exit code: 0
Result: PASS
Relevant stdout:
OpenAiResponsesAnalysisProvider tests: 8 passed
T-10 late completion closure tests: 3 passed
Provider disclosure widget test: 1 passed
Existing strategy tests: 8 passed
Existing controller tests: 10 passed
All tests passed! (30 tests)
Relevant stderr: dependency resolver only reported newer incompatible package versions; no test error。
```

## Full verification

```text
Task: T-11 full regression verification
Command: flutter test
Working directory: D:\GitHub\workspace\lingolens-audit-t11-verify7
Exit code: 0
Result: PASS
Relevant stdout: All tests passed! (117 tests)
Relevant stderr: dependency resolver only reported newer incompatible package versions; no test error。
```

## Static checks

```text
Task: T-11 static verification
Command: dart format --output=none --set-exit-if-changed lib test && flutter analyze
Working directory: D:\GitHub\workspace\lingolens-audit-t11-verify7
Exit code: 0
Result: PASS
Relevant stdout:
Formatted 47 files (0 changed)
No issues found!
Relevant stderr: empty apart from dependency-version notices from Flutter tooling。
```

T-10 同一 branch closure：late Preview success、late Preview failure、late Full success
均以 invocation count 與 final Request B state 驗證；不建立 T-10R。
