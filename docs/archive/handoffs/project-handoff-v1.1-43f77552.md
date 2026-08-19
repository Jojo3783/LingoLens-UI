# LingoLens — Project Handoff

> **Version:** 1.1  
> **Handoff date:** 2026-07-26  
> **Recipient:** Codex  
> **Project Owner:** Luke  
> **Reviewer:** ChatGPT  
> **Status:** Ready for pre-implementation baseline, audit, and architecture planning  
> **Production implementation:** Not authorized  
> **Authorized tasks:** `T-00` through `T-04`

## 1. Executive summary

LingoLens is being rebuilt as a cross-platform Flutter desktop application for Windows and macOS.

The first MVP focuses on contextual Chinese-English translation and structured language analysis. The complete learning application is a future evolution and is not part of the current implementation authorization.

Three local implementations are available:

1. Jimmy's Swift/macOS prototype, used as functional and behavioral reference.
2. Joe's Flutter implementation, used as a selective module donor.
3. Ethan's Flutter implementation, used as the primary base candidate.

The target is not to combine directory trees mechanically. The target is to create one maintainable architecture, retain the strongest capabilities, and align product behavior with the Swift prototype.

## 2. Source-of-truth precedence

Use this order:

1. Luke's latest explicit instruction.
2. Accepted ADR.
3. `AGENTS.md`.
4. `handoff.md`.
5. `agent_tasks.md`.
6. Other documentation.
7. Existing code behavior.

When documents conflict, stop and report the conflict.

## 3. Local workspace

### 3.1 Official writable repository

```text
D:\GitHub\LingoLens
```

This is the only official implementation workspace.

Before changing files, Codex must inspect and report:

```powershell
git remote -v
git branch --show-current
git rev-parse HEAD
git status --short
```

The exact GitHub owner and remote must be established by evidence, not assumed.

### 3.2 Read-only LingoLens sources

```text
D:\GitHub\temp\Prototype
D:\GitHub\temp\Merged Model 1
D:\GitHub\temp\Merged Model 2
```

| Directory | Remote repository | Role |
|---|---|---|
| `Prototype` | `https://github.com/j-neyrox/LingoLens` | Jimmy's Swift functional reference |
| `Merged Model 1` | `https://github.com/Jojo3783/MVP-flutter-LingoLens` | Joe's Flutter module donor |
| `Merged Model 2` | `https://github.com/FUNDAI/Lingolens_flutter_test` | Ethan's Flutter base candidate |

These directories must remain unchanged.

### 3.3 Disposable audit workspace

Commands that may generate or update files must run in:

```text
D:\GitHub\workspace\lingolens-audit
```

The original sources are used only to read Git metadata and create commit-pinned disposable clones.

## 4. Internal code donors

```text
D:\GitHub\LLM-Agent-System
D:\GitHub\Portable-Agent-Protocol
D:\GitHub\Python-learning-web
D:\GitHub\health_manager_app
D:\GitHub\AI-Smart-Food-Manager
D:\GitHub\kickstart-coach
D:\GitHub\pressuretalk
```

Candidate reuse areas:

| Donor | Candidate capability |
|---|---|
| LLM-Agent-System | Provider adapters, cancellation, timeout, lifecycle, cost control, verification discipline |
| Portable-Agent-Protocol | Agent contracts, workflows, handoffs, governance |
| Python-learning-web | Request IDs, structured logs, async calls, token/failure telemetry |
| health_manager_app | Flutter migration, local-first settings, reset/export/privacy flows |
| AI-Smart-Food-Manager | Structured API/error envelopes and Riverpod patterns |
| kickstart-coach | Flutter `app/core/features/shared`, Riverpod, Drift, bilingual patterns |
| pressuretalk | Structured AI output, constrained enums, local-first history, smoke-test patterns |

All donor repositories are read-only. Complete applications must not be imported.

## 5. Reuse permission boundary

A module's technical quality does not prove permission to copy it.

Each candidate must separately record:

- technical classification;
- permission status;
- license compatibility.

Code may be copied only when:

```text
DIRECT_REUSE_CANDIDATE
+ APPROVED
+ COMPATIBLE
```

No public license is selected for the new LingoLens repository until ownership and source-code reuse permissions are resolved.

## 6. Current product contract

