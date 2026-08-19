# LingoLens — Codex Task Flow

> **Version:** 1.1  
> **Status:** Active implementation execution plan
> **Primary repository:** `D:\GitHub\LingoLens`  
> **Production implementation authorization:** `IMPLEMENTATION_AUTHORIZED: T-12`
> **Current task authorization:** `IMPLEMENTATION_AUTHORIZED: T-12`
> **T-13 and later:** `NOT_AUTHORIZED`

## 1. Task-state model

Every task uses one state:

```text
NOT_STARTED
IN_PROGRESS
BLOCKED
READY_FOR_REVIEW
ACCEPTED
REJECTED
SUPERSEDED
```

Codex may mark a task `READY_FOR_REVIEW`. Only the designated approver may mark gated work `ACCEPTED`.

## 2. Standard procedure

For every task:

1. Read `AGENTS.md`, `handoff.md`, and this file.
2. Confirm source-of-truth precedence and authorization.
3. Inspect Git status, branch, remote, and relevant files.
4. Restate the task scope.
5. Identify blockers and missing decisions.
6. Create or switch to the approved branch when changes are authorized.
7. Make the smallest viable change.
8. Add or update tests when behavior changes.
9. Run required verification.
10. Save full evidence under `docs/evidence/<task-id>/`.
11. Commit with a scoped message.
12. Prepare review notes.
13. Stop at the task gate.

### 2.1 Living handoff rule

Root `handoff.md` is the living operational handoff and the current task-status
source. Every change-bearing task must update it before completion. `T-00` is
read-only and may report its state in the conversation without changing the
Root handoff. Historical Handoffs are archived and are not task-status sources.

## 3. Standard evidence template

For each executed command, record:

```text
Task:
Command:
Working directory:
Start time:
End time:
Exit code:
Result: PASS | FAIL | BLOCKED | NOT_RUN | UNVERIFIED
Relevant stdout:
Relevant stderr:
Generated artifacts:
Git status before:
Git status after:
Limitations:
```

## 4. Authorized task sequence

```text
T-00 Workspace preflight
T-01 Governance scaffold
T-02 Disposable source baseline
T-03 Code-level capability audit
T-04 Proposed architecture decisions
STOP_FOR_TEAM_REVIEW
```

`T-05` and later are blocked until Luke provides:

```text
IMPLEMENTATION_AUTHORIZED: T-05
```

---

# T-00 — Workspace preflight

**State:** `ACCEPTED`
**Change authorization:** Read-only

## Objective

Verify the exact Git, repository, governance-file, and toolchain state of:

```text
D:\GitHub\LingoLens
```

## Commands

```powershell
Set-Location "D:\GitHub\LingoLens"

git rev-parse --is-inside-work-tree
git remote -v
git branch --show-current
git rev-parse HEAD
git status --short
git log -1 --oneline
flutter --version
dart --version
git --version
```

Read without editing:

```text
README.md
.gitignore
AGENTS.md
agent_tasks.md
handoff.md
```

## Deliverable

A preflight response containing:

- exact remote repository;
- current branch;
- current HEAD;
- working-tree state;
- Flutter, Dart, and Git versions;
- governance files present or missing;
- authorization understood;
- blockers.

## Gate

Stop if:

- the repository is not the intended LingoLens remote;
- the working tree contains unexplained changes;
- the governance documents conflict;
- the current branch or HEAD cannot be identified.

No files may be changed during T-00.

---

# T-01 — Governance scaffold

**State:** `ACCEPTED`
**Suggested branch:** `chore/governance-scaffold`

## Objective

Create the minimum repository structure required for controlled baseline, audit, architecture, evidence, and later implementation.

## Required files and directories

```text
README.md
.gitignore
AGENTS.md
agent_tasks.md
handoff.md
CONTRIBUTING.md
docs/
  PRODUCT_SCOPE.md
  ARCHITECTURE.md
  ACCEPTANCE_CRITERIA.md
  integration/
  decisions/
  evidence/
  quality/
  privacy/
  reuse/
.github/
  pull_request_template.md
```

## Rules

- Read and preserve useful existing README and `.gitignore` content.
- Create the initial living Root `handoff.md` during `T-01`.
- Do not add Flutter production code.
- Do not import any source repository.
- Do not add a public license while permissions remain unresolved.
- Ignore credentials, databases, logs, build output, benchmark output, audit clones, and donor directories.
- Add a clear repository status: planning and controlled integration.
- Record source-of-truth precedence in governance documentation.

