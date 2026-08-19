# Feature Specifications

這個資料夾是 LingoLens 功能開發的共同規格入口。每一項功能使用一份
Markdown 規格書，例如 `F-001-personal-learning-memory-v2.md`。

## 使用方式

1. PM 先依 `TEMPLATE.md` 建立功能規格草稿。
2. Joe、Eason、Luke、Ethan 分別確認自己的責任、依賴與問題。
3. PM 確認產品規則與驗收條件後，才開始實作。
4. 各 Owner 依 `TEAM.md` 的邊界開發；跨層變更須由對應 Owner review。

`FORMAL_IMPLEMENTATION_SPEC` 表示產品規則與跨層交接已凍結為正式實作規格；它不取代
`AGENTS.md`、`handoff.md` 或 task-level 的 production implementation authorization。

## 目前功能規格

| ID | 功能 | 優先級 | 狀態 | 規格 |
| --- | --- | --- | --- | --- |
| F-001 | 個人學習記憶 | P0 | FORMAL_IMPLEMENTATION_SPEC | [F-001-personal-learning-memory-v2.md](F-001-personal-learning-memory-v2.md) |
| F-002 | AI 分析核心與統一結果 | P0 | FORMAL_IMPLEMENTATION_SPEC | [F-002-ai-analysis-core.md](F-002-ai-analysis-core.md) |
| F-003 | Cache-First 分析體驗 | P0 | DRAFT | [F-003-cache-first-analysis.md](F-003-cache-first-analysis.md) |
| F-004 | 低壓複習與回想 | P1 | DRAFT | [F-004-low-pressure-review.md](F-004-low-pressure-review.md) |
| F-005 | 生成客製化複習素材 | P1 | DRAFT | [F-005-personalized-review-materials.md](F-005-personalized-review-materials.md) |
| F-006 | 全域快捷鍵、選取文字與浮動分析視窗 | P0 | DRAFT | [F-006-global-hotkey-floating-analysis.md](F-006-global-hotkey-floating-analysis.md) |
| F-007 | 跨情境英文聆聽與發音 | P1 | DRAFT | [F-007-contextual-tts-pronunciation.md](F-007-contextual-tts-pronunciation.md) |

## 文件優先順序

功能規格書用於協作，不取代既有治理文件。若內容衝突，依下列順序處理：

1. 最新 Product Owner 指示
2. 已接受的 ADR
3. `AGENTS.md`
4. Root `handoff.md`
5. `agent_tasks.md`

實作前仍須讀取 `AGENTS.md`、`handoff.md` 與相關 ADR，並確認當前授權。
