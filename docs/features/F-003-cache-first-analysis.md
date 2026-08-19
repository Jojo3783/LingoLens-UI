# F-003：Cache-First 分析體驗

- 狀態：`DRAFT`
- 建立日期：`2026-08-15`
- PM：Jimmy
- 優先級：`P0`
- 關聯 task／PR：尚未建立
- Implementation authorization：`NOT_AUTHORIZED_BY_THIS_DOCUMENT`

## 功能願景

使用者再次分析相同內容時，不應無必要地重新等待 AI、消耗 Provider 資源，或得到
不一致的結果。LingoLens 應優先安全地重用仍然有效的分析結果，讓即時理解感覺更快
且更可靠。

但 Cache 是系統的效能機制，不是使用者的學習紀錄。它不得取代 Recent History 或
Favorites，也不得讓使用者誤以為清除其中一方會改變另一方。依 F-001，完整成功的
分析會自動進入最近 20 筆 History；只有使用者加上星號的內容才是永久 Favorite。

## 邏輯流程

### Cache-First 分析流程

```text
使用者發起分析
  ↓
建立 Cache Key
  └─ 輸入內容、語言方向、分析模式、schema 版本、Provider、model
  ↓
檢查 Cache
  │
  ├─ 命中且仍有效
  │    └─ 直接顯示既有完整分析結果，不呼叫 Provider
  │         ↓
  │       若使用者啟用 Recent History 寫入，自動保留最近 20 筆
  │         └─ 使用者可加星成為永久 Favorite
  │
  └─ 未命中／已過期／條件不同
       ↓
     呼叫使用者選定的 Provider
       │
       ├─ 成功且結果完整
       │    ├─ 顯示分析結果
       │    ├─ 寫入 Cache，供後續相同條件重用
       │    └─ 若使用者啟用 Recent History 寫入，自動保留最近 20 筆
       │         └─ 使用者可加星成為永久 Favorite
       │
       ├─ 取消／失敗／結果不完整／舊請求
       │    └─ 不寫入 Cache，也不寫入 Recent History
       │
       └─ Cache 寫入失敗
            └─ 分析結果仍可顯示；如 History 寫入成功，仍依 F-001 保留最近紀錄
```

### Cache 與個人學習記憶的關係

```text
Cache
  ├─ 目標：加速相同條件下的分析
  ├─ 有效期限、容量上限與獨立清理規則
  └─ 使用者可停用或清除

Recent History
  ├─ 目標：顯示最近 20 筆完整成功的查詢
  └─ 超過上限時淘汰最舊紀錄

Favorites
  ├─ 目標：永久保留使用者加星的學習內容
  └─ 不受 Recent History 上限影響

清除 Cache ↔ 不影響 History／Favorites
清除 History／Favorites ↔ 不影響 Cache
```

## 使用者價值

- 重複查詢能更快顯示結果，減少等待。
- 同一個分析設定下，可重用已驗證的結果，降低不必要的 Provider 呼叫。
- 啟用 Recent History 寫入時，完整成功的查詢會依 F-001 自動保留在最近 20 筆 History；使用者仍可決定哪些內容要加星永久保存。
- 有清楚的隱私控制，不必擔心 Cache 與 Favorites 混在一起。

## 重要實作細項

### Cache-First 流程

- 每次分析都先檢查是否存在可用 Cache；只有未命中或快取無效時才呼叫 Provider。
- Provider 成功產生完整結果後，才可以寫入 Cache。
- Cache 命中時，使用者仍看到正常的分析結果；啟用 Recent History 寫入時，完整結果依 F-001 自動保留最多 20 筆 Recent History。
- 分析取消、失敗、不完整、過期或屬於舊請求的結果不得寫入 Cache 或 Recent History。

### 正確性與相容性

- Cache 必須區分輸入內容、語言方向、分析模式、結果 schema 版本、Provider 與 model 等會影響結果的條件。
- 改變上述條件時不可錯用舊 Cache。
- Cache 需要明確的有效期限與容量／清理規則，避免無限制累積過時內容。
- Cache 讀取或寫入失敗不能抹除已成功產生的分析結果；系統應能誠實處理而不造成假成功。

### 隱私與使用者控制

- Cache 與 History／Favorites 必須使用獨立的資料生命週期與管理方式。
- 使用者應能理解 Cache 的用途，並能停用或清除 Cache。
- Cache 不得保存 API key、Authorization header、raw HTTP response、完整 prompt、telemetry 或 private log。
- 清除 History 不應意外代表清除 Cache，反之亦然；兩者的關係必須清楚可預期。

### 與學習體驗的關係

- Cache 的目標是降低等待，不是自動替使用者決定哪些內容值得學習。
- 啟用 Recent History 寫入時，Cache 命中的完整結果同樣會依 F-001 進入 Recent History；使用者加星後才成為永久 Favorite。
- 日後 Review 與學習分析只應使用 Favorite 等使用者主動永久保留的學習資料，不應把 Cache 或單純 Recent History 當作學習行為。

## 不在本功能範圍

- Recent History、Favorites 或加星永久保留流程本身。
- Codex CLI／OpenAI API 的內容格式、憑證管理或 Provider 選擇介面。
- 自動複習、學習狀態分析、推薦或進階個人化。
- 雲端 Cache、多裝置同步或跨帳號共用 Cache。

## 建議開發與整合順序

1. PM 確認 Cache 的使用者控制、有效期限、容量／清理原則，以及 Cache 與 Recent History／Favorites 完全分離的驗收情境。
2. Luke 先凍結 Cache Key 組成、有效性、Cache Repository 介面、相容性規則與 typed cache failure。
3. Ethan 依契約實作本機 Cache schema、TTL、容量清理、讀寫與錯誤映射；同時 Eason 可用 fake Cache 實作 Cache-First use case。
4. Eason 實作命中、未命中、過期、寫入失敗與取消／舊請求 guards，並與 F-001 的 Recent History 寫入規則接線；Joe 同步製作必要的 Cache 設定與說明狀態。
5. 以 Ethan 的真實 Cache 替換 fake Cache，完成 key 隔離、TTL、清除獨立性與 provider-call 避免的整合測試。
6. Joe 驗證使用者可理解 Cache 狀態與清除效果；PM 驗收命中、失效、關閉與分離清除情境。

## 四位 Owner 的責任與交付

### Luke／Domain Owner

- 定義 Cache Key、有效性與相容性規則、Cache Repository 介面及讀寫失敗的 typed error。
- 確保 Cache 不被 Domain 視為學習紀錄；不決定資料表、TTL 實作或 UI。

### Ethan／Infrastructure Owner

- 實作 Cache 持久化、TTL、容量清理、key 查詢與 Cache／History 分離的實際資料機制。
- 確保不保存 credential、raw response 等禁止資料，並提供 Infrastructure tests。

### Eason／Application Owner

- 實作先查 Cache、未命中才呼叫 Provider、完整結果才寫入，以及 stale／cancel 不寫入的流程。
- 負責將結果依 F-001 寫入 Recent History 的時機與隱私開關正確接線，並提供整合測試。

### Joe／Presentation Owner

- 呈現 Cache 用途、啟用／停用與清除操作，以及必要成功／失敗狀態。
- 不顯示或操作底層 key、資料表與 Provider transport；完成 Widget／semantics tests。