## Minimum `.gitignore` additions

Ensure the repository ignores, where applicable:

```text
.env
.env.*
!.env.example
*.key
*.pem
*.isar
*.isar.lock
*.sqlite
*.sqlite3
*.db
logs/
telemetry/
benchmark-results/local/
tmp/
temp/
analysis-output/
codex-output/
references/
donors/
```

Do not ignore normal tracked source or test directories.

## Verification

```powershell
git diff --check
git status --short
```

## Deliverable

A reviewable governance commit and summary.

## Gate

Stop for review if existing governance files materially conflict with v1.1.

---

# T-02 — Disposable source baseline

**State:** `ACCEPTED`
**Suggested branch:** `chore/source-baseline`

## Objective

Freeze immutable Git metadata and produce truthful build/test baselines without modifying the original source repositories.

## Original read-only sources

```text
D:\GitHub\temp\Prototype
D:\GitHub\temp\Merged Model 1
D:\GitHub\temp\Merged Model 2
```

## Disposable workspace

```text
D:\GitHub\workspace\lingolens-audit
```

## Step 1 — Record original source state

For each source:

```powershell
git -C "<source>" rev-parse --is-inside-work-tree
git -C "<source>" remote -v
git -C "<source>" branch --show-current
git -C "<source>" rev-parse HEAD
git -C "<source>" status --short
git -C "<source>" log -1 --oneline
```

A dirty source is `BLOCKED` unless Luke explicitly authorizes auditing the committed HEAD while ignoring local changes.

## Step 2 — Create disposable clones

Use a unique destination containing the source name and short SHA.

Example:

```powershell
git clone --local --no-hardlinks `
  "D:\GitHub\temp\Merged Model 1" `
  "D:\GitHub\workspace\lingolens-audit\Merged-Model-1-<short-sha>"

git -C "D:\GitHub\workspace\lingolens-audit\Merged-Model-1-<short-sha>" `
  checkout --detach <full-sha>
```

Do not use hard-linked working objects for audit isolation.

## Step 3 — Static safety inspection

Before package resolution or build, inspect:

- `pubspec.yaml`;
- Git/path dependencies;
- native plugins;
- PowerShell, batch, shell, and build scripts;
- bundled executables;
- environment-variable use;
- hard-coded secrets;
- post-build hooks.

Record findings. Stop if suspicious or unsafe behavior is found.

## Step 4 — Detect Flutter application roots

Do not assume repository root.

Search for candidate Flutter apps:

```powershell
Get-ChildItem -Path "<audit-clone>" -Filter pubspec.yaml -Recurse |
  Where-Object {
    $_.FullName -notmatch '\\.dart_tool\\|\\build\\'
  }
