# T-12R 參考決策矩陣

本文件記錄 Ethan pinned source 的產品 parity decision 與 LingoLens 的 implementation boundary。不複製其實作、商標、原始碼或 native integration；產品 UX／feature behavior 仍以 Ethan 為 Source of Truth。

| Concept | Reference source | 決策 | LingoLens implementation boundary | Reason | Risk | Verification |
|---|---|---|---|---|---|---|
| Material 3、indigo-family `ColorScheme`、system theme | Ethan `df4f5424e8abfedc52f941c8c5c2f1a9463e8aac` | ADOPT | Flutter `ThemeData`、`ColorScheme.fromSeed`、`ThemeMode.system` | 與既有 Flutter stack 相容，支援 light/dark 與 accessibility | 深色模式對比或 surface 層級不足 | Widget tests、Windows screenshots、`flutter analyze` |
| Desktop `NavigationRail` 與產品 destinations | Ethan `df4f5424e8abfedc52f941c8c5c2f1a9463e8aac` | ADOPT／ADAPT | 產品目標包含 Dashboard、History、Favorites、Review、Settings；寬版 rail、窄版 compact control | Ethan product IA 是 parity target；LingoLens 保留自身元件與 state boundary | Compact panel 與 incremental migration 可能增加寬度與 state 風險 | Wide／compact widget tests與 manual UI evidence |
| Settings section cards 與 provider status | Ethan `df4f5424e8abfedc52f941c8c5c2f1a9463e8aac` | ADAPT | 一般、AI Provider、隱私與安全 cards | 保留清楚的學習產品層級，改為 LingoLens approved scope | 狀態文字可能洩漏 credential | Semantics tests、security review |
| Compact floating panel hierarchy | Ethan `df4f5424e8abfedc52f941c8c5c2f1a9463e8aac` | ADAPT | 既有 Windows panel service、actual size 與 Escape dismissal | 不採用 `desktop_multi_window` 或 Ethan native design | Windows host smoke 仍可能受環境阻塞 | Native build、manual smoke |
| Provider／model separation | LAS `ee50c66f090334144e0a2dc58dde899fffe8351b` | ADOPT | Domain `ProviderProfile` 與 runtime composition 分離 | 讓 provider identity 與 model 設定可驗證 | 與既有 T-11 composition 整合錯誤 | Domain、application composition tests |
| Stable profile identity、credential indirection | LAS `ee50c66f090334144e0a2dc58dde899fffe8351b` | ADAPT | 單一 `openai-default`、`CredentialReference` 僅存 alias／env name／none | 支援未來多帳戶邊界，但本輪不實作多帳戶 | secret 進入 state 或 persistence | Security tests、state assertions |
| Active provider selection、fail-closed configuration | LAS `ee50c66f090334144e0a2dc58dde899fffe8351b` | ADAPT | Fake 預設、OpenAI explicit opt-in、缺設定時顯示 configuration required | 避免 silent Fake fallback 與意外 network request | startup hydration race | Provider coordinator tests |
| Environment credential reference | LAS `ee50c66f090334144e0a2dc58dde899fffe8351b` | ADAPT | `OPENAI_API_KEY` 作為 secure storage 後備來源 | 保留本機 BYOK 邊界，不持久化 raw key | 環境變數可能被誤認為已安全保存 | Credential precedence tests |
| Multiple accounts、failover、budget、cost routing、tenant state | LAS `ee50c66f090334144e0a2dc58dde899fffe8351b` | REJECT | 本輪只有一個 OpenAI profile，無 account collection、failover 或 routing | 明確排除 LAS 不符合 LingoLens MVP 的範圍 | 未來擴充需保持 contract 相容 | Profile count、scope tests |
| Ethan provider state package、Isar、`window_manager`、`hotkey_manager`、Codex CLI、automatic analysis after capture | Ethan `df4f5424e8abfedc52f941c8c5c2f1a9463e8aac` | PRODUCT ADOPT／CODE REJECT | 保留 product behavior target；使用既有 Application interfaces、Windows MethodChannel 與 LingoLens persistence boundary 重新實作 | Ethan 行為是 parity target，但不得複製 donor architecture 或未授權 dependencies | 行為差異與 migration regression 需由 LingoLens tests 鎖定 | Architecture dependency tests |
| LAS React／Tauri、topology／administration pages、raw `accounts.json` secret | LAS `ee50c66f090334144e0a2dc58dde899fffe8351b` | REJECT | 不引入 React、Tauri、拓撲頁或檔案 credential store | 僅取 provider-neutral concepts，不複製實作 | 參考文字可能被誤讀為 implementation permission | Review diff、privacy scan |

## Provenance boundary

Ethan pinned source 在產品 UX／feature behavior 上是 `PRODUCT_SOURCE_OF_TRUTH`；在 code reuse、provider implementation、native integration 與 secret storage 上仍是 `BEHAVIOR_REFERENCE`，不是 copy permission。LAS 僅作為 `CONCEPT_ONLY`。本 Repository 未複製任何完整 application。所有 production code 均在 LingoLens 的既有 Presentation／Application／Domain／Infrastructure boundary 內重新實作。完整 parity contract 與 salvage matrix 見 `docs/product/T-12R3_ETHAN_PRODUCT_PARITY.md`。

## Product parity correction

- Ethan product feature set：`Dashboard`、`History`、`Favorites`、`Review`、`Settings`、speech／pronunciation、recent-query 與 learning-state visibility：`ADOPT` 為產品 target。
- `UIA-first mandatory capture`：`REPLACE` 為 optional UIA enhancement；支援 Windows 的正常 bounded Clipboard workflow 不得被 UIA gate 阻擋。
- LingoLens enhancements：Reading／Expression、typed analysis、secure credential storage、provider abstraction、cancellation／timeout、observability 與 typed failures：`KEEP`。
- Product source pinned commit：`df4f5424e8abfedc52f941c8c5c2f1a9463e8aac`。
