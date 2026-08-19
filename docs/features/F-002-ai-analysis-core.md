# F-002：AI 分析核心與統一結果

- 狀態：`FORMAL_IMPLEMENTATION_SPEC`
- 建立日期：`2026-08-15`
- PM：Jimmy
- 優先級：`P0`
- 關聯 task／PR：尚未建立
- Implementation authorization：`NOT_AUTHORIZED_BY_THIS_DOCUMENT`
- 說明：此為正式實作規格；此狀態僅凍結產品規則與跨層交接，不構成新的 production implementation authorization。

## 功能願景

LingoLens 的核心不只是取得翻譯，而是把使用者當下遇到的英文，轉化為容易理解、可
實際使用的學習解釋。無論分析由 Codex CLI 或 OpenAI API 產生，使用者都應得到一致
且可信的產品體驗。

Provider 是底層能力，不是使用者必須理解的差異。使用者應能依自己的設定明確選擇
Provider，而 LingoLens 則負責以同一套結果結構、錯誤語言與操作方式呈現分析。

## 邏輯流程

### 分析與結果流程

```text
使用者輸入文字
  ↓
判斷分析情境
  ├─ 英文 → 中文：Reading
  │    └─ 翻譯、句意／結構、單字、文法、語氣
  │
  └─ 中文 → 英文：Expression
       └─ 自然英文、關鍵片語、語氣／正式度、情境、常見錯誤
  ↓
使用者在設定中明確選擇 Provider
  ├─ Codex CLI
  └─ OpenAI API
  ↓
執行分析
  ├─ 處理中：顯示真實處理狀態
  ├─ 成功：轉換為統一的結構化結果
  ├─ 失敗：顯示可理解原因，可重試或調整設定
  └─ 取消：停止操作，不產生可保存結果
```

### 分層結果呈現

```text
成功的統一結果
  │
  ├─ 第一層：直接答案
  │    └─ 讓使用者立刻看懂翻譯或英文表達
  │
  ├─ 第二層：最重要的學習重點
  │    └─ 文法、單字、語氣、容易誤用之處
  │
  └─ 第三層：依需求展開的深入內容
       └─ 特殊用法、替代表達、例句、詳細解釋
```

### Provider 失敗處理

```text
使用者選定 Provider
  ↓
Provider 可用？
  ├─ 是 → 產生統一結果
  └─ 否 → 回傳明確錯誤
            ├─ 未安裝
            ├─ 未登入
            ├─ 缺少憑證
            └─ 執行失敗
```

Provider 不得靜默切換；失敗、取消、Preview 或過期結果不可當成完整學習結果保存。

## 使用者價值

- 不必在翻譯工具、聊天工具與英文教材之間切換。
- 不只知道字面意思，也知道文法、語氣、詞彙與實際用法。
- 分析內容有一致結構，方便快速閱讀，也方便未來儲存與複習。
- Provider 無法使用時，使用者能理解原因並決定重試或調整設定。

## 重要實作細項

### 兩種分析情境

- **英文 → 中文（Reading）**：至少提供自然翻譯、關鍵句意／結構、重要單字、必要的文法說明，以及語氣或特殊用法。
- **中文 → 英文（Expression）**：至少提供自然英文表達、關鍵片語、適合的語氣或正式程度、使用情境，以及容易出錯的地方。
- 兩種情境共用一致的結果骨架，但不可強迫使用相同欄位或相同內容深度。

### 分層結果體驗

- 每次分析先提供最直接的答案，讓使用者能立刻繼續閱讀或表達。
- 再提供少量最有學習價值的重點，例如文法、單字、語氣或常見誤用。
- 特殊用法、替代表達、例句與深入解釋可在使用者需要時展開。
- 不應為了完整而讓每個結果都變成冗長報告；內容必須與輸入和情境相關。

### Provider 一致性與選擇

- Codex CLI 與 OpenAI API 必須產生同一份產品層級的結構化結果契約。
- Provider 選擇必須由使用者明確決定；設定錯誤、未安裝、未登入、憑證缺失或執行失敗時不得靜默改用另一個 Provider。
- 分析操作應支援處理中、成功、失敗、取消與重試等真實狀態。
- 結果需保留足以辨識其來源的 Provider 資訊，但不向一般資料庫暴露 credential。

### 安全與後續資料相容性

