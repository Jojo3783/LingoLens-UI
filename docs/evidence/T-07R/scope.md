# T-07R Scope and Governance Evidence

## Authorized scope

- Feedback reason、comment、consent、RequestId boundary 與 submission guard。
- Application-owned effective mode Dropdown 與 `Use suggestion` synchronization。
- Same-RequestId async action generation guard。
- Regression tests、evidence 與 T-07R governance updates。

## Explicitly excluded

- `pubspec.yaml`、dependency upgrade、real provider、progressive／streaming result、durable persistence、native TTS。
- T-08、T-09 及後續 task。
- Merge、auto-merge、Ready for Review、force push、rebase、reset、cherry-pick、新 Branch、新 PR。
- `docs/archive/handoffs/project-handoff-v1.1-43f77552.md`。

## Governance assertions

- Root `handoff.md` 是 Living Operational Handoff，未重新放入 Archived Handoff 的完整歷史背景。
- Archived Handoff 清楚標示 historical background only、通常唯讀、不代表目前 task status，且不得覆寫 Root `handoff.md`。
- `AGENTS.md` 與 `agent_tasks.md` 均保留 T-08 及後續 `NOT_AUTHORIZED`。
