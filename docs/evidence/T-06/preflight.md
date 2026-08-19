# T-06 Preflight Evidence

## Authorization

- Controlling authorization：`IMPLEMENTATION_AUTHORIZED: T-06`
- Unauthorized boundary：`T-07_AND_LATER: NOT_AUTHORIZED`
- Repository：`D:\GitHub\LingoLens`
- Required baseline：`71bb73c650c7b45b0e9dc96abd0e14d7c0f18656`

## Command receipts

### Fetch all remotes and prune stale refs

- Command：`git fetch --all --prune`
- Working directory：`D:\GitHub\LingoLens`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`052ca25..71bb73c main -> origin/main`
- Relevant stderr：空
- Generated artifacts：Git remote refs only
- Git status before／after：未變更工作檔案
- Limitations：無

### Remote verification

- Command：`git remote -v`
- Working directory：`D:\GitHub\LingoLens`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`origin https://github.com/OPluke11-abula/LingoLens.git (fetch／push)`
- Relevant stderr：空

### PR #8 verification

- Command：`gh pr view 8 --repo OPluke11-abula/LingoLens --json number,title,state,isDraft,baseRefName,headRefName,headRefOid,mergeCommit,url`
- Working directory：`D:\GitHub\LingoLens`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：PR `#8`、`state: MERGED`、merge commit `71bb73c650c7b45b0e9dc96abd0e14d7c0f18656`
- Relevant stderr：空

### Immutable baseline and worktree

- Commands：`git rev-parse origin/main`、`git status --short --branch`
- Working directory：`D:\GitHub\LingoLens`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`origin/main = 71bb73c650c7b45b0e9dc96abd0e14d7c0f18656`；preflight working tree clean
- Relevant stderr：空

### Archived Handoff checksum

- Command：`Get-FileHash -Algorithm SHA256 docs/archive/handoffs/project-handoff-v1.1-43f77552.md`
- Working directory：`D:\GitHub\LingoLens`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`43f77552800dfbc68b983da603b3b5483217e7c8bea2ba04fdce03fee1135279`
- Relevant stderr：空

## Source review notes

- `docs/PRODUCT_DEFINITION.md`：`NOT_FOUND`；Repository 現有替代文件為 `docs/PRODUCT_SCOPE.md`，已讀取並記錄此限制。
- ADR-001 至 ADR-007 個別文件的 `Approval` 均為 `Status: ACCEPTED`。
- `docs/decisions/README.md` 的「目前沒有任何 ADR 被核准」與個別 ADR 狀態不一致；依 source-of-truth precedence，採個別 accepted ADR 內容，未修改 ADR 或索引。
- Existing Domain、`AnalysisController`、Fake Provider、repository contracts、deterministic fakes 與 T-05/T-05R/T-05R2 tests 均已讀取。

## Branch

- Created：`feat/t06-domain-schema-errors`
- Created from：`origin/main` at `71bb73c650c7b45b0e9dc96abd0e14d7c0f18656`
- Direct work on `main`：未進行