```

For every candidate record:

```text
Repository root:
Flutter application root:
pubspec.yaml:
pubspec.lock:
windows/ present:
macos/ present:
Selection reason:
```

If multiple application roots are plausible, stop and request a decision.

## Step 5 — Execute Flutter baseline in audit clones only

From each selected Flutter app root:

```powershell
flutter --version
dart --version
flutter pub get
flutter analyze
flutter test
flutter build windows
```

Record before/after Git status inside the disposable clone.

Do not claim a macOS build from Windows. The Swift prototype and macOS Flutter target remain `NOT_RUN` or `UNVERIFIED` until executed on macOS.

## Step 6 — Recheck originals

After all audit commands:

```powershell
git -C "<original-source>" status --short
```

The result must match the pre-audit state exactly.

## Deliverables

```text
docs/integration/SOURCE_BASELINES.md
docs/integration/BUILD_AND_TEST_REPORT.md
docs/evidence/T-02/
```

## Gate

Stop if:

- a source cannot be tied to a commit SHA;
- the original source changes;
- the app root is ambiguous;
- dependency or build behavior is unsafe;
- evidence is incomplete.

---

# T-03 — Code-level capability audit

**State:** `ACCEPTED`
**Suggested branch:** `docs/code-audit`

## Objective

Identify reusable behavior, modules, dependencies, tests, and platform capabilities across the three LingoLens sources.

## Required audit areas

- application bootstrap;
- domain models;
- query coordinator;
- query state;
- prompt construction;
- AI provider;
- process runner;
- JSON schema and parsing;
- selected-text capture;
- global hotkey;
- floating window;
- window activation;
- TTS;
- persistence;
- cache;
- history;
- minimal Favorite;
- review code, for future reference only;
- error handling;
- tests;
- platform-specific code.

## Required classification

For every candidate, record all three dimensions.

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

Do not label a module “approved for copy” unless all three production-copy conditions are satisfied.

## Tone rule

Describe strengths, capability, fit, and migration implications. Do not perform personal criticism of individual contributors.

## Deliverables

```text
docs/integration/FUNCTIONAL_MATRIX.md
docs/integration/MIGRATION_MATRIX.md
docs/reuse/DONOR_REPOSITORY_MATRIX.md
docs/reuse/MODULE_PROVENANCE.md
docs/reuse/LICENSE_BOUNDARIES.md
docs/evidence/T-03/
```

## Gate

No production code may be copied during T-03.

---

# T-04 — Proposed architecture decisions

**State:** `ACCEPTED`
**Suggested branch:** `docs/architecture-decisions`

## Objective

Produce evidence-backed ADR proposals required before application implementation.

## Required ADRs

```text
docs/decisions/ADR-001-base-repository.md
docs/decisions/ADR-002-state-management.md
docs/decisions/ADR-003-persistence.md
docs/decisions/ADR-004-provider-boundary.md
docs/decisions/ADR-005-progressive-results.md
docs/decisions/ADR-006-concurrency.md
docs/decisions/ADR-007-platform-boundary.md
```

## Decision topics

1. Ethan base import versus clean Flutter skeleton.
2. Provider versus Riverpod.
3. Isar versus Drift/SQLite.
4. CLI/API/local/fake provider boundary.
5. Two-stage requests versus streaming structured output versus hybrid strategy.
6. Latest-request-wins implementation and true cancellation.
7. Windows/macOS platform adapter boundaries.

## Required ADR fields

```text
Title:
Status: PROPOSED
Date:
Owners:
Context:
Evidence:
Decision proposal:
Alternatives:
Consequences:
Migration impact:
Security/privacy impact:
Verification plan:
Open questions:
Approval:
```

Codex may propose but may not set an ADR to `ACCEPTED`.

## Deliverables

- Seven proposed ADRs.
- Decision summary.
- Evidence links.
- Explicit unresolved questions.

## Mandatory gate

After T-04:

```text
STOP_FOR_TEAM_REVIEW
```

Codex must not begin T-05 unless Luke explicitly provides:

```text
IMPLEMENTATION_AUTHORIZED: T-05
```

---

# T-05 — Flutter architecture skeleton

**State:** `ACCEPTED_WITH_NON_BLOCKING_LIMITATIONS_AND_MERGED`

The merged T-05 review findings are being handled only under:

```text
IMPLEMENTATION_AUTHORIZED: T-05R_REMEDIATION_ONLY
```

This does not authorize T-06 or later work.

## T-05R — T-05 review remediation

**State:** `CLOSED_BY_T05R2`

This task covered the merged T-05 review remediation and is closed by the accepted T-05R2 policy correction.

## T-05R2 — Visible history limit policy correction

**State:** `ACCEPTED_AND_MERGED`

This task corrected visible History selection so Favorites receive priority but still count toward the total query limit. It did not authorize durable persistence, UI work, dependency changes, platform integration, or T-06.

## Objective

Create the accepted Flutter desktop project structure without real AI, database, hotkey, selected-text, or floating-window integration.

## Preconditions

- T-00 through T-04 accepted.
- Required ADRs accepted.
- `IMPLEMENTATION_AUTHORIZED: T-05` present.
- Base import or clean-skeleton strategy confirmed.

## Minimum structure

```text
lib/
  app/
  core/
  domain/
  application/
  infrastructure/
  presentation/
test/
```

## Initial contracts

- `AnalysisProvider`
- `AnalysisRequest`
- `AnalysisResult`
- `ReadingAnalysis`
- `ExpressionAnalysis`
- `AnalysisMode`
- `InputLanguage`
- `QueryState`
- `HistoryRepository`
- cancellation abstraction
- `FakeAnalysisProvider`

## First runnable flow

```text
Manual input
→ fake provider
→ typed result
→ visible result UI
```

## Verification

```powershell
flutter pub get
flutter analyze
flutter test
flutter build windows
```

## Gate

No real provider, persistence, hotkey, selected-text, or floating-window integration.

---

# T-06 — Domain schemas and error contract

**State:** `ACCEPTED_AND_MERGED`

**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-06`

