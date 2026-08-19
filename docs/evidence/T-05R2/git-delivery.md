# T-05R2 Git Delivery Evidence

## Authorization and Base

- Authorization：`IMPLEMENTATION_AUTHORIZED: T-05R2_POLICY_FIX_ONLY`
- Base branch：`main`
- Base SHA：`052ca2534b9809f99b8f4b3413a2b189a51c113f`
- Branch：`fix/t05r2-visible-history-limit`
- PR #7 merge baseline：`052ca2534b9809f99b8f4b3413a2b189a51c113f`

## Scoped Commits

1. `9e84b5fb50ce6e846817c42b4d975ee1fff45e92` `fix: enforce total visible history limit`
2. `59acaa02bb25e69429feeddff625f9ac1f076731` `test: verify favorite retention and visible selection`
3. `1532224c87b5a3f221568e8210607dd026af296f` `docs: record T-05R2 evidence and governance state`
4. 本交付證據補充 Commit：建立後以最終 `git rev-parse HEAD` 與 PR metadata 回報。

## Push Evidence

- Command：`git push -u origin fix/t05r2-visible-history-limit`
- Result：`PASS`
- Remote：`https://github.com/OPluke11-abula/LingoLens.git`
- Push output 確認新 Branch 已建立並設定追蹤 `origin/fix/t05r2-visible-history-limit`。

## Draft PR Metadata Before Final Receipt Commit

- PR：`#8`
- URL：<https://github.com/OPluke11-abula/LingoLens/pull/8>
- Title：`fix: enforce total visible history limit`
- State：`OPEN`
- Draft：`true`
- Base：`main`
- Head：`fix/t05r2-visible-history-limit`
- Head SHA at PR creation：`1532224c87b5a3f221568e8210607dd026af296f`
- Merge、Ready for Review、auto-merge：未執行且未授權
- PR #7：未更新

## Delivery Rules

- 僅 Push `fix/t05r2-visible-history-limit`。
- 不 Push `main`。
- 不使用 force push。
- 不 Merge、不啟用 auto-merge、不標示 Ready for Review、不刪除 Branch。
- PR #8 維持 Draft，等待 Team Review。
- T-06 維持 `NOT_AUTHORIZED`。

## Final Receipt Note

本檔案補充 Commit 會使 PR #8 Head SHA 改變；最終 Branch HEAD、PR Head SHA、Working Tree 與 GitHub metadata 以最終唯讀驗證及 Task Report 為準。
