# T-04R Git Delivery Evidence

Task: T-04R Architecture Correction
Working directory: `D:\GitHub\LingoLens`

## Commit

Command: `git commit -m "docs: correct T-04 architecture boundaries"`

Result: `PASS`；focused commit message 正確。由於本檔案與 Root `handoff.md` 在 Draft PR 建立後補記，最新 commit SHA 以本檔案所屬 final Git metadata 與 final report 為準。

Initial delivery commit before PR metadata update:

```text
e1e75912e77358c12d53f9917f7980e2590d4ca2 docs: correct T-04 architecture boundaries
```

## Push

Command: `git push -u origin docs/t04r-architecture-corrections`

Exit code: `0`；stdout：

```text
branch 'docs/t04r-architecture-corrections' set up to track 'origin/docs/t04r-architecture-corrections'.
```

stderr：

```text
To https://github.com/OPluke11-abula/LingoLens.git
 * [new branch]      docs/t04r-architecture-corrections -> docs/t04r-architecture-corrections
```

Result: `PASS`。未 Push `main`。

## Draft PR

Command: `gh pr create --repo OPluke11-abula/LingoLens --draft --base main --head docs/t04r-architecture-corrections --title "docs: correct T-04 architecture boundaries" --body <T-04R body>`

Exit code: `0`。

stdout：

```text
https://github.com/OPluke11-abula/LingoLens/pull/5
```

Command: `gh pr view 5 --repo OPluke11-abula/LingoLens --json number,title,state,isDraft,baseRefName,headRefName,headRefOid,url,body`

Verified metadata at PR creation:

```text
PR: #5
State: OPEN
Draft: true
Title: docs: correct T-04 architecture boundaries
Base: main
Head: docs/t04r-architecture-corrections
Head SHA at PR creation: e1e75912e77358c12d53f9917f7980e2590d4ca2
URL: https://github.com/OPluke11-abula/LingoLens/pull/5
```

Result: `PASS`；PR 維持 Draft，未 Merge、未啟用 Auto-merge、未標示 Ready for Review。

## Final delivery limitation

本檔案與 Root `handoff.md` 的 PR metadata 補記會形成同一 focused commit 的 metadata amendment；因此 final Head SHA 必須以最後一次 `git rev-parse HEAD`、`git push` 與 `gh pr view 5` output 為準，不使用上方 PR 建立時的暫存 SHA 取代 final metadata。