Implement:

- shared response envelope;
- distinct Reading and Expression result types;
- JSON serialization/deserialization;
- 2,000-character input boundary;
- explicit application errors.

Minimum error codes:

```text
EMPTY_INPUT
INPUT_TOO_LONG
SELECTION_UNAVAILABLE
ACCESSIBILITY_PERMISSION_REQUIRED
PROVIDER_NOT_FOUND
PROVIDER_TIMEOUT
REQUEST_CANCELLED
INVALID_STRUCTURED_OUTPUT
PERSISTENCE_FAILED
UNKNOWN_ERROR
```

Verification requires schema, invalid-payload, and boundary tests.

## T-06R — T-06 PR #9 review remediation

**State:** `ACCEPTED_AND_MERGED`

**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-06R_PR9_REMEDIATION_ONLY`

This remediation is limited to repository-boundary persistence error mapping, its raw-failure tests, removal of disconnected analysis/persistence assertions, and the corresponding governance and evidence corrections for PR #9. T-07 and later remain unauthorized.

---

# T-07 — Manual-input fake-provider MVP

**State:** `ACCEPTED_AND_MERGED`

**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-07`

T-07 was the prior authorized task. Its historical section does not override the current T-08 authorization recorded above and in the T-08 section below.

Implement deterministic provider-independent behavior:

- manual input;
- Reading/Expression selection;
- automatic mode suggestion interface;
- manual override;
- loading, success, cancellation, and failure states;
- Copy;
- Listen adapter according to accepted scope;
- Retry;
- Save;
- minimal Favorite;
- feedback UI shell.

T-07 is limited to a deterministic full-only Fake Provider, session-only actions, and no real AI, durable storage, or native TTS.

---

# T-07R — PR #10 request-scoped UI and async-action remediation

**State:** `CLOSED_BY_T07R2`

**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-07R_PR10_REMEDIATION_ONLY`

T-07R is limited to the reviewed PR #10 findings:

- request-scoped Feedback reason, comment, consent, submission, and attached content;
- Application-controlled mode Dropdown synchronization with effective mode and `Use suggestion`;
- same-RequestId async action generation guards for Copy, Listen, Save, Favorite, and Feedback;
- focused regression tests, exact verification evidence, and governance updates.

T-07R does not authorize T-08, T-09, or any later task. It does not authorize merge, auto-merge, Ready for Review, dependency changes, or unrelated cleanup.

---

# T-07R2 — PR #10 Feedback in-flight ownership remediation

**State:** `ACCEPTED_AND_MERGED`

**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-07R2_PR10_FEEDBACK_RACE_ONLY`

T-07R2 is limited to ensuring that Feedback persistence has request-scoped operation ownership. A stale Request A completion must not clear Request B in-flight state, action state, or submission state. The task includes controlled success and failure race tests with repository invocation-count assertions and the related evidence and governance corrections.

T-07R2 does not modify repository contracts, dependencies, product scope, or T-08/T-09 behavior. It does not authorize merge, auto-merge, Ready for Review, force push, rebase, or a new Branch or PR.

---

# T-08 — Reading mode

**State:** `ACCEPTED_AND_MERGED`

**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-08`

Information hierarchy:

1. Translation.
2. Copy.
3. Listen.
4. Sentence analysis.
5. Grammar.
6. Vocabulary.
7. Nuance.

Required focus:

- stable layout;
- long-output scrolling;
- reusable result components;
- accessible states;
- no empty-space selection loss.

T-08 uses exact schema version `2` and replaces the prior Reading `note` field with `sentenceAnalysis`, `grammar`, `vocabulary`, and `nuance`. It does not authorize real AI, progressive or streaming output, native TTS, durable persistence, T-09 fields, dependency changes, merge, or Auto-merge.

Team Review found a mode-aware accessibility and Expression regression evidence issue. The T-08 implementation remains otherwise unchanged; this review finding is handled only by T-08R below.

---

# T-08R — PR #11 mode-aware accessibility and evidence remediation

**State:** `CLOSED_BY_T08R2`

**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-08R_PR11_ACCESSIBILITY_EVIDENCE_ONLY`