- OpenAI credential 必須放在 OS secure storage，而不是一般 App 資料或 History 資料庫。
- 統一結果契約需有版本概念，讓已保存的學習紀錄與 Cache 能判斷是否仍相容。
- 分析失敗、取消、Preview 或過期結果不可被當成完整可保存的學習結果。

## 不在本功能範圍

- Recent History／Favorite 的持久化與保留政策本身；此功能只提供可供 F-001 正確保存的完整結果。
- Cache-First 判斷、快取保存與快取清除。
- 多帳號、provider 自動 failover、custom endpoint 或 cost routing。
- 完整複習系統、學習成效分析或 TTS。
- 未取得額外授權的 live paid API 呼叫。

## 建議開發與整合順序

1. PM 確認 Reading／Expression 的使用者結果、Provider 選擇規則、失敗文案與驗收情境。
2. Luke 先凍結統一結果 schema、Reading／Expression typed model、Provider 介面、schema version 與 typed errors。
3. Ethan 依契約實作 Provider adapter、credential boundary 與結果轉換；同時 Eason 可用 deterministic fake Provider 建立分析流程。
4. Eason 實作模式判斷、Provider 選擇、處理中、成功、失敗、取消與重試的 Application states；Joe 依 state 製作分層結果與錯誤畫面。
5. Ethan 的 adapter 與 Eason 的流程接線，驗證同一產品契約在不同 Provider 下均成立。
6. Joe 完成 Widget／semantics 驗證；PM 依兩種分析情境及 Provider 失敗情境驗收。

## 與前後功能的交接

- F-002 接收使用者輸入、mode 與明確選定的 Provider，產生統一且版本化的 Reading／
  Expression typed result。
- 只有完整、通過驗證且仍屬於目前 request 的結果，才交給 F-001 的唯一保存入口；
  Preview、失敗、取消或 stale result 不得保存。
- F-003 日後在 F-002 的 Provider execution 前加入 Cache-First，但 Cache hit 仍回傳同一
  typed result，不改變 F-002 UI 或 F-001 保存方式。
- F-004／F-005 可沿用結構化的單字、片語、文法、語氣與情境；F-006 可直接呼叫 F-002
  分析 command；F-007 可辨識其中的英文內容進行播放。

## 四位 Owner 的責任與交付

### Luke／Domain Owner

- 定義共用 result envelope，以及 Reading／Expression 各自需要的 typed fields、schema
  version、Provider identity 與相容性原則。
- 定義 Provider、request、optional Preview、cancellation 與 typed failures 的邊界，並保留
  F-001 保存、F-003 fingerprint 及後續學習／TTS 所需資訊。
- 提供 serialization、validation、Domain tests 與契約說明；不處理 CLI、HTTP、secure
  storage、History DB 或 Widget。

### Ethan／Infrastructure Owner

- 依 Luke 的契約實作 deterministic Fake、Codex CLI 與 OpenAI adapters，以及必要的
  prompt／structured-output mapping、credential boundary、timeout 與 cancellation。
- 確保 Provider 不可用或輸出不合法時回傳正確 failure，不靜默切換 Provider，也不將
  credential、raw input／output、完整 prompt 或 private log 寫入一般資料。
- 提供共用 Provider contract tests、failure-mapping tests、資源 cleanup 與平台驗證；
  未授權的 live paid call 如實標示未執行。

### Eason／Application Owner

- 實作輸入、mode suggestion／manual override、Provider selection、submit、cancel、retry
  與 latest-request-wins，並向 Joe 提供穩定的 UI states。
- 將合法 full result 交給 F-001 一次；將 persistence 狀態與 analysis 狀態分開，並預留
  F-003 可以插入 Cache-First 的單一 execution seam。
- 使用 Fake 與 Ethan adapters 提供 Application／integration／race／cancel tests，確保舊
  request、Preview、failure 或取消結果不會更新目前 UI 或進入 History。

### Joe／Presentation Owner

- 製作輸入、mode／Provider 操作、Reading／Expression 分層結果、loading、Preview、
  success、failure、cancel、retry，以及 Provider Settings／credential 狀態。
- 沿用 F-001 既有 persistence／Favorite actions，並讓 typed English content 可供未來
  F-007 使用；不提前實作 Cache、Review 或 TTS。
- 完成 responsive、長內容、keyboard、focus、Semantics 與 Widget tests；不直接呼叫
  Provider、CLI、HTTP、secure storage、History Repository 或 Cache。
