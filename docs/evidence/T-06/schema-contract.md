# T-06 Schema Contract Evidence

## Implemented contract

- Framework-independent serialization uses `dart:convert`。
- Shared envelope：`AnalysisResult`。
- Exact schema version：`schemaVersion = 1`。
- Required top-level properties：`schemaVersion`、`providerLabel`、`reading`、`expression`。
- Required `reading` properties：`translation`、`note`。
- Required `expression` properties：`natural`、`polite`。
- `ReadingAnalysis` 與 `ExpressionAnalysis` 保持 distinct typed nested models。
- `toJson`、`fromJson`、`toJsonText`、`fromJsonText` 均提供 deterministic typed contract。
- Properties missing、null、wrong type、unexpected、invalid JSON syntax 或 unsupported schema version 均轉為 typed `INVALID_STRUCTURED_OUTPUT`。
- `providerLabel` 與 nested strings 以 `trim()` 驗證非空，但合法原始字串保留。
- `FakeAnalysisProvider` 仍回傳完整、非空、version-1 compatible typed envelope。

## Evidence tests

- Valid deserialization：PASS
- Object → JSON → object round trip：PASS
- Reading／Expression distinct type：PASS
- Missing、null、wrong type、unexpected fields：PASS
- Invalid syntax：PASS
- Unsupported version：PASS
- Empty／whitespace output：PASS
- Parser details／raw payload not exposed：PASS
- Valid output string preservation：PASS
