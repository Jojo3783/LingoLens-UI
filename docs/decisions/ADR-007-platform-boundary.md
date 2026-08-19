# ADR-007 Platform Boundary

Title: Platform Boundary
Status: ACCEPTED
Date: 2026-07-27
Decision owners: Luke、Team Review、Codex 提案

## Context

T-03 顯示 M1 的 clipboard、PowerShell、`osascript` 與 TTS side effects，以及 M2 的 selected-text、hotkey、floating window 與 speech services，都需要與 Presentation／Application 分離。Prototype 只能作 macOS behavior reference，不代表 Flutter macOS verification。

## Decision

保留 Platform Adapter architecture 與 security rules，但不要求 T-05 預先建立每一項未使用的 OS capability interface 或 fake adapter。Platform interface 應在一個已授權的 task 真正需要該 capability 時才引入。

### Stable platform rules

- Widgets 及 Domain 不得直接呼叫 Win32、PowerShell、AppleScript、Clipboard APIs、Process、native plugins 或其他 OS APIs。
- Platform Adapter 必須隔離 permission、OS handle、window lifecycle、process invocation 與 cleanup。
- selected-text capture 只能由 user-triggered hotkey 或 explicit action 觸發。
- Accessibility 不可用時，bounded clipboard fallback 必須保存 snapshot，只有 clipboard 仍由本 request 改變時才 restore；timeout、empty result 或 concurrent modification 必須回傳 typed error，不得回傳 stale clipboard text。
- PowerShell 不是預設 platform primitive；若日後獲授權使用，必須位於 platform／infrastructure seam，使用固定 executable、固定 argument contract、timeout、stderr mapping 與 no raw user input in command string。
- Windows host 不得宣稱 macOS verification；macOS claim 必須有 macOS execution evidence。

### T-05 scope

T-05 manual-input flow 不需要 hotkey、selected-text、clipboard、floating-window、TTS、permission 或 native process implementation。T-05 必須保留 platform seam，但不得建立 speculative unused interfaces 或 fakes，也不得執行任何 OS integration。

## Architecture boundaries

```text
Presentation
    ↓
Application
    ↓
Platform／Domain Interfaces
    ↓
Windows Adapter／macOS Adapter（於授權 task 引入）
```

- `presentation` 只提交 Application intent。
- `application` 只依賴已授權且有實際使用需求的 Platform Interface。
- `platform` 承擔 OS-specific permission、lifecycle、argument safety 與 cleanup。
- `infrastructure` 承擔 generic `ProcessRunner`；OS-specific process policy 由 Platform Adapter 提供。

## Consequences

- T-05 可先完成 manual input + Fake Provider，不需為未使用能力增加空殼 abstractions。
- 後續每個 platform capability 仍必須有 interface、adapter scope、permission policy 與可驗證的 error semantics。
- 將 capability 延後不等於放寬 selected-text、clipboard、PowerShell 或 macOS evidence 的安全規則。

## Testing and validation strategy

- T-05 只驗證沒有 direct OS/API calls，並驗證 Application seam 可替換。
- selected-text task 另行驗證 permission、empty selection、timeout、concurrent clipboard change、restore success／failure。
- Windows task 另行驗證 safe process args、no shell interpolation、UTF-8、kill／cleanup 與 window／hotkey lifecycle。
- macOS task 必須在 macOS environment 驗證 Accessibility、Carbon／hotkey、NSPanel 與 TTS behavior。

## Migration plan

先交付無 platform integration 的 manual-input flow。當某個 authorized task 需要 platform capability 時，再建立最小 interface、deterministic fake 與對應 OS adapter；M1／M2 OS code 只作 reference，不直接搬移。

## Rollback plan

若 adapter 不穩定，保留 manual input + fake provider flow，將該 capability 標示 `UNSUPPORTED`。不得把 OS call 回填 Widget，也不得以 speculative fake 宣稱 integration 已完成。

## Open questions

- Windows selected-text capture 是否核准 native plugin，或必須提供 accessibility-first fallback？
- Floating window 的 topmost 與 click-outside 行為是否屬於同一 authorized task？
- macOS verification environment 何時可提供？

## T-05 implications

T-05 只保留 Platform seam 與相關 architecture constraint，不實作 Win32、PowerShell、AppleScript、Accessibility、hotkey、clipboard、floating-window、TTS、permission 或 native process runtime integration。只有後續明確授權的 task 才能引入實際 platform interface。

## Approval

Status: ACCEPTED
Accepted by: Luke, Product Owner
Acceptance source: explicit ChatGPT project instruction
Acceptance date: 2026-07-28
Architecture Review disposition: ACCEPTED_WITH_NON_BLOCKING_FOLLOWUPS
