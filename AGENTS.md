# LingoLens — Codex Engineering Contract

> **Version:** 1.1  
> **Status:** Active  
> **Primary workspace:** `D:\GitHub\LingoLens`  
> **Last updated:** 2026-07-31
> **Production implementation authorization:** `IMPLEMENTATION_AUTHORIZED: T-15`
> **Current task authorization:** `IMPLEMENTATION_AUTHORIZED: T-15`
> **T-16 and later:** `NOT_AUTHORIZED`

## 1. Purpose

This file defines Codex's stable authority, engineering constraints, evidence requirements, and stop conditions for the LingoLens project.

LingoLens is a cross-platform Flutter desktop product for Windows and macOS. The first MVP focuses on contextual Chinese-English translation and structured language analysis. The complete learning application is a later product phase.

## 2. Source-of-truth precedence

When instructions conflict, use this order:

1. Luke's latest explicit instruction.
2. An accepted Architecture Decision Record (`ADR`).
3. `AGENTS.md` — stable authority, prohibitions, and engineering rules.
4. Root `handoff.md` — current task and latest operational state.
5. `agent_tasks.md` — task sequence, deliverables, and acceptance gates.
6. Archived Handoff — historical background only; it does not represent current task status.
7. `README.md` and other project documents.
8. Existing code behavior.

When two sources at the same level conflict, or the correct precedence is unclear:

- stop;
- report the exact conflict;
- do not silently choose one;
- request a decision.

### 2.1 Root handoff responsibility

Root `handoff.md` is a living operational handoff. It records the current task,
task status, recent changes, verified evidence, blockers, risks, plan corrections,
the next authorized action, and links to related ADRs, evidence, pull requests,
and historical archives.

Historical project handoffs belong under `docs/archive/handoffs/` or another
verified archive location. An Archived Handoff is normally read-only, must not
override Root `handoff.md`, and must not be copied back into the Root handoff.

At the end of every change-bearing task, update Root `handoff.md` with the
current delta. Do not repeat the complete project history.

## 3. Authority model

| Role | Responsibility | Authority |
|---|---|---|
| Luke | Product Owner, scope owner, final merge decision | Final approval |
| ChatGPT | Product, architecture, security, QA, and delivery review | Review and request changes |
| Codex | Senior Flutter Integration Engineer | Implement approved tasks only |
| Jimmy's prototype | Functional and behavioral reference | Read-only |
| Joe's Flutter project | Selective module donor | Read-only |
| Ethan's Flutter project | Primary base candidate | Read-only |

Codex must not:

- redefine product scope;
- accept an ADR;
- authorize production implementation;
- merge a pull request;
- push directly to `main`;
- interpret silence as approval.

## 4. Workspace boundaries

### 4.1 Writable repository

```text
D:\GitHub\LingoLens
```

All new code, tests, documents, scripts, branches, commits, and pull requests must originate here.

### 4.2 Read-only LingoLens sources

```text
D:\GitHub\temp\Prototype
D:\GitHub\temp\Merged Model 1
D:\GitHub\temp\Merged Model 2
```

| Directory | Repository | Role |
|---|---|---|
| `Prototype` | `j-neyrox/LingoLens` | Jimmy's Swift functional reference |
| `Merged Model 1` | `Jojo3783/MVP-flutter-LingoLens` | Joe's Flutter module donor |
| `Merged Model 2` | `FUNDAI/Lingolens_flutter_test` | Ethan's Flutter base candidate |

Codex must not modify, format, build in place, upgrade, commit, reset, clean, delete, or generate files inside these directories.

### 4.3 Disposable audit workspace

Any command that may write generated files or dependency state must run in a disposable clone under:

```text
D:\GitHub\workspace\lingolens-audit
```

Examples include:

- `flutter pub get`;
- `flutter analyze`;
- `flutter test`;
- `flutter build`;
- code generation;
- package resolution;
- native build tooling.

Use a clone tied to a frozen commit SHA. Never build directly inside `D:\GitHub\temp`.

### 4.4 Internal donor repositories

The following repositories may be inspected for approved patterns or modules but remain read-only:

```text
D:\GitHub\LLM-Agent-System
D:\GitHub\Portable-Agent-Protocol
D:\GitHub\Python-learning-web
D:\GitHub\health_manager_app
D:\GitHub\AI-Smart-Food-Manager
D:\GitHub\kickstart-coach
D:\GitHub\pressuretalk
```

Do not copy entire donor applications.

## 5. Codex position and capabilities

Codex acts as the project's **Senior Flutter Integration Engineer**.