T-08R is limited to PR #11 remediation:

- make quick-action and session-action accessibility labels and stable keys derive from the typed `AnalysisMode`;
- verify Reading and Expression action identity, output semantics, and mode switching through regression tests;
- record truthful visual and semantics evidence, including the existing screenshot readability limitation;
- update only related governance and evidence documents.

T-08R must preserve schema version `2`, `RequestId` guards, Application ownership, persistence behavior, and existing T-07/T-07R/T-07R2 accepted state. It does not authorize T-09 or later, dependency changes, real AI, native integration, merge, Auto-merge, Ready for Review, or a new Branch or PR.

---

# T-08R2 — PR #11 governance and delivery reconciliation

**State:** `ACCEPTED_AND_MERGED`

**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-08R2_PR11_GOVERNANCE_DELIVERY_ONLY`

T-08R2 is limited to reconciling current governance states, correcting T-08R tested-commit traceability, updating the existing Draft PR #11 body, adding T-08R2 evidence, and running verification from the frozen governance correction commit. It must not modify production code, tests, schemas, dependencies, platform files, or the Archived Handoff. T-09 and later remain `NOT_AUTHORIZED`.

---

# T-09 — Expression mode

**State:** `ACCEPTED_AND_MERGED`

**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-09`

Information hierarchy:

1. Natural.
2. Copy.
3. Listen.
4. Polite.
5. Formal.
6. Context.
7. Tone.

Rules:

- manual mode always wins;
- low-confidence mixed input may request confirmation;
- no mandatory confirmation for every request.
- shared `analysisSchemaVersion` is exactly `3`;
- `ExpressionAnalysis` contains exactly five required non-empty strings in JSON order: `natural`, `polite`, `formal`, `context`, `tone`;
- Expression UI presents Natural, Copy, Listen（Fake）, Polite, Formal, Context, Tone, then Save/Favorite/Feedback;
- Copy, Listen（Fake） and consent-attached Feedback use Expression `natural`;
- existing Application-owned mode snapshot, retry mode, RequestId guard, stale-result rejection, persistence boundary, and Reading regressions remain intact;
- no real AI, network, SDK, progressive or streaming output, durable persistence, native platform integration, dependency changes, or later task work.

Required evidence includes schema/provider tests, Expression widget and action accessibility tests, long/narrow layout tests, visual evidence with truthful screenshot limitations, complete Flutter verification from a disposable clone, and Draft PR metadata.

T-09 may be marked `READY_FOR_REVIEW` only after all required verification passes or is truthfully recorded as an environment limitation.

---

# T-10 — Progressive results and cancellation

**State:** `READY_FOR_REVIEW`

**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-10`

**Execution mechanism:** `APPLICATION_OWNED_TWO_STAGE_STRATEGY_WITH_DETERMINISTIC_FAKE_CAPABILITY`.

T-10 實作 Application-owned `FullOnlyStrategy` 與 optional
`TwoStageStrategy`。deterministic Fake Provider 可提供 Preview 與 Full
capability；沒有 optional capability 的 provider 使用 Full-only。Preview
僅是 typed、mode-bound primary output：Reading 使用 Translation，Expression
使用 Natural。Preview 絕不序列化為 `AnalysisResult`，也不寫入 full History、
Favorite、Feedback 或 Cache。

Required state semantics 包含 Preview loading、partial Preview with Full
pending、Full pending 期間的 non-fatal Preview failure、Full success、保留
partial Preview 的 typed Full failure、cancellation 與 stale-result rejection。
Retry 建立新的 RequestId；Dispose 阻止 post-dispose state。

T-10 不授權 real provider、network、SDK、CLI、streaming parser、durable
persistence、dependency changes、native platform integration、Merge、
Auto-merge、Ready for Review、T-12 或後續工作。

## Objective

依 accepted `ADR-005`，使用已授權的 Application-owned two-stage strategy 與
deterministic Fake capability 實作 progressive results。Real-provider
two-stage、streaming structured output 與 hybrid parsing 維持停用且未授權。

## Behavioral requirements

- fast and full-result states are distinguishable;
- new requests cancel active work;
- stale work cannot overwrite current state;
- partial success is represented truthfully;
- cancellation propagates where supported.

## T-10 verification boundary

- focused strategy, cancellation, stale-result, retry, dispose, and Preview UI tests;
- full Flutter verification from a disposable clone tied to the reviewed commit;
- Windows build may be `BLOCKED_ENVIRONMENT` when CMake／Visual Studio is absent;
- macOS verification is `NOT_RUN` on Windows;
- Draft PR delivery stops before merge and awaits Team Review.

## Verification

- cancellation tests;
- race-condition tests;
- stale-result rejection tests;
- partial-success tests.

---

# T-11 — Provider adapters and observability

**State:** `REQUEST_CHANGES`

**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-11`

