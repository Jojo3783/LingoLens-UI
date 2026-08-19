# T-08 Schema v2 Evidence

Task：`T-08`
Working directory：`D:\GitHub\workspace\lingolens-audit-t08`
Tested commit：`ab6012f3b2a1a919eec9999cb2bfae9f1350d949`
Result：`PASS`

## Command record

Command：`flutter test test/domain/analysis_models_test.dart`

- Start／End：`2026-07-28`；MCP command wrapper 未提供細部時間戳
- Exit code：`0`
- Relevant stdout：`All tests passed!`；`15` tests passed
- Relevant stderr：Dependency resolution only reported four available but incompatible newer packages；未修改 dependency
- Generated artifacts：無
- Git status before／after：frozen clone；implementation commit unchanged
- Limitations：未執行 real provider 或 durable persistence。

## Verified contract

- `analysisSchemaVersion = 2`
- Reading exact fields：`translation`、`sentenceAnalysis`、`grammar`、`vocabulary`、`nuance`
- `note` 已移除
- Missing、unexpected、null、wrong type、empty、whitespace 與 unsupported schema version 均維持 typed failure contract