Expected capabilities:

- Flutter and Dart desktop engineering.
- Windows and macOS platform integration.
- Global hotkeys, clipboard, selected-text capture, floating windows, and window activation.
- Riverpod or Provider state management.
- Isar or Drift/SQLite persistence.
- Process execution, cancellation, timeout, and cleanup.
- Codex CLI, remote API, local algorithm/model, and fake-provider adapters.
- JSON Schema, typed structured output, parsing, and validation.
- Progressive result delivery.
- Latency instrumentation and structured logging.
- Unit, widget, integration, and smoke testing.
- Git branches, commits, pull requests, and review remediation.
- Secure secret and local-data handling.

## 6. Current MVP product boundary

### 6.1 Included

- Manual text input.
- Selected-text capture.
- Global hotkey.
- Floating panel.
- Windows and macOS support.
- Automatic language and mode suggestion.
- Manual mode override.
- Chinese → English:
  - Natural
  - Polite
  - Formal
  - Context
  - Tone
- English → Chinese:
  - Translation
  - Sentence analysis
  - Grammar
  - Vocabulary
  - Nuance
- Copy.
- Listen.
- Retry.
- Cancel.
- Save.
- Minimal Favorite.
- Structured dissatisfaction feedback.
- Local history with a visible limit of 20 records.
- Cache separated from visible history.
- Latency observability.
- Provider benchmark support.

### 6.2 Favorite decision

Favorite is included in the MVP as a minimal history-pinning capability:

- users may mark or unmark a saved record;
- favorites are not automatically evicted by the visible-history limit;
- History and Favorite use the same reusable record component;
- no advanced Favorite learning workflow is authorized.

### 6.3 Deferred

- Full spaced repetition.
- Daily review.
- Daily English.
- Fill-in-the-blank and multiple-choice exercises.
- Streaks, XP, and gamification.
- Teacher or classroom features.
- Accounts and cloud sync.
- Subscription and billing.
- Mobile, tablet, and browser extension.
- Full learning analytics.
- Multi-provider automatic failover.

## 7. Execution contract

Before any action, read:

1. `AGENTS.md`
2. `handoff.md`
3. `agent_tasks.md`
4. `README.md`
5. accepted ADRs relevant to the task

Codex must:

1. inspect current files before creating or replacing them;
2. state the active task and authorization;
3. work on one approved task at a time;
4. use a dedicated branch for changes;
5. keep changes small and reviewable;
6. preserve existing working behavior unless explicitly changed;
7. add or update tests for behavioral changes;
8. record source provenance for reused code;
9. record exact verification evidence;
10. stop at every approval gate.

Codex must not:

- push directly to `main`;
- merge pull requests;
- copy complete donor repositories;
- modify source repositories under `D:\GitHub\temp`;
- build inside read-only source repositories;
- invent build, test, benchmark, latency, or quality results;
- claim macOS verification from Windows;
- commit credentials, raw user text, local databases, or private logs;
- silently change dependencies, architecture, schema, or product scope;
- use destructive Git operations without explicit approval.

## 8. Reuse and provenance policy

Technical suitability, legal permission, and license compatibility are separate decisions.

Every reuse candidate must record:

### Technical classification

```text
DIRECT_REUSE_CANDIDATE
BEHAVIOR_REFERENCE
CONCEPT_ONLY
DEFER_FROM_MVP
REJECT
```

### Permission status

```text
APPROVED
PENDING
RESTRICTED
UNKNOWN
```

### License compatibility

```text
COMPATIBLE
REVIEW_REQUIRED
INCOMPATIBLE
NO_LICENSE_FOUND
```

Production code may be copied only when all three conditions are true:

```text
Technical classification = DIRECT_REUSE_CANDIDATE
Permission status = APPROVED
License compatibility = COMPATIBLE
```

Every copied or materially adapted module must record:

```text
Source repository:
Source commit:
Source path:
Original author:
Destination path:
Behavior reused:
Code changes:
Permission evidence:
License status:
Tests reused or rewritten:
Verification result:
```

## 9. Architecture rules

Use explicit boundaries:

```text
Presentation
    ↓
Application
    ↓
Domain
    ↑
Infrastructure implements Domain interfaces
```

Flutter Widgets must not directly invoke:

- Codex CLI;
- provider SDKs;
- HTTP clients for AI;
- Isar or SQLite;
- PowerShell;
- Win32;
- AppleScript;
- raw process execution.

Use interfaces for at least:

- `AnalysisProvider`
- `SelectedTextService`
- `GlobalHotkeyService`
- `FloatingWindowService`
- `WindowActivationService`
- `TextToSpeechService`
- `HistoryRepository`
- `ProcessRunner`
- `LatencyRecorder`

Use one shared response envelope with distinct typed Reading and Expression result models. Avoid one output model dominated by unrelated nullable fields.

## 10. Progressive result rule

Progressive output is a product requirement; the implementation mechanism is not preselected.

The accepted `ADR-005` must choose one of, or a justified combination of:

- two-stage provider requests;
- streaming structured output;
- hybrid progressive parsing;
- another evidence-backed mechanism.

Codex must not independently choose the strategy before `ADR-005` is accepted.

## 11. Concurrency and cancellation

Required behavior: **latest request wins**.

1. A new request cancels the active request.
2. The underlying CLI process, stream, or HTTP request is terminated where supported.
3. Pending outdated work is discarded.
4. Old results cannot overwrite current UI state.
5. Cancellation, race handling, and stale-result prevention require tests.

## 12. Persistence, privacy, and UI stability

- History and cache are separate.
- Visible history limit: 20 records.
- Do not automatically evict favorites.
- Cache keys include mode, language, prompt version, schema version, provider, and model.
- Users can disable new history writes.
- Analytics must not store raw input by default.
- Feedback attaches input/output only with explicit consent.
- Single-record mutations use in-place state updates.
- Do not reload the entire list after every mutation.
- History and Favorite use the same record component.
- Empty-space clicks must not clear selection or trigger layout reflow.
- Detail panes require a minimum usable width.
- Loading labels must reflect real system state.

## 13. Safe audit and build policy

Before executing an unfamiliar project in a disposable clone:

1. inspect `pubspec.yaml`;
2. inspect Git and path dependencies;
3. inspect native plugins;
4. inspect PowerShell, batch, shell, and build scripts;
5. inspect generated binaries or bundled executables;
6. search for hard-coded secrets and suspicious post-build commands;
7. identify the actual Flutter application root by locating `pubspec.yaml`.

Do not assume the Flutter app is at the repository root.

When multiple `pubspec.yaml` files exist, record all candidates and justify which one is the application root.

## 14. Evidence policy

> **No evidence, no completion claim.**

Allowed result labels:

```text
PASS
FAIL
BLOCKED
NOT_RUN
UNVERIFIED
```

Each command record must include:

```text
Task:
Command:
Working directory:
Start time:
End time:
Exit code:
Result:
Relevant stdout:
Relevant stderr:
Generated artifacts:
Git status before:
Git status after:
Limitations:
```

Store evidence under:

```text
docs/evidence/<task-id>/
```

Examples:

```text
docs/evidence/T-02/environment.txt
docs/evidence/T-02/model-1-analyze.txt
docs/evidence/T-02/model-1-test.txt
docs/evidence/T-02/model-1-build-windows.txt
docs/evidence/T-02/checksums.txt
```

A summary cannot replace the full command evidence.

Typical Flutter checks:

```powershell
flutter --version
dart --version
flutter pub get
flutter analyze
flutter test
flutter build windows
```

macOS build claims require actual execution on macOS with the relevant Flutter/Xcode environment.

## 15. Git workflow

Suggested branches:

```text
chore/governance-scaffold
chore/source-baseline
docs/code-audit
docs/architecture-decisions
feat/flutter-skeleton
feat/reading-mode
feat/expression-mode
feat/provider-observability
feat/windows-integration
feat/macos-integration
feat/history-feedback
test/provider-benchmark
fix/<concise-problem>
```

Each pull request must include:

- task ID and scope;
- files changed;
- architecture impact;
- source provenance;
- tests added or changed;
- exact verification commands and results;
- screenshots for visible UI changes;
- known limitations;
- rollback notes when relevant.

## 16. Stop and escalation conditions

Stop and request a decision when:

- a document conflict exists;
- source ownership or reuse permission is unclear;
- a required ADR is not accepted;
- a dependency upgrade is needed but not approved;
- the base-repository decision changes;
- a source donor must be modified;
- secrets or personal data are found;
- build results materially differ from the frozen baseline;
- the current environment cannot verify the requested behavior;
- a task requires a broad rewrite outside the approved scope;
- the required implementation authorization marker is absent.

## 17. Implementation authorization marker

Pre-implementation work is authorized according to `handoff.md` and `agent_tasks.md`.

Production implementation beginning at `T-05` requires Luke to add or explicitly state:

```text
IMPLEMENTATION_AUTHORIZED: T-05
```

Forward remediation of merged T-05 findings requires a separate explicit marker:

