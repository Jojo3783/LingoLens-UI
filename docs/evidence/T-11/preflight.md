# T-11 Preflight Evidence

## Authorization and scope

- Current task: `T-11 — Provider adapters and observability`
- Authorization: `IMPLEMENTATION_AUTHORIZED: T-11`
- Primary real provider: `OPENAI_RESPONSES_API`
- Provider mode: `FULL_ONLY_OPT_IN_DISABLED_BY_DEFAULT`
- Default provider: `DETERMINISTIC_FAKE`
- Live paid API calls: `NOT_AUTHORIZED`
- T-12 and later: `NOT_AUTHORIZED`

## Required governance reads

已完整讀取：`AGENTS.md`、`handoff.md`、`agent_tasks.md`、`README.md`、
`docs/ARCHITECTURE.md`、`docs/ACCEPTANCE_CRITERIA.md`、
`docs/decisions/ADR-004-provider-boundary.md`、
`docs/decisions/ADR-005-progressive-results.md`、
`docs/decisions/ADR-006-concurrency-and-cancellation.md` 與
`docs/quality/T-03_FINDINGS.md`。

## Command records

### Git baseline

```text
Task: T-11 preflight
Command: git status --short --branch && git fetch origin --prune && git rev-parse origin/main && git rev-parse HEAD && git branch --show-current && git merge-base HEAD origin/main
Working directory: D:\GitHub\LingoLens
Exit code: 0
Result: PASS
Relevant stdout:
## feat/t10-progressive-results...origin/main
2d0dfb3e47f27ff5f27c97da151a72876a6ee78a
96dd1da9b5bee6d80bb928c8553fe6a1a1a465a2
feat/t10-progressive-results
96dd1da9b5bee6d80bb928c8553fe6a1a1a465a2
Relevant stderr:
From https://github.com/OPluke11-abula/LingoLens
   af97297..2d0dfb3  main -> origin/main
Limitations: 初始檢查先確認遠端 base；其後從 required base 建立 T-11 branch。
```

### T-11 branch verification

```text
Task: T-11 branch setup
Command: git switch -c feat/t11-openai-provider-observability origin/main && git status --short --branch && git rev-parse HEAD && git merge-base HEAD origin/main
Working directory: D:\GitHub\LingoLens
Exit code: 0
Result: PASS
Relevant stdout:
branch 'feat/t11-openai-provider-observability' set up to track 'origin/main'.
## feat/t11-openai-provider-observability...origin/main
2d0dfb3e47f27ff5f27c97da151a72876a6ee78a
2d0dfb3e47f27ff5f27c97da151a72876a6ee78a
Relevant stderr: Switched to a new branch 'feat/t11-openai-provider-observability'
```

### Toolchain and application root

```text
Task: T-11 preflight
Command: flutter --version && dart --version && git --version; find . -name pubspec.yaml -not -path './.dart_tool/*' -not -path './build/*' -print
Working directory: D:\GitHub\LingoLens
Exit code: 0
Result: PASS
Relevant stdout:
Flutter 3.41.5 • channel stable
Tools • Dart 3.11.3 • DevTools 2.54.2
Dart SDK version: 3.11.3 (stable) on windows_x64
git version 2.53.0.windows.1
./pubspec.yaml
Limitations: Windows host；macOS verification 另行標記為 NOT_RUN。
```

### Archive integrity

```text
Task: T-11 preflight
Command: sha256sum docs/archive/handoffs/project-handoff-v1.1-43f77552.md
Working directory: D:\GitHub\LingoLens
Exit code: 0
Result: PASS
Relevant stdout:
43f77552800dfbc68b983da603b3b5483217e7c8bea2ba04fdce03fee1135279 *docs/archive/handoffs/project-handoff-v1.1-43f77552.md
```

Archived Handoff 維持 historical background only、normally read-only，不代表目前
task status，且不得覆寫 Root `handoff.md`。本檔案未修改 Archive bytes。