```text
T-11_PRIMARY_REAL_PROVIDER: OPENAI_RESPONSES_API
T-11_PROVIDER_MODE: FULL_ONLY_OPT_IN_DISABLED_BY_DEFAULT
DEFAULT_PROVIDER: DETERMINISTIC_FAKE
LIVE_PAID_API_CALLS: NOT_AUTHORIZED
CODEX_CLI_PROVIDER: DEFERRED
LOCAL_MODEL_PROVIDER: DEFERRED
REAL_PROVIDER_PROGRESSIVE_MODE: DISABLED_BY_DEFAULT
T-12_AND_LATER: NOT_AUTHORIZED
```

T-11 只實作 `OpenAiResponsesAnalysisProvider` 的 full-only
`AnalysisProvider.analyzeFull` adapter。它不得實作
`ProgressiveAnalysisProviderCapability`；remote provider 一律使用
`FullOnlyStrategy`。Default app composition 維持 deterministic Fake Provider，
remote provider 只能透過 explicit typed selection、explicit model 與 credential
source opt-in，且不新增 provider picker UI。

Required contract includes fixed HTTPS Responses API endpoint、`POST`、`store: false`、
strict JSON Schema、`additionalProperties: false`、system／user input separation、
typed refusal／incomplete／malformed／HTTP／timeout／cancel mapping、controlled
transport cancellation、late completion rejection、safe Traditional Chinese UI
disclosure 與 no-fallback behavior。Live paid API call 不執行。

Typed observability 只允許下列實際 events：

```text
analysis_request_started
provider_started
provider_completed
schema_decode_completed
analysis_request_failed
analysis_request_cancelled
```

只量測：

```text
provider_setup_ms
response_read_ms
json_decode_ms
total_latency_ms
```

不得記錄 raw input、prompt、output、response body、clipboard、credential、Auth
header、stack trace 或 arbitrary exception；不得捏造 first-token 或 model-generation
timing。Default sink 為 bounded in-memory，sink failure 不得影響分析結果。

T-11 同時補上 T-10 late Preview success、late Preview failure 與 late Full success
的 stale-result regression tests；不建立 T-10R，不進入 T-12 或後續 task。

---

# T-11R — PR #14 provider remediation

**State:** `READY_FOR_REVIEW`

**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-11R_REMEDIATION_ONLY`

T-11R 只修正既有 PR #14 的 review findings：`HttpClientAnalysisHttpTransport`
必須在 request 建立前與建立後都支援 typed cancellation，所有階段共用一個
provider deadline，並以 streaming byte count 套用命名的 `maxResponseBytes`
上限。Cancellation、transport exception race 與 timeout 必須由不使用 live
network 的 controlled tests 證明。

`provider_setup_ms`、`response_read_ms`、`json_decode_ms` 與
`total_latency_ms` 必須各自使用真實且可驗證的 start／end boundary；
`provider_completed` 只能在 HTTP、schema validation 與 typed decode 全部成功後
發出，且每次 execution 只能有一個 terminal outcome。Telemetry sink failure
不得改變 application behavior，也不得記錄 raw input、response、credential、
Authorization header 或完整 prompt。

Analysis UI 必須使用 provider-neutral identity；Default Fake 與 OpenAI Remote
disclosure 必須保持一致。Required evidence 位於 `docs/evidence/T-11R/`。

T-11R 不執行 live OpenAI API、不修改 schema v3 欄位、不進入 T-12 或後續 task、
不建立新 Branch／PR、不 Merge、不啟用 Auto-merge，也不將 PR 標示為 Ready for
Review。

---

# T-12 — Windows desktop integration

**State:** `BLOCKED_ENVIRONMENT_MANUAL_HOTKEY`

**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-12`