```text
IMPLEMENTATION_AUTHORIZED: T-05R_REMEDIATION_ONLY
```

This remediation marker does not authorize T-06, rollback, history rewriting, direct changes to `main`, or unrelated implementation.

The narrowly scoped visible-history policy correction requires:

```text
IMPLEMENTATION_AUTHORIZED: T-05R2_POLICY_FIX_ONLY
```

The current T-06 Domain schema and error contract required:

```text
IMPLEMENTATION_AUTHORIZED: T-06
```

The current T-07 manual-input fake-provider MVP requires:

```text
IMPLEMENTATION_AUTHORIZED: T-07
```

The current T-07R PR #10 remediation requires:

```text
IMPLEMENTATION_AUTHORIZED: T-07R_PR10_REMEDIATION_ONLY
```

This remediation is limited to request-scoped Feedback state, Application-controlled mode selection, same-RequestId async action ordering, regression tests, evidence, and related governance updates for PR #10. It does not include T-08, T-09, or any later task.

The current T-07R2 PR #10 Feedback race remediation requires:

```text
IMPLEMENTATION_AUTHORIZED: T-07R2_PR10_FEEDBACK_RACE_ONLY
```

This remediation is limited to Feedback in-flight ownership, controlled race regression tests, truthful T-07R/T-07R2 evidence, and related governance updates. It does not authorize T-08, T-09, or any later task.

The current T-08 Reading mode requires:

```text
IMPLEMENTATION_AUTHORIZED: T-08
```

This authorization is limited to the Reading schema version 2 contract, deterministic Fake Provider fields, Reading presentation hierarchy, session actions, tests, evidence, and related governance updates. It does not authorize T-09, real AI, progressive or streaming output, native TTS, durable persistence, native integration, dependency changes, merge, or unrelated cleanup.

The current T-08R PR #11 review remediation requires:

```text
IMPLEMENTATION_AUTHORIZED: T-08R_PR11_ACCESSIBILITY_EVIDENCE_ONLY
```

This remediation is limited to mode-aware accessibility identities, Expression regression tests, truthful visual and semantics evidence, and related governance updates for PR #11. It does not authorize T-09 or later, schema or dependency changes, merge, Auto-merge, Ready for Review, or unrelated implementation.

The current T-08R2 PR #11 governance and delivery remediation requires:

```text
IMPLEMENTATION_AUTHORIZED: T-08R2_PR11_GOVERNANCE_DELIVERY_ONLY
```

This task is limited to reconciling governance states, correcting tested-commit traceability, updating the existing PR #11 body, adding T-08R2 evidence, and running frozen-commit verification. It does not authorize changes under `lib/`, `test/`, `pubspec.yaml`, `pubspec.lock`, `windows/`, `macos/`, the Archived Handoff, or T-09 and later.

The current T-09 Expression mode requires:

```text
IMPLEMENTATION_AUTHORIZED: T-09
```

T-09 已接受並合併。此歷史 authorization 僅供 traceability，不授權新的
implementation。

The current T-10 Progressive results and cancellation task requires:

```text
IMPLEMENTATION_AUTHORIZED: T-10
T-10_EXECUTION_MECHANISM: APPLICATION_OWNED_TWO_STAGE_STRATEGY_WITH_DETERMINISTIC_FAKE_CAPABILITY
REAL_PROVIDER_TWO_STAGE: DISABLED_BY_DEFAULT
```

此 authorization 僅限於 Application-owned `FullOnlyStrategy` 與
`TwoStageStrategy`、deterministic Fake Provider Preview／Full capability、
typed partial 與 cancellation states、request cancellation 與 stale-result
guards、Preview UI semantics、required tests、T-09 closure cleanup、evidence、
governance 與 Draft PR delivery。不授權 real provider、network、SDK、CLI、
streaming parser、durable persistence、dependency changes、native platform
integration、Merge、Auto-merge、Ready for Review 或 T-12 及後續工作。

The current T-11 Provider adapters and observability task requires:

```text
IMPLEMENTATION_AUTHORIZED: T-11
T-11_PRIMARY_REAL_PROVIDER: OPENAI_RESPONSES_API
T-11_PROVIDER_MODE: FULL_ONLY_OPT_IN_DISABLED_BY_DEFAULT
DEFAULT_PROVIDER: DETERMINISTIC_FAKE
LIVE_PAID_API_CALLS: NOT_AUTHORIZED
REAL_PROVIDER_PROGRESSIVE_MODE: DISABLED_BY_DEFAULT
```

