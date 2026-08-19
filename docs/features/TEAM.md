# Team Responsibilities

這份文件定義 LingoLens 五位成員的固定責任。每一份功能規格書再依功能內容，
列出各人的本次工作與交付成果。

## PM／Product Owner

### 負責

- 整理功能清單、優先順序與開發範圍。
- 說明使用者問題、使用情境與預期操作流程。
- 決定產品規則，例如儲存、刪除、Favorite、History 上限與隱私行為。
- 定義成功、失敗、空白與其他需要驗收的情境。
- 確認功能規格書，處理團隊提出的產品問題。
- 依驗收條件執行最終功能驗收。

### 交付成果

- 功能目標與優先級。
- 功能範圍與不在範圍。
- 使用者流程與產品規則。
- 可實際操作的驗收條件。
- 是否同意功能進入開發或通過驗收的決定。

### 不負責

- 決定資料庫、Flutter 元件、Controller 或外部服務的技術實作。
- 代替各層 Owner 撰寫其技術契約與測試方案。

## Joe／Presentation Owner

### 負責

- UI/UX、頁面、導覽、元件與視覺一致性。
- 按鈕、表單、Dialog、提示訊息與使用者互動。
- Loading、Empty、Success、Failure、Disabled 等畫面狀態。
- 響應式版面、鍵盤操作、Focus、Semantics 與基本無障礙。
- 向 Eason 說明畫面需要哪些狀態、資料與操作。
- Presentation 與 Widget tests。

### 交付成果

- 可操作且符合規格的頁面與共用元件。
- 完整的正常、載入、空白、錯誤與停用狀態。
- Widget tests 與必要的畫面驗證證據。
- 提供給 Eason 的 UI state 與 action 需求清單。

### 不負責

- 在 Widget 中直接讀寫 DB、呼叫 AI Provider 或平台原生 API。
- 自行改變產品規則、Domain 契約或資料保存行為。

## Eason／Application Owner

### 負責

- 使用者操作後的完整 Application 流程。
- Controller、use case、狀態管理與狀態轉換。
- 串接 Presentation、Domain 與 Infrastructure。
- Loading、Success、Failure、Cancel、Retry 與重複操作處理。
- 非同步競態、stale result 與 latest-request-wins。
- 定義 Joe 可使用的 UI commands 與 states。
- Application tests、跨層整合測試與端到端整合。

### 交付成果

- 清楚且可測試的 Application commands。
- 穩定的 UI state 與錯誤狀態。
- 完整的成功、失敗、取消與重試流程。
- Application／integration tests。
- 可交給 PM 驗收的端到端功能。

### 不負責

- 直接撰寫 SQL 或讓 UI 依賴 Infrastructure 實作細節。
- 自行改變 PM 的產品規則或繞過 Luke 的 Domain 契約。

## Luke／Domain Owner

### 負責

- Domain models、資料欄位意義與 value objects。
- 不依賴 UI、DB 或外部服務的業務規則與資料驗證。
- Repository、Provider 與 Service interfaces。
- Typed errors、資料關係與不可被破壞的規則。
- 與 Eason、Ethan 確認契約是否足以支援流程與技術實作。
- Domain tests 與 Domain 契約審查。

### 交付成果

- 資料模型與欄位說明。
- Repository／Provider／Service 契約。
- 成功、失敗與邊界情境的規則。
- Domain tests。
- 供 Joe、Eason、Ethan 使用的簡短契約說明。

### 不負責

- Flutter UI、SQL、HTTP client 或平台原生實作。
- 未經 PM 確認自行改變產品行為。
- 為特定畫面或資料庫技術改變 Domain 的資料意義。

## Ethan／Infrastructure Owner

### 負責

- 本機 DB、schema、migration、索引與 transaction。
- Repository 的實際資料讀寫實作。
- Domain model 與 DB record 的轉換。
- 外部技術 adapter，例如 Provider transport、secure storage 與平台服務。
- 資料一致性、持久化、錯誤映射與效能風險。
- Infrastructure tests 與重開 App／DB 後的資料驗證。
- 目前階段以本機資料與 DB Infrastructure 為主要責任；其他 adapter 變更須與 Luke、Eason 對齊。

### 交付成果

- 可由 Application 注入使用的 Repository／adapter。
- DB schema、migration 與 transaction 實作。
- 讀取、寫入、更新、刪除與失敗處理測試。
- 持久化與 migration 驗證結果。
- 已知技術限制、風險與後續維護說明。

### 不負責

- 自行改變資料的產品意義、保存規則或使用者流程。
- 讓 Presentation 或 Application 直接依賴 SQL、資料表或 credential。
- 因 DB 實作方便而要求 Domain 契約配合特定 schema。

## 共同邊界

- 每個人主要維護自己的層；因功能需要跨層修改時，須由該層 Owner review。
- 跨層功能開始前，功能規格書必須列明各人的工作、交付成果、依賴與驗收條件。
- Domain 契約變更由 Luke 負責，並與直接依賴的 Eason、Ethan 對齊。
- 跨層流程由 Eason 負責整合，PM 負責產品驗收。
- AI 只能在明確任務範圍內修改檔案；需要改變產品規則、契約或其他層時，先提出問題。
