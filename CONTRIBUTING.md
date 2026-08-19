# LingoLens Contribution Guide

## 工作規則

- 不得直接 Push 到 `main`。
- 每個 Task 使用獨立 Branch。
- Commit 應小型且具有單一目的。
- Pull Request 必須對應 Task ID。
- Behavior Change 必須加入或更新 Test。
- No evidence, no completion claim。
- Source Reuse 必須記錄 Provenance、Permission 與 License 狀態。
- 不得修改 `D:\GitHub\temp` 下的唯讀 Source Repository。
- 不得提交 Secret、Database、Raw Input 或 Build Artifact。
- 每個變更型 Task 結束時更新 Root `handoff.md`。
- Archived Handoff 不得覆蓋目前 Root `handoff.md`。
- Merge 由 Luke 最終決定；Codex 不得自行 Merge。

## 驗證與文件

每個 Task 必須保存完整 Command Evidence，並使用 `PASS`、`FAIL`、`BLOCKED`、`NOT_RUN` 或 `UNVERIFIED` 等真實結果。

所有新文件、PR Description 與 Commit Message 使用台灣繁體中文；Command、Git output、API、Framework、Package 與第三方原文保留原樣。
