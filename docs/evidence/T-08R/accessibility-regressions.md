# T-08R Accessibility Regression Evidence

Task: T-08R
Working directory: `D:\GitHub\workspace\lingolens-audit-t08r`

Command:

```text
flutter test test/widget_reading_mode_test.dart test/widget_test.dart
```

Exit code: `0`
Result: PASS; `16 tests passed`.

The focused suite verifies the following review boundaries:

- Reading has `reading-quick-actions` and `reading-session-actions` exactly once.
- Expression has `expression-quick-actions` and `expression-session-actions` exactly once.
- The opposite mode's action identities and labels are absent.
- Reading Copy／Listen uses `Translation`.
- Expression Copy／Listen uses `Natural`.
- Reading and Expression result bodies expose one explicit section semantics label.
- Switching from Reading to Expression does not leave stale Reading keys or labels.
- Existing Reading hierarchy, selection surface, long output, narrow viewport, session actions, and Expression regressions remain passing.

LSP diagnostics for the four changed source/test files: no diagnostics found.

No raw runtime semantics dump is claimed. A deterministic contract artifact derived from these assertions is stored at `docs/evidence/T-08R/semantics-tree.txt`.