**Preceding state:** T-11 `ACCEPTED_AND_MERGED`

**T-11 merge SHA:** `10f2d3da98d1fdbdfd2e0abbb39d758a396a6183`

Implement behind platform interfaces:

- global hotkey;
- selected-text capture;
- bounded clipboard fallback;
- floating panel;
- window activation;
- display-bound positioning;
- clear failure and permission states.

No Win32 or PowerShell calls from Widgets.

Verification requires Windows build and manual smoke evidence.

Candidate code-level verification is complete. Required default `Ctrl+Alt+Space`
manual registration-success smoke is blocked because a pre-implementation host
probe returned `RegisterHotKey=False` and `GetLastError=1408`; T-12 must not be
marked `READY_FOR_REVIEW` until that evidence is rerun on a clean hotkey owner.

T-13 及後續：`NOT_AUTHORIZED`。

---

# T-13 — macOS desktop integration

**State:** `NOT_AUTHORIZED`

Implement behind the same contracts:

- global hotkey;
- Accessibility selected-text capture;
- floating panel;
- window activation;
- permission guidance.

macOS claims require macOS execution evidence.

---

# T-14 — History, cache, settings, Favorite, and feedback

**State:** `NOT_AUTHORIZED`

History:

- enabled by default with disclosure;
- can be disabled;
- visible limit 20;
- single deletion;
- clear;
- export.

Favorite:

- mark/unmark;
- shared record component;
- favorites are not automatically evicted.

Cache:

- separate from visible history;
- version-aware keys;
- stale invalidation.

Feedback:

- structured reasons;
- optional comment;
- explicit consent before attaching input/output.

State updates must be in place; avoid whole-list reload for simple mutations.

---

# T-15 — Benchmark and MVP hardening

**State:** `IN_PROGRESS`

Compare providers using:

- total latency;
- time to first token;
- output quality;
- structured-output success rate;
- cost;
- failure rate;
- cancellation success;
- authentication friction.

External MVP approval requires:

- Windows build and smoke evidence;
- macOS build and smoke evidence;
- critical tests accepted;
- no known critical data-loss or secret-exposure issue;
- Luke's final approval.

---

# T-12R — PR #15 expanded final remediation

**State:** `READY_FOR_REVIEW`
**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-12R_PR15_EXPANDED_FINAL`
**Branch:** `feat/t12-windows-integration`
**Draft PR:** `#15`
**T-13 and later:** `NOT_AUTHORIZED`

---

# T-12R2 — PR #15 final native boundedness correction

**State:** `USER_ACTION_REQUIRED_T-12R2_WINDOWS_MANUAL_QA`
**Authorization:** `IMPLEMENTATION_AUTHORIZED: T-12R2_FINAL_NATIVE_BOUNDEDNESS_CORRECTION_ONLY`
**Branch:** `feat/t12-windows-integration`
**Draft PR:** `#15`
**Implementation candidate:** `218261d2f6b0a782a7dcd82fd5ad585da0461b8d`
**T-13 and later:** `NOT_AUTHORIZED`

## Scope

- Clipboard post-Copy cleanup state machine、capture deadline、獨立 `750ms` cleanup deadline、sequence ownership、exact restore／verify 與 deterministic native harness。
- UI Automation deadline watchdog、deadline-triggered `CoCancelCall`、typed `T-12R2_UIA_BOUNDEDNESS_BLOCKED` fallback、generation checks 與 owned shutdown boundary。
- Startup Provider hydration、Application-owned secret boundary、typed secure-storage failures、atomic Save and Apply 與 required regression tests。
- Luke-authorized generated `pubspec.lock`，包含 `flutter_secure_storage 10.3.1` 與必要 platform／transitive packages。

## Evidence

Evidence：`docs/evidence/T-12R2/`。Verified implementation SHA `218261d2f6b0a782a7dcd82fd5ad585da0461b8d` 的 fresh clone focused `23 PASS`、full `150 PASS`、native watchdog／UIA timeout／Clipboard state-machine harness、format、analyze、Windows build 與 immutable diff check 均通過；fresh `flutter pub get` 後 tracked lockfile 未變更。Receipt：`D:\GitHub\workspace\T-12R2-integration-218261d.log`。

