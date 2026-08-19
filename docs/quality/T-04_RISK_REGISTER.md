# T-04 Architecture Risk Register

狀態：`ACCEPTED`；ADR-001 至 ADR-007 已接受，剩餘項目為 `ACCEPTED_WITH_NON_BLOCKING_FOLLOWUPS`，T-05 已獲明確 authorization。

## Gate taxonomy

每個 risk 必須且只能使用以下一個 gate category：

```text
BLOCKS_ADR_ACCEPTANCE
BLOCKS_T05_SKELETON
BLOCKS_FUTURE_PRODUCTION_INTEGRATION
NON_BLOCKING_FOLLOWUP
```

`BLOCKS_T05_SKELETON` 只表示 T-05 skeleton 所需的 contract 或 deterministic fake 尚未具備；不代表需要提前加入 real provider、durable database 或 OS integration。`BLOCKS_FUTURE_PRODUCTION_INTEGRATION` 不阻擋 manual-input + Fake Provider skeleton。

## Register

| ID | Severity | Source finding | Architecture impact | Gate category | Required resolution | Validation method | Residual risk |
|---|---|---|---|---|---|---|---|
| AR-001 | P1 | T-03 F-007；M1 analyze/test failure | 錯誤 base strategy 會把 incomplete wiring 帶入 skeleton | `NON_BLOCKING_FOLLOWUP` | 維持 Clean Flutter Skeleton；donor 僅作 reference | ADR-001 decision 與 clean branch evidence | skeleton 初始成本 |
| AR-002 | P1 | T-03 F-001 | Silent Mock fallback 會產生 fabricated success | `BLOCKS_FUTURE_PRODUCTION_INTEGRATION` | provider source／failure 必須 explicit、typed、observable；T-05 fake 可維持 full-only | provider failure、no-silent-fallback contract tests | future offline fallback policy 待決定 |
| AR-003 | P1 | T-03 F-006 | Cache／History 混用會破壞 privacy 與 retention semantics | `NON_BLOCKING_FOLLOWUP` | T-05R 已定義 interfaces、fake isolation、favorite protection；T-05R2 修正 visible query total limit；不加入 Drift runtime | repository contract tests PASS、T-05R2 selection tests | visible policy 待 T-05R2 Team Review；durable schema 待未來 ADR |
| AR-004 | P1 | T-03 F-008 | 未確認 permission／license 不可安全 copy donor code | `BLOCKS_FUTURE_PRODUCTION_INTEGRATION` | 無 evidence 不複製 donor production code | provenance、permission、license evidence | clean skeleton 仍需自行建立 |
| AR-005 | P1 | T-03 F-003 | generation guard 不能停止 underlying CLI／stream | `NON_BLOCKING_FOLLOWUP` | T-05R 已補強 deterministic fake cancellation、stale-result 與 lifecycle tests；real process cancellation 仍作 production gate | race、cancel、stale-result contract tests PASS | third-party adapter 可能 unsupported |
| AR-006 | P2 | T-03 F-002 | raw input／prompt／stdout／stderr 可能洩漏使用者資料 | `BLOCKS_FUTURE_PRODUCTION_INTEGRATION` | production default redacted logging；raw data 僅明確 opt-in | static Log scan、redaction tests | diagnostics retention 待定 |
| AR-007 | P2 | T-03 F-004 | auto clipboard monitor 或 stale fallback 可能誤讀資料 | `BLOCKS_FUTURE_PRODUCTION_INTEGRATION` | selected-text 必須 explicit action、bounded fallback、concurrent-change fail-safe | clipboard contract tests、manual consent smoke | OS clipboard semantics 差異 |
| AR-008 | P2 | T-03 F-005 | dynamic PowerShell command 增加 injection risk | `BLOCKS_FUTURE_PRODUCTION_INTEGRATION` | direct native／plugin first；若使用 PowerShell，固定 executable／arguments／timeout | adversarial text tests、shell interpolation scan | native plugin availability |
| AR-009 | P2 | T-02 build failure | Windows CMake discovery 阻擋 Windows evidence | `BLOCKS_FUTURE_PRODUCTION_INTEGRATION` | 於 disposable workspace 取得實際 build evidence；文件不得宣稱 PASS | `flutter build windows` evidence | host toolchain drift |
| AR-010 | P2 | T-02 macOS NOT_RUN | Prototype behavior 不等於 Flutter macOS support | `BLOCKS_FUTURE_PRODUCTION_INTEGRATION` | 在 macOS environment 執行相關 build／permission／smoke evidence | macOS／Xcode execution evidence | 目前沒有 macOS environment |
| AR-011 | P2 | ADR-002 lifecycle ownership | Domain 若承擔 Riverpod／Widget state 會破壞 layer seam | `NON_BLOCKING_FOLLOWUP` | Domain contracts 與 Application lifecycle 分離；Riverpod 僅在 Application／composition | static architecture review、Domain dependency check | framework scope policy 待決定 |
| AR-012 | P2 | ADR-004／ADR-005 progressive contract | provider 若假設 two-stage 會限制 full-only path | `NON_BLOCKING_FOLLOWUP` | full-only provider、optional preview capability、Application-owned strategy 一致 | ADR consistency check、strategy contract tests | real-provider evidence 待未來 |
| AR-013 | P3 | ADR-005 two-stage latency／cost | duplicate request 可能增加 latency、cost 或 inconsistency | `BLOCKS_FUTURE_PRODUCTION_INTEGRATION` | T-05 使用 `FULL_ONLY_FAKE`；real two-stage `DISABLED_BY_DEFAULT`，具 evidence 後才可 enable | latency、cost、usefulness、consistency、cancel、partial-failure evidence | 尚無實際 provider benchmark |

## T-05 skeleton gate

目前 T-05 仍為：

```text
T-05 Status: REQUEST_CHANGES
T-05R Status: REMEDIATION_IN_PROGRESS
T-05R2 Status: REMEDIATION_IN_PROGRESS
```

T-05 skeleton 的實際必要 gate 是：

- `AR-003`：T-05R 已完成 repository interfaces 與 fake isolation；T-05R2 正在修正 visible-history selection policy，直到 Team Review 前仍屬 remediation；durable schema 仍是 future risk。
- `AR-005`：T-05R 已完成 deterministic cancellation abstraction、stale-result rejection 與 lifecycle tests；real process cancellation 仍是 future risk。
- `AR-001`：只阻擋 ADR-001 acceptance；Clean Flutter Skeleton 一旦被接受，不是永久 T-05 blocker。

Silent Mock、permission／license、raw logging、clipboard、PowerShell、Windows／macOS evidence 與 two-stage latency／cost 不阻擋 full-only Fake Provider skeleton，但會阻擋相應的 future production integration claim。

本 Register 不解除 future integration risks；本次 authorization 只涵蓋 T-05 manual-input vertical slice。
