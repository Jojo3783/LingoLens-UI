# T-07 Preflight Evidence

## Result

`PASS`

## Repository

- Working directory：`D:\GitHub\LingoLens`
- Required baseline：`db04a5843462abfbfec8385cb7717dd9b1695b33`
- Branch：`feat/t07-manual-input-mvp`
- Remote：`https://github.com/OPluke11-abula/LingoLens.git`
- `origin/main`：`db04a5843462abfbfec8385cb7717dd9b1695b33`
- PR #9：`MERGED`，merge commit 與 required baseline 相同

## Commands and evidence

### `git fetch --all --prune`

- Exit code：`0`
- Result：`PASS`
- Relevant output：`origin/main` 更新至 `db04a5843462abfbfec8385cb7717dd9b1695b33`

### `gh pr view 9 --repo OPluke11-abula/LingoLens --json number,state,mergedAt,mergeCommit,baseRefName,headRefName,headRefOid,url,isDraft`

- Exit code：`0`
- Result：`PASS`
- Relevant output：PR `#9`、state `MERGED`、merge commit `db04a5843462abfbfec8385cb7717dd9b1695b33`、base `main`、isDraft `false`

### `git diff --quiet origin/main db04a5843462abfbfec8385cb7717dd9b1695b33`

- Exit code：`0`
- stdout／stderr：empty
- Result：`PASS`

### Archive checksum

- Path：`docs/archive/handoffs/project-handoff-v1.1-43f77552.md`
- SHA-256：`43f77552800dfbc68b983da603b3b5483217e7c8bea2ba04fdce03fee1135279`
- Result：`PASS`

## Limitations

T-07 working tree contains the implementation changes after branch creation；此 receipt 記錄的是 immutable baseline 與 branch boundary，不宣稱工作樹 clean。