Clipboard deadline correction：`ACCEPTED`。
UIA bounded timeout correction：`ACCEPTED`。
Automated integration verification：`PASS`。
GitHub checks：`NO_CHECKS_REPORTED`；Gate `NOT_APPLICABLE`，不視為 PASS 或 integration blocker。
Windows manual QA：`PENDING`。
macOS build：`REPORTED_PASS_BY_EASON`；macOS formal evidence／secure-storage QA：`PENDING`。
`T-12R2_READY_FOR_TEAM_REVIEW`：`false`。
`SAFE_TO_MERGE`：`false`。

## Gates

Windows desktop manual QA 與 macOS shared-code／secure-storage QA 尚未完成；未完成前不得標記 `T-12R2_READY_FOR_TEAM_REVIEW`，不得 Merge、Auto-merge、Ready for Review 或進入 T-13。

## Scope

- Required hotkey is `Alt + S`。
- Native hotkey registration must run on the window owner thread and map Win32 failures to typed statuses。
- Selected-text capture and clipboard fallback use owned operations, one deadline, cancellation guards, sequence-safe restoration and no detached workers。
- Captured draft updates only after successful panel show and activation；failed activation preserves normalized draft without requesting focus。
- Desktop shell contains only `分析` and `設定`；wide layout uses `NavigationRail`，compact layout uses `NavigationBar`。
- One `openai-default` Provider Profile supports secure credential storage、environment fallback and future profile expansion without implementing multi-account behavior。
- Provider switching is Application-owned，cancels active work，preserves draft／mode and rejects late completions。

## Exclusions

Live OpenAI API、T-13 native macOS integration、multi-account、failover、budget、cost routing、other providers、custom endpoint、History、Favorites、Review、schema v4、Merge 與 Auto-merge 均未授權。

## Required evidence

完整 command evidence、focused／full tests、format、analyze、Windows build、native harness、Windows manual smoke、macOS limitation、archive hash、security review 與 existing PR #15 metadata 必須保存在 `docs/evidence/T-12R/`。

---

# T-12R3 — Ethan product parity contract and bounded migration plan

**State:** `READY_FOR_REVIEW`
**Authorization:** Documentation-only product realignment，未授權 product code implementation
**Branch:** `feat/t12-windows-integration`
**Draft PR:** `#15`
**Product source of truth:** Ethan `D:\\GitHub\\temp\\Merged Model 2` at `df4f5424e8abfedc52f941c8c5c2f1a9463e8aac`
**T-12R2 Windows manual QA:** `FAIL`
**Ethan functional parity:** `FAIL`
**T-13 and later:** `NOT_AUTHORIZED`

## Scope

- 建立 `docs/product/T-12R3_ETHAN_PRODUCT_PARITY.md` 作為 authoritative product parity contract。
- 將 Dashboard、History、Favorites、Review、Settings、speech／pronunciation、recent-query 與 learning-state visibility 設為產品目標。
- 將 UI Automation 從 mandatory capture gate 修正為 optional enhancement；bounded Clipboard workflow 是支援 Windows 的正常路徑。
- 保留 LingoLens Reading／Expression、structured contracts、provider abstraction、secure credential storage、cancellation／timeout、observability、typed failures 與 automated evidence。
- 評估既有 PR #15 restructuring 與 replacement branch 兩種策略，但本 Task 不建立新 branch 或 PR。

## Evidence and gates

T-12R2 automated verification 仍以 implementation SHA `218261d2f6b0a782a7dcd82fd5ad585da0461b8d` 為準；Windows manual QA 的 current observed result 是 application launch `PASS`、hotkey／activation observable `PASS`、selected-text workflow `FAIL` with `uiaBoundednessBlocked`。Ethan functional parity 為 `FAIL`。`SAFE_TO_MERGE: false`。

本 Task 僅執行 `git diff --check`；不得執行 Flutter／Dart commands。不得修改 `lib/`、`windows/`、`macos/`、`test/`、`pubspec.yaml`、`pubspec.lock` 或 source repositories。

## Next authorized node

`T-12R3-B`：依 parity contract 提出 bounded implementation slices，仍須 Luke 最新明確 authorization；在此之前不得開始 product code、Merge、Auto-merge、Ready for Review 或 T-13。
