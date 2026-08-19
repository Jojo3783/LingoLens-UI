# T-12R Evidence

本目錄記錄既有 PR #15 的 T-12R expanded remediation。所有結果均以實際
command 或明確的 environment limitation 標記；`NOT_RUN` 與 `BLOCKED` 不得視為
`PASS`。

## Immutable delivery

- Repository: `D:\\GitHub\\LingoLens`
- Branch: `feat/t12-windows-integration`
- PR: `#15`，Base `main`，Draft `true`
- Required base: `10f2d3da98d1fdbdfd2e0abbb39d758a396a6183`
- Starting HEAD: `b22b7223df2575bfa79f6cd412285e51ea54bf74`
- No new branch or PR；no Merge、Auto-merge 或 Ready for Review。

## Evidence index

- [reference-decisions.md](reference-decisions.md)：Ethan／LAS 參考決策與 provenance boundary。
- [dependency-review.md](dependency-review.md)：dependency、credential 與 source boundary 審查。
- [native-verification.md](native-verification.md)：Windows native harness 與 owner-thread lifecycle。
- [dart-verification.md](dart-verification.md)：Flutter、Dart、focused／full tests 與 build command records。
- [ui-qa.md](ui-qa.md)：responsive shell、destination、provider disclosure 與 semantics。
- [secure-settings-qa.md](secure-settings-qa.md)：single profile、secure credential boundary 與 runtime switching。
- [windows-manual-smoke.md](windows-manual-smoke.md)：實際 executable smoke 結果與限制。
- [macos-verification.md](macos-verification.md)：Windows host 無法宣稱 macOS runtime pass 的限制。
- [security-review.md](security-review.md)：raw input、response、key、prompt 與 telemetry 的檢查。

## Global limitations

- Live OpenAI API 與 real API key：`NOT_RUN`、未授權。
- `D:\\GitHub\\temp` source repositories：唯讀，未修改或建置。
- Archived Handoff：未修改；hash 應維持
  `43f77552800dfbc68b983da603b3b5483217e7c8bea2ba04fdce03fee1135279`。
- macOS native runtime：`BLOCKED`，目前 host 為 Windows。
