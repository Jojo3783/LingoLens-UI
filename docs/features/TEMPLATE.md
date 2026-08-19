# 功能規格書模板與填寫指南

這份模板用來建立新的功能規格書。複製本檔並改名，例如：

```text
F-002-cache-first-analysis.md
```

規格書分成兩個閱讀層次：

1. 前半部先讓人理解「為什麼要做、使用者會怎麼使用」。
2. 後半部再把規則、分工、交付成果、限制與驗收寫清楚，供團隊和 AI 執行。

填寫時請把所有「填寫說明」和「簡短範例」替換成該功能的實際內容。若尚未決定，
不要自行猜測，請放到「待確認事項」。

---

# F-XXX：功能名稱

- 狀態：`DRAFT`
- 建立日期：`YYYY-MM-DD`
- PM：
- 優先級：`P0／P1／P2`
- 關聯 task／PR：尚未建立
- Implementation authorization：`NOT_AUTHORIZED_BY_THIS_DOCUMENT`

> 填寫說明：功能名稱應描述使用者能完成的事情，而不是按鈕或技術名稱。
> 例如使用「手動儲存與加入最愛」，不要只寫「Save Button」或「SQLite」。

## 功能願景

> 填寫者：PM。請先用幾段自然語言說明使用者遇到的問題、產品希望帶來的改變，
> 以及完成後的整體體驗。這一段是讓所有人先理解全貌，不需要寫 class、table 或 API。

建議回答：

- 使用者目前遇到什麼問題？
- 為什麼值得現在解決？
- 功能完成後，使用者會感受到什麼改變？
- 這個功能最重要的產品原則是什麼？

簡短範例：

> 分析結果目前只存在本次工作階段。使用者希望自行決定哪些結果值得保留，並在
> 重開 App 後繼續查看。產品不會自動永久保存所有分析，而是在使用者按下儲存或
> 加入最愛後，才將資料寫入本機。

## 目前狀態與目標差異

> 填寫者：PM 主導，四位 Owner 協助確認。分開寫「現在已經有什麼」和「本功能完成
> 後應變成什麼」，避免 AI 重做既有功能或誤以為畫面已經等於完整實作。

### 目前狀態

- （目前已有的畫面、流程、資料或限制）

### 目標狀態

```text
使用者觸發功能
→ 系統執行主要處理
→ 使用者看到成功結果
→ 必要資料正確更新或保存
```

## 名詞定義

> 填寫者：PM 與 Luke。只列本功能容易產生不同理解的名詞，並給出一致定義。
> 若沒有特殊名詞，可寫「無」。

- **名詞 A**：它在本功能中代表什麼。
- **名詞 B**：它與其他資料或狀態的差異。

簡短範例：

- **已儲存紀錄**：已成功寫入本機 DB、具有穩定 ID 的完整分析結果。
- **Favorite**：已儲存紀錄的收藏狀態，不是另一份重複內容。

## 功能範圍

> 填寫者：PM。列出本輪確定會交付的使用者能力。每一點都應能在最後被驗收，
> 不要把技術研究或可能順便做的事情混進來。

- 使用者可以……
- 系統會……
- 發生失敗時……
- 重新開啟 App 後……

## 不在範圍

> 填寫者：PM。明確列出這一輪不做的相鄰功能，防止團隊或 AI 自行擴大範圍。

- 本輪不做……
- 本輪不修改……
- 本輪不新增……

簡短範例：

- 不自動儲存所有分析。
- 不包含 History 搜尋、匯出或雲端同步。
- 不改變 AI Provider 或分析結果 schema。

## 使用者流程

> 填寫者：PM 主導，Eason 補充系統狀態。每一條重要路徑分開寫，至少包括正常流程、
> 失敗流程，以及取消／刪除等會改變資料的流程。先用使用者看得懂的語言，不要先寫
> Controller 或 SQL。

### 流程 A：主要成功流程

```text
使用者在哪個畫面做什麼
→ 畫面顯示處理中
→ 系統完成什麼操作
→ 畫面顯示什麼成功結果
→ 資料發生什麼改變
```

### 流程 B：失敗流程

```text
操作開始
→ 系統處理失敗
→ 畫面保留操作前的真實狀態
→ 顯示可理解的錯誤
→ 使用者可以重試或離開
```

### 流程 C：取消／刪除流程

```text
使用者要求取消或刪除
→ 必要時顯示確認
→ 確認後才修改資料
→ 取消確認時不修改任何資料
```

## 產品規則與不變條件