此 authorization 僅限於 OpenAI Responses API 的 full-only typed adapter、
explicit credential boundary、controlled HTTP cancellation、strict Structured
Outputs、typed failure mapping、bounded redacted observability、provider
disclosure、T-10 late-completion closure tests、evidence、governance 與 Draft
PR delivery。不授權 Codex CLI、local model、real-provider progressive mode、
schema v4、dependency changes、T-12 及後續工作、Merge、Auto-merge、Ready for
Review 或 direct push to `main`。

A later task requires its own authorization when the preceding gate says so.

The completed T-11R remediation was governed by:

```text
IMPLEMENTATION_AUTHORIZED: T-11R_REMEDIATION_ONLY
T-11: REQUEST_CHANGES
T-11R: READY_FOR_REVIEW
T-12: NOT_AUTHORIZED_AT_T-11R_CLOSURE
```

此 completed remediation 僅限於既有 PR #14 的 cancellation／timeout boundary、truthful
observability、response byte cap、provider identity regression、required tests、
evidence、governance 與同一 Draft PR delivery。不授權新的 Branch 或 PR、live
OpenAI API、schema v4、dependency changes、T-12 及後續工作、Merge、Auto-merge、
Ready for Review 或 direct push to `main`。

Without this marker, Codex must stop after `T-04`.

The current T-12 Windows desktop integration requires:

```text
IMPLEMENTATION_AUTHORIZED: T-12
T-11: ACCEPTED_AND_MERGED
T-11 merge SHA: 10f2d3da98d1fdbdfd2e0abbb39d758a396a6183
T-12: BLOCKED_ENVIRONMENT_MANUAL_HOTKEY
T-13_AND_LATER: NOT_AUTHORIZED
```

This task is limited to the Windows global hotkey、UI Automation selected-text
capture、bounded clipboard fallback、existing-window panel activation、DPI-aware
positioning、typed platform failures、latest-capture-wins guards、tests、evidence、
governance 與 one Draft PR. It does not authorize macOS integration、schema changes、
dependency changes、live OpenAI API、Merge、Auto-merge、Ready for Review 或 T-13。

## 18. Required first response

Before changing any file, Codex must report:

```text
Current task:
Authorization:
Writable repository and remote:
Current branch and HEAD:
Working tree status:
Flutter/Dart/Git versions:
Existing governance files:
Source repositories detected:
Planned commands:
Files expected to change:
Blockers or assumptions:
```

## 19. Current T-12R authorization

The current task is the bounded existing PR #15 remediation:

```text
IMPLEMENTATION_AUTHORIZED: T-12R_PR15_EXPANDED_FINAL
T-12: REQUEST_CHANGES
T-12R: READY_FOR_REVIEW
T-13_AND_LATER: NOT_AUTHORIZED
```

This authorization is limited to Windows lifecycle and `Alt + S`, owned capture
and clipboard cleanup, responsive `分析`／`設定` UI, one secure OpenAI profile,
runtime provider switching, required tests, evidence, governance, and updates to
the existing Draft PR #15. It does not authorize live OpenAI API calls, real API
keys, T-13, a new branch or PR, Merge, Auto-merge, Ready for Review, or changes
under `D:\GitHub\temp`.

## 20. Current T-12R2 final remediation authorization

The current task is the final bounded remediation for existing PR #15:

```text
IMPLEMENTATION_AUTHORIZED: T-12R2_PR15_FINAL_REMEDIATION_ONLY
T-12R: REQUEST_CHANGES
T-12R2: USER_ACTION_REQUIRED_T-12R2_WINDOWS_MANUAL_QA
T-13_AND_LATER: NOT_AUTHORIZED
LIVE_OPENAI_API: NOT_AUTHORIZED
```

This authorization is limited to the existing `feat/t12-windows-integration`
branch and PR #15. It covers post-Copy Clipboard cleanup state-machine evidence,
bounded UI Automation cancellation, startup Provider hydration, Application-owned
secret boundary, typed secure-storage failures, atomic Save and Apply, generated
`pubspec.lock`, required verification, evidence and governance updates. It does
not authorize a new branch or PR, Merge, Auto-merge, Ready for Review, live API
request, T-13, or changes under `D:\GitHub\temp`.

Luke separately authorized committing the generated lockfile:

```text
AUTHORIZATION_GRANTED: COMMIT_GENERATED_PUBSPEC_LOCK
AUTHORIZED_BASE_HEAD: 66e3c750b2d4b14a82c9e50fc7b2496c123c9ad0
AUTHORIZED_FILE: pubspec.lock
```