### 6.1 Core workflow

```text
User types or selects text
→ application receives or suggests a mode
→ manual override remains available
→ cache lookup
→ provider analysis
→ fast usable result
→ complete structured result
→ Copy / Listen / Save / Favorite / Retry / Cancel / Feedback
```

### 6.2 Reading mode: English → Chinese

Required output:

- Translation.
- Sentence analysis.
- Grammar.
- Vocabulary.
- Nuance.

### 6.3 Expression mode: Chinese → English

Required output:

- Natural.
- Polite.
- Formal.
- Context.
- Tone.

### 6.4 Mode behavior

- Automatic language and mode suggestion.
- Manual mode override.
- Manual selection has priority.
- Mixed-language or low-confidence input may trigger lightweight confirmation.
- Do not force confirmation for every request.
- Context and Tone are not directly editable in the first MVP.

### 6.5 Input boundary

Maximum input length:

```text
2,000 characters
```

Longer input must be rejected clearly.

## 7. Current MVP capabilities

- Manual input.
- Selected-text capture.
- Global hotkey.
- Floating panel.
- Windows and macOS support.
- Automatic mode suggestion.
- Manual mode override.
- Progressive result experience.
- Copy.
- Listen.
- Retry.
- Cancel.
- Save.
- Minimal Favorite.
- Structured feedback.
- Local history.
- Cache.
- Latency observability.
- Provider benchmark support.

## 8. Favorite decision

Minimal Favorite is included in this MVP plan.

Authorized behavior:

- mark and unmark a saved record;
- preserve favorites when enforcing the visible-history limit;
- reuse the same record component in History and Favorite views.

Deferred:

- Favorite-based exercises;
- Favorite learning analytics;
- advanced organization, tags, or folders.

## 9. Deferred learning capabilities

- vocabulary highlighting and review;
- daily review;
- spaced repetition;
- fill-in-the-blank;
- multiple choice;
- Daily English;
- streaks and XP;
- long-term learning analytics;
- accounts and cloud sync;
- subscription and billing;
- mobile application.

Interfaces may preserve future extensibility, but current tasks must not implement the complete learning app.

## 10. UX decisions

### 10.1 Reading hierarchy

1. Translation.
2. Copy.
3. Listen.
4. Sentence analysis.
5. Grammar.
6. Vocabulary.
7. Nuance.

### 10.2 Expression hierarchy

1. Natural.
2. Copy.
3. Listen.
4. Polite.
5. Formal.
6. Context.
7. Tone.

### 10.3 Waiting experience

Product requirement:

```text
A fast usable result appears before the complete analysis.
```

The technical mechanism remains open until `ADR-005` is accepted.

Possible mechanisms:

- two-stage requests;
- streaming structured output;
- hybrid progressive parsing.

Progress labels must reflect actual states.

### 10.4 Popup

- Clicking outside closes the popup.
- History may preserve completed results.
- Keep the popup inside usable display bounds.
- Screen-edge disappearance requires usability validation.
- Do not close or move the popup while the user is actively interacting unless explicitly specified.

### 10.5 Dissatisfaction feedback

Candidate reasons:

- meaning wrong;
- unnatural expression;
- Tone mismatch;
- grammar explanation wrong;
- explanation too long;
- Vocabulary too basic;
- example irrelevant;
- structured response failed;
- other.

Raw input/output may be attached only with explicit consent.

## 11. History, cache, and privacy

- History enabled by default with first-run disclosure.
- User can disable new history writes.
- Visible history limit: 20 records.
- Single-record deletion.
- Clear history.
- Export.
- Favorites are not automatically evicted.
- History and cache are separate.
- Analytics does not store raw input by default.
- Debug logs must not store user text by default.
- Feedback content attachment is opt-in.

## 12. Reliability and provider plan

The project must compare:

- optimized Codex CLI;
- official API;
- local algorithm or model.

Benchmark dimensions:

- total latency;
- time to first token;
- output quality;
- structured-output success rate;
- cost;
- failure rate;
- cancellation success;
- authentication friction.

Timing segments where measurable:

```text
input capture
language/mode detection
cache lookup
provider setup
CLI startup
time to first token
model generation
response read
JSON parsing
persistence
UI display
total latency
```