> 填寫者：PM 決定產品規則，Luke 將其轉成 Domain 規則。這裡要寫「任何實作都不可
> 違反的結果」，不要指定資料表或 Widget 寫法。

1. 什麼條件下允許執行此功能？
2. 什麼資料可以或不可以保存？
3. 重複操作應如何處理？
4. 失敗時資料與 UI 應維持什麼狀態？
5. 刪除、取消或關閉 App 後應發生什麼？
6. 是否有隱私、數量、時間或平台限制？

簡短範例：

1. 只有完整成功的分析結果可以儲存。
2. 重複按儲存不得建立重複紀錄。
3. 儲存失敗時 UI 不得顯示「已儲存」。

## 資料需求

> 填寫者：PM 說明產品需要保存或顯示的資訊；Luke 定義正式資料意義；Ethan 在契約
> 確認後設計 schema。這裡不直接指定 table、column 或 DB 技術。

需要的資料：

- （例如：唯一 ID、內容、狀態、建立時間）

禁止保存的資料：

- （例如：API key、Authorization header、private log）

資料生命週期：

- 何時建立：
- 何時更新：
- 何時刪除：
- 重開 App 後是否保留：

## 畫面與狀態需求

> 填寫者：PM 描述使用者應看到的結果；Joe 提出具體 UI；Eason 提供真實狀態來源。
> 請列出所有會影響按鈕、文案或列表的狀態，不只描述成功畫面。

| 狀態 | 畫面應顯示 | 使用者可以做什麼 |
| --- | --- | --- |
| 初始 | （待填） | （待填） |
| 處理中 | （待填） | 不可重複提交 |
| 成功 | （待填） | （待填） |
| 失敗 | 保留真實狀態並顯示錯誤 | 可重試或離開 |
| 空白 | （待填） | （待填） |

如有多個頁面，請分別說明：

- 頁面 A：
- 頁面 B：

## 四人工作分配

> 這一節是每位 Owner 與其 AI 的直接工作依據。每個人都要列出「工作、交付成果、
> 測試、限制、依賴」。不要只寫「負責前端」或「負責 DB」。

### Luke／Domain Owner

#### 工作

- 需要新增或調整哪些資料模型、規則與 Repository／Service contracts？
- 需要定義哪些 typed errors 與不變條件？
- 需要和 Eason、Ethan 對齊哪些契約？

#### 交付成果

- Domain models／contracts。
- 契約說明：輸入、輸出、錯誤與邊界情境。
- Domain unit tests。
- 給 Ethan 與 Eason 的交接說明。

#### 必測情境

- [ ] 正常資料符合規則。
- [ ] 無效資料被拒絕。
- [ ] 邊界與錯誤行為符合規格。

#### 限制

- 不修改 UI、SQL、HTTP client 或平台實作。
- 不自行改變 PM 已確認的產品規則。

#### 依賴

- 需要 PM 確認：
- 需要 Eason／Ethan review：

### Ethan／Infrastructure Owner

#### 工作

- 需要實作哪些 Repository、DB、migration、transaction 或 adapter？
- 如何將 Domain model 轉換成實際儲存或外部服務格式？
- 失敗如何映射成 Luke 定義的 typed error？

#### 交付成果

- 可注入 Application 的 Repository／adapter。
- Schema、migration、transaction 或技術實作說明。
- Infrastructure tests 與實際驗證結果。
- 已知技術限制與風險。

#### 必測情境

- [ ] 讀取、寫入、更新與刪除正確。
- [ ] 失敗時不留下不一致資料。
- [ ] 重開 App／DB 或 migration 後資料仍符合規格。

#### 限制

- 不自行改變 Domain 契約、產品規則或 UI 行為。
- 不讓上層直接依賴 SQL、table model、credential 或 adapter 細節。

#### 依賴

- 需要 Luke 提供：
- 需要 Eason 確認：

### Eason／Application Owner

#### 工作

- UI 需要呼叫哪些 commands？
- 需要提供哪些 UI states？
- 成功、失敗、取消、重試、重複點擊和競態如何處理？
- 如何串接 Luke 的 contracts 與 Ethan 的 Repository／adapter？

#### 交付成果

- 可測試的 Application commands 與 UI states。
- 完整的使用者流程與錯誤處理。
- Application／integration tests。
- 可交給 Joe 串接及 PM 驗收的整合版本。

#### 必測情境

- [ ] 成功後才更新 UI state。
- [ ] 失敗或取消時不顯示假成功。
- [ ] 重複操作與 late completion 不破壞目前狀態。

#### 限制

- 不直接寫 SQL，不讓 Widget 直接使用 Infrastructure。
- 不繞過 Luke contract 或自行改變 PM 規則。

