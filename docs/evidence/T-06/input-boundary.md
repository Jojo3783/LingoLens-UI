# T-06 Input Boundary Evidence

- Shared constant：`maxAnalysisInputCharacters = 2000`。
- Validation component：`AnalysisInput.fromRaw`。
- Normalization：先執行 `input.trim()`。
- Count definition：`normalizedInput.runes.length`，即 Unicode scalar values；不使用 UTF-16 code units、bytes 或 grapheme clusters。
- Empty／whitespace-only：`EMPTY_INPUT`，provider invocation count `0`。
- Exactly 2,000 scalar values：accepted。
- 2,001 scalar values：`INPUT_TOO_LONG`，provider invocation count `0`。
- Supplementary-plane emoji：每一個 emoji 以一個 scalar value 計算。
- Invalid input 不寫入 History 或 Cache。
- Existing cancel、retry、latest-wins、stale-result rejection 與 dispose behavior 保留。
