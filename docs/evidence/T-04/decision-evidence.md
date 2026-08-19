# T-04 Decision Evidence

Task: T-04 Proposed Architecture Decisions
Result: PASS for evidence review; all decisions remain `PROPOSED`.
Working directory: `D:\GitHub\LingoLens`

## Main branch preflight

Command:
```bash
git status --short --branch
git switch main
git pull --ff-only
git rev-parse HEAD
git log -1 --oneline
```

Observed output:
```text
Initial status: ## docs/code-capability-audit...origin/docs/code-capability-audit
git switch main: exit 0
git pull --ff-only: exit 0
Updating 8451919..27804f2
Fast-forward
git rev-parse HEAD: 27804f2263382ae6a2ba3922d1e987db60c73c75
git log -1 --oneline: 27804f2 Merge pull request #3 from OPluke11-abula/docs/code-capability-audit
```

stderr contained the expected branch switch and remote fetch messages. Working Tree was clean before switch and `main` HEAD begins with the Product Owner supplied prefix `27804f2`.

## T-04 branch

Command: `git switch -c docs/proposed-architecture-decisions`

Exit code: `0`
stderr: `Switched to a new branch 'docs/proposed-architecture-decisions'`

## Evidence read set

Read without re-running the full T-03 audit:

- `AGENTS.md`
- `agent_tasks.md`
- `handoff.md`
- `README.md`
- `docs/integration/SOURCE_BASELINES.md`
- `docs/integration/BUILD_AND_TEST_REPORT.md`
- `docs/integration/CAPABILITY_MATRIX.md`
- `docs/integration/CODE_LEVEL_AUDIT.md`
- `docs/reuse/SOURCE_REUSE_MATRIX.md`
- `docs/quality/T-03_FINDINGS.md`
- all files under `docs/evidence/T-03/`
- `docs/ACCEPTANCE_CRITERIA.md`
- existing `docs/ARCHITECTURE.md`
- `docs/decisions/README.md`

## Evidence-to-decision mapping

| Decision | Direct evidence | Finding / constraint handled |
|---|---|---|
| ADR-001 | T-02 baseline and T-03 reuse matrix | M1 source/test defects、license／permission uncertainty |
| ADR-002 | Prototype／M1／M2 `QueryCoordinator` snippets | async lifecycle、manual override、stale state、testability |
| ADR-003 | Prototype SwiftData、M1 in-memory、M2 Isar repositories | F-006 cache/history separation、limit 20、favorite policy |
| ADR-004 | Prototype／M1／M2 Codex services and T-03 security evidence | F-001 silent fallback、F-002 raw logging、process contract |
| ADR-005 | AGENTS progressive result rule、existing typed schemas | partial state、duplicate cost、stage-aware cache／persistence |
| ADR-006 | T-03 F-003、M2 process runner timeout behavior | true process cancellation、latest-request-wins、race tests |
| ADR-007 | M1／M2 platform calls、Prototype macOS adapters、T-02 build limits | F-004 clipboard、F-005 PowerShell、Windows／macOS verification |

## Explicit limitations

- T-04 沒有重新執行完整 T-03 audit、Flutter commands、build、test 或 dependency restore。
- T-04 沒有修改 `D:\GitHub\temp` 下的唯讀來源。
- T-04 的 architecture choice 是 evidence-backed proposal，不是已決定事實。
- Windows build toolchain 與 macOS integration 仍未驗證；不能被 ADR 文字轉成 PASS。
- 未發現新的 permission／license evidence；donor production code 不在 T-04 scope。
