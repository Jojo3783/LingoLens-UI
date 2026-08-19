# LingoLens

LingoLens 是一個面向 Windows 與 macOS 的 Flutter Desktop 跨平台語言工具，聚焦中文與英文的情境式翻譯及結構化語言分析。

## 目前階段

`T-15: READY_FOR_REVIEW`

T-14 已完成。目前 T-15（Provider 效能對比對照、時間與 Latency 評測、Token 估算、MVP 硬化與 Windows Release 二進位編譯 `lingolens.exe`）之程式碼實作與自動化測試（162 PASS）已全部完成，Windows 發行版編譯成功！

## 第一階段 Product Scope

- 中文 → 英文情境式表達。
- 英文 → 中文翻譯與結構化分析。
- 目標平台：Windows 與 macOS Flutter Desktop。
- Product shell：Dashboard、History、Favorites、Review 與 Settings。
- Product visibility：recent queries、learning state 與 speech／pronunciation support。
- Windows primary flow：`Alt + S`、bounded Clipboard fallback、ownership-aware restore、prewarmed floating panel、automatic analysis、Cache-First 與 result rendering。

## Governance 入口

- [AGENTS.md](AGENTS.md)：長期工程規則、Workspace 邊界與停止條件。
- [handoff.md](handoff.md)：目前任務與最新 operational 狀態。
- [agent_tasks.md](agent_tasks.md)：Task 順序、Deliverables 與 Gate。
- [docs/](docs/README.md)：正式文件與 Evidence 索引。

歷史 Handoff 位於 `docs/archive/handoffs/`，僅供背景參考，不代表目前 Task Status。

## Source 與資料安全

- Source Repository 不存在於本 Repository，且保持唯讀。
- 不得提交 Credential、使用者原始文字、本機資料庫或 Build Artifact。
- 尚未選擇 Public License，等待 Ownership 與 Source Reuse Permission 決策。

本 Repository 目前不是已完成的 MVP；T-12R2 自動化驗證已完成，但 Windows manual QA 為 `FAIL`，且仍須完成 macOS QA。Ethan pinned source `df4f5424e8abfedc52f941c8c5c2f1a9463e8aac` 是產品 UX／feature behavior 的 Source of Truth；不代表可複製其原始碼或 dependencies。歷史 Handoff 僅供背景參考，不代表目前 Task Status。

## T-12R 交付邊界

- Default Provider 維持 deterministic Fake；OpenAI Responses API 僅可由明確選擇啟用。
- Production providers 為 Codex CLI 與 OpenAI Responses API；Fake Provider 僅供 test／debug，兩者 production provider 遵循相同 Domain contract，且 Cache-First 優先於 provider execution。
- OpenAI 只提供單一 `openai-default` profile；API key 由 OS secure storage 管理，未設定時不靜默切回 Fake。
- Required Windows hotkey 為 `Alt + S`；native capture、post-Copy clipboard cleanup、window activation 與 typed failure evidence 位於 `docs/evidence/T-12R2/`。
- `pubspec.lock` 已提交 `flutter_secure_storage 10.3.1` 與必要 platform／transitive packages；fresh clone `flutter pub get` 後保持 clean。
- 本輪不包含 live API、multi-account、failover、其他 provider、custom endpoint、T-13 macOS native integration 或 Merge。Parity contract 與 salvage matrix 位於 `docs/product/T-12R3_ETHAN_PRODUCT_PARITY.md`。
