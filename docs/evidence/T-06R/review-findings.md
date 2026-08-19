# T-06R Review Findings

## Review status

- Task: T-06R_PR9_REMEDIATION_ONLY
- PR: #9
- Branch: feat/t06-domain-schema-errors
- Remediation baseline: ca87ef8d791fbf8b70894a0e7e8398c220af2a30
- Current delivery state: READY_FOR_REVIEW

## Findings and disposition

| Finding | 判定 | 處置 |
|---|---|---|
| Repository exceptions 在實際 PersistenceController boundary 原樣穿透 | 可重現且阻擋交付 | 每個 repository-backed operation 以窄範圍 helper 映射 raw exception 為 AnalysisPersistenceException |
| Provider-simulated persistence test 未經過 persistence layer | 測試責任錯置 | 從 error_contract_test.dart 移除，改由 raw repository fakes 驗證 |
| Input boundary test 宣稱 History／Cache 不變，但沒有 integrated coordinator | 不成立的保證 | 從 analysis_input_boundary_test.dart 移除；保留 provider invocation zero tests |
| T-05R／T-05R2 governance state 混淆 | 治理文件錯誤 | 分離兩個 task，T-05R closed、T-05R2 accepted and merged |

## Explicit non-scope

未修改 T-06 schema、input boundary contract、cancellation／latest-wins behavior、
dependencies、UI、platform code、Archived Handoff 或 T-07。