An end-to-end processing time of approximately 20 seconds was reported. It is a provisional observation, not a validated benchmark.

## 13. Structured output direction

Use a common envelope and distinct typed Reading and Expression results.

Conceptual envelope:

```json
{
  "schemaVersion": "1.0",
  "requestId": "uuid",
  "mode": "reading",
  "detectedLanguage": "en",
  "provider": "codex_cli",
  "result": {}
}
```

Do not use one model filled with unrelated nullable fields.

## 14. Concurrency direction

The product behavior is **latest request wins**:

1. a new request cancels active work;
2. outdated pending work is discarded;
3. only the newest request may update the UI;
4. cancellation propagates to the process or request where supported;
5. race behavior requires tests.

## 15. Prototype issues converted into Flutter acceptance criteria

### Layout and selection

- Clicking empty space below a record must not clear selection.
- Empty-space interaction must not cause layout reflow.
- History and Favorite share one record component.
- Detail panes have a minimum usable width.
- Responsive layout prevents component compression and displacement.

### State updates

- Single-record mutations update local state in place.
- Do not fully reload after favorite, note, or later review mutations.
- Replacing the entire records array must not destroy navigation selection or trigger split-view instability.

The “add to today's review does not reset” issue belongs to the future learning phase.

## 16. Repository integration direction

Current provisional recommendation:

- Jimmy Swift project: behavioral reference.
- Ethan Flutter project: primary base candidate.
- Joe Flutter project: selective module donor.
- Internal FindAi projects: targeted capability donors.

This is not final until disposable-clone baselines and code-level audit evidence are complete.

Do not merge full directory trees before ADR approval.

## 17. Required audit controls

Before executing a Flutter source:

1. freeze its commit SHA;
2. confirm the original working-tree state;
3. create a disposable clone with `--no-hardlinks`;
4. inspect dependencies, scripts, plugins, binaries, and secret handling;
5. locate the actual Flutter app root using `pubspec.yaml`;
6. run commands only in the disposable clone;
7. recheck the original source afterward.

Joe's Flutter application may be below the repository root. No repository may be assumed to have its Flutter app at the top level.

## 18. Open decisions

1. Ethan base import versus clean Flutter skeleton.
2. Provider versus Riverpod.
3. Isar versus Drift/SQLite.
4. Local provider architecture versus future FastAPI relay.
5. Two-stage requests versus streaming structured output versus hybrid approach.
6. Final Windows selected-text method.
7. Final macOS selected-text method.
8. Ownership and reuse permissions.
9. Final public license.
10. Provider and credential policy.

Portable Agent Protocol supports development governance and handoff. It is not the runtime parser for partial translation output.

## 19. Current authorization

Codex may execute:

```text
T-00 Workspace preflight
T-01 Governance scaffold
T-02 Disposable source baseline
T-03 Code-level capability audit
T-04 Proposed architecture decisions
```

After T-04:

```text
STOP_FOR_TEAM_REVIEW
```

Codex may not begin production implementation.

To authorize the Flutter skeleton, Luke must explicitly provide:

```text
IMPLEMENTATION_AUTHORIZED: T-05
```

## 20. Not authorized

- direct merge or push to `main`;
- modification of source repositories;
- building inside `D:\GitHub\temp`;
- full copy of Joe's or Ethan's repository;
- silent dependency modernization;
- automatic selection of State Management or Persistence;
- public licensing;
- production release;
- claiming macOS verification from Windows;
- T-05 or later without explicit authorization.

## 21. First Codex response required

Before changing any file, Codex must report:

```text
1. Current task and authorization:
2. Confirmed writable repository and remote:
3. Current branch and HEAD:
4. Working-tree status:
5. Flutter/Dart/Git versions:
6. Existing governance files:
7. Source repositories detected:
8. Planned commands:
9. Files expected to change:
10. Blockers, conflicts, or assumptions:
```

## 22. Handoff success condition

This handoff is accepted when Codex:

- reads all three governance files;
- confirms source-of-truth precedence;
- confirms workspace boundaries;
- produces truthful evidence;
- uses disposable audit clones;
- does not modify source repositories;
- separates technical reuse from permission and license;
- stops after T-04;
- does not begin application code without `IMPLEMENTATION_AUTHORIZED: T-05`.
