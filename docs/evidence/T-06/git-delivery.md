# T-06 Git Delivery Evidence

## Before delivery

- Branch：`feat/t06-domain-schema-errors`
- Base：`main`
- Base SHA：`71bb73c650c7b45b0e9dc96abd0e14d7c0f18656`
- Local pre-delivery HEAD：`de4da2c`，final SHA 以最後 Push 後驗證為準

## Scoped commits

1. `e46b8e4` `test: define T-06 schema and boundary contracts`
2. `e0aa6c1` `test: correct T-06 stream fixtures`
3. `991bb24` `feat: add T-06 domain schema and error contract`
4. `fc22e77` `test: preserve valid structured output strings`
5. `de4da2c` `docs: record T-06 governance and evidence`

## Delivery policy

- 只 Push `feat/t06-domain-schema-errors`。
- 不 Push `main`。
- 建立 OPEN Draft PR targeting `main`。
- 不 Merge、不啟用 auto-merge、不標示 Ready for Review、不刪除 Branch。
- T-07 維持 `NOT_AUTHORIZED`。

## PR metadata

- PR：`#9`
- URL：<https://github.com/OPluke11-abula/LingoLens/pull/9>
- State：`OPEN`
- Draft：`true`
- Base：`main`
- Head：`feat/t06-domain-schema-errors`
- Head SHA at PR creation：`1251eb1140d37b8a757af79611f5861427548eb8`
- 此後的 delivery metadata Commit 會更新 PR Head；最終 SHA 以 final report 與 GitHub verification 為準。
- Required flags：`STOP_BEFORE_MERGE: true`、`AWAITING_CHATGPT_TEAM_REVIEW: true`