#### 依賴

- 需要 Luke 提供：
- 需要 Ethan 提供：
- 需要 Joe 確認：

### Joe／Presentation Owner

#### 工作

- 哪些頁面、元件與互動需要新增或修改？
- Loading、Empty、Success、Failure、Disabled 如何呈現？
- 需要 Eason 提供哪些 commands 與 states？
- 響應式、鍵盤、Focus、Semantics 如何處理？

#### 交付成果

- 可操作的頁面與共用元件。
- 完整的畫面狀態與使用者提示。
- Widget／semantics tests。
- 主要畫面截圖與人工互動檢查結果。

#### 必測情境

- [ ] 正常、處理中、空白與錯誤狀態正確顯示。
- [ ] 使用者操作呼叫正確的 Application command。
- [ ] 寫入失敗時不顯示假成功。

#### 限制

- 不直接呼叫 Repository、DB、Provider 或平台 API。
- 不自行推測成功狀態或改變產品／Domain 規則。

#### 依賴

- 需要 PM 確認：
- 需要 Eason 提供：

## 依賴與開發順序

> 填寫者：四位 Owner 共同確認。寫出誰的成果是誰的前置條件，以及哪些工作可以並行。

```text
PM 確認產品規則與 implementation authorization
→ Luke 提出 Domain contract
→ Eason、Ethan review 並鎖定 contract
→ Ethan 實作 Infrastructure
→ Eason 串接 Application 流程
→ Joe 串接真實 states／commands
→ 四層測試與整合
→ PM 驗收
```

可並行工作：

- Joe 可以先……，但必須等待……才能正式串接。
- Ethan 可以先……，但必須等待……才能鎖定 schema／adapter。
- Eason 可以先……，但必須等待……才能完成整合。

## 各層交接

| 交接者 | 接收者 | 必須提供 |
| --- | --- | --- |
| Luke | Ethan | Models、Repository contracts、errors 與資料規則 |
| Luke | Eason | Application 需要遵守的業務規則與錯誤 contract |
| Ethan | Eason | 可注入的實作、初始化方式、failure mapping 與限制 |
| Eason | Joe | UI commands、states、mutation lifecycle 與錯誤狀態 |
| Eason | PM | 已整合功能、測試結果、限制與可驗收版本 |

## 最終驗收條件

> 填寫者：PM。每一條都要是 PM 可以實際操作或觀察的結果。不要只寫「功能正常」或
> 「測試通過」。建議同時覆蓋成功、失敗、重開 App、重複操作與刪除／取消情境。

### 驗收 1：主要成功流程

1. 使用者……
2. 系統……
3. 畫面……
4. 預期結果……

### 驗收 2：失敗流程

1. 模擬……失敗。
2. 畫面不得……。
3. 資料必須……。
4. 使用者可以……。

### 驗收 3：重新開啟或邊界情境

1. 完成……。
2. 關閉並重新開啟 App。
3. 預期……。

## Definition of Done

> 這是整個功能完成前的共同檢查表。可依功能刪除不適用項目，但不得把未執行的驗證
> 寫成通過。

- [ ] PM 已確認功能規格、產品規則與驗收條件。
- [ ] 已取得符合治理文件的 implementation authorization。
- [ ] Luke 的 Domain contract 已由直接依賴者 review。
- [ ] Ethan 的 Infrastructure 實作與測試完成。
- [ ] Eason 的 Application／integration tests 完成。
- [ ] Joe 的 Widget／semantics tests 與畫面證據完成。
- [ ] 完整 analyze、test、format 與適用平台 build 有可追溯證據。
- [ ] 未執行項目誠實標示 `NOT_RUN／BLOCKED`。
- [ ] 未提交 credential、private data、local DB 或 private logs。
- [ ] PM 已依驗收流程完成驗收。

## 待確認事項

> 尚未決定、會影響產品規則或技術方向的問題放在這裡，並標明誰負責回答。問題未解決
> 且會改變實作結果時，不得讓 AI 自行選擇。

- [ ] PM：需要決定……
- [ ] Luke：需要提出……
- [ ] Ethan：需要評估……
- [ ] Eason：需要確認……
- [ ] Joe：需要提出……

## 治理限制

本功能規格書不等於 production implementation authorization。開始修改產品程式前，
仍須閱讀 `AGENTS.md`、Root `handoff.md`、`agent_tasks.md` 與相關 accepted ADR，確認
當前 branch、task marker 與授權範圍。若文件互相衝突，必須停止並依治理優先順序處理。
