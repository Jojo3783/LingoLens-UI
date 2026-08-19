# F-001 舊版規格移除驗證

Task: 移除已被 F-001 個人學習記憶正式規格取代的舊版手動儲存／Favorite 規格，並修正引用。

Command:

```text
test ! -e docs/features/F-001-manual-save-and-favorite.md
rg -n -F 'F-001-manual-save-and-favorite.md' . -g '!**/.git/**' -g '!docs/evidence/**'
git diff --check
```

Working directory: `/Users/jimmy_only/Documents/LingoLens`

Start time: `2026-08-15T16:16:05+0800`

End time: `2026-08-15T16:16:05+0800`

Exit code: `0`

Result: `PASS`

Relevant stdout:

- `docs/features/F-001-manual-save-and-favorite.md` no longer exists.
- The removed path has no remaining reference under `docs/features/`.
- `handoff.md` retains an explicit historical note that the old draft was replaced and removed.
- `git diff --check` and the targeted trailing-whitespace check produced no errors.

Relevant stderr: none.

Generated artifacts: this evidence record.

Git status before: target file was staged as deleted; documentation references remained.

Git status after: target staged as deleted; documentation changes and new feature specifications remain unstaged or untracked for the user to review and commit.

Limitations: documentation-only change; no Flutter build, analyze, or test is required.
