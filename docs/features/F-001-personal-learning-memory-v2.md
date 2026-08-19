# F-001：個人學習記憶

- 狀態：`FORMAL_IMPLEMENTATION_SPEC`
- 建立日期：`2026-08-15`
- PM：Jimmy
- 優先級：`P0`
- 關聯 task／PR：尚未建立
- Implementation authorization：`NOT_AUTHORIZED_BY_THIS_DOCUMENT`
- 說明：此為正式實作規格；此狀態僅凍結產品規則與跨層交接，不構成新的 production implementation authorization。

## 功能願景

LingoLens 應讓使用者快速找回最近查過的內容，但不會把所有查詢都變成永久學習紀
錄。每一次完整成功的分析會自動保留在本機 Recent History；History 只顯示最近 20
筆。使用者在閱讀文章、處理工作文字或練習英文時，可把真正重要的內容加上星號，
成為不受 History 上限影響的永久 Favorite。

這個功能將即時分析分為兩種保存層級：Recent History 是最近 20 筆查詢的短期紀錄，
超過上限時會由最舊資料淘汰；Favorite 是使用者明確保留的長期學習素材，可在未來
回顧與複習。

## 邏輯流程

### 自動 Recent History 與收藏

```text
即時分析完成
  │
  ├─ 取消／失敗／結果不完整／已過期
  │    └─ 僅顯示當前狀態，不寫入 History，也不可收藏
  │
  └─ 完整成功結果
       │
       ├─ 自動寫入 Recent History
            ├─ 有唯一 ID、輸入文字、模式、結果、建立時間、favorite=false
            ├─ 保留最近 20 筆查詢紀錄
            └─ 超過 20 筆時，淘汰最舊的 Recent History 紀錄
       │
       └─ 點「加入 Favorite」
            └─ 原子操作：將同一筆 Recent History 紀錄設為 favorite=true
                 ├─ 成功：寫入 favoritedAt、History 保留該紀錄，並讓它出現在 Favorites
                 ├─ Favorite 不受 Recent History 20 筆上限影響
                 └─ 任一步失敗：畫面不可顯示成功，資料維持原狀
```

### 儲存後操作關係

```text
同一筆已完成的查詢紀錄
  │
  ├─ 收藏
  │    └─ 設為永久 Favorite；保留 History 紀錄，並出現在 Favorites
  │
  ├─ 取消收藏
  │    └─ 從 Favorites 移除，回到 Recent History 保留規則
  │         └─ 若原查詢已不在最近 20 筆，則不再保留
  │
  ├─ 刪除
  │    └─ 從 History 刪除；若已收藏，也同步從 Favorites 移除
  │
  └─ History 達可見上限
       └─ 淘汰最舊 Recent History 紀錄；Favorite 不得因此自動刪除
```

Favorites 不是第二份重複資料，而是同一筆查詢紀錄的 `favorite` 狀態與永久保留政策。

## 使用者價值

- 使用者能快速找回最近 20 次完整成功的查詢。
- 使用者不必擔心未收藏的查詢會無限制地永久累積。
- 真正有價值的英文內容可透過 Favorite 在關閉 App 後持續保留。
- Favorites 是使用者挑選出的重點，不是另一份重複資料。
- 日後的 Review 與學習狀態，只會建立在使用者願意留下的內容之上。

## 重要實作細項

### Recent History 與收藏

- 只有完整成功的分析結果可以寫入 Recent History；取消、失敗、不完整或過期結果不可保存。
- 每次成功查詢自動保留為 Recent History；History 只顯示最近 20 筆查詢紀錄。
- 使用者可將目前結果或 Recent History 項目加入 Favorite；收藏為原子操作，不可留下不一致資料。
- 同一個查詢結果的重複 UI 操作不可建立重複紀錄；使用者重新發起的獨立查詢則是新的紀錄。
- Favorite 是同一筆紀錄的永久保留狀態，不受 Recent History 20 筆上限影響。

### History、Favorites 與刪除

- History 顯示最近 20 筆查詢；Favorites 只顯示已收藏的同一批紀錄，並可保留已退出 Recent History 的收藏項目。
- 超過 20 筆時，淘汰最舊 Recent History 紀錄；Favorite 不得因為 History 上限而被自動刪除。
- 取消 Favorite 會移除永久保留狀態；若該紀錄已不在最近 20 筆，則同步移除該紀錄。
- 刪除任一紀錄時，若它已收藏，相關 Favorite 必須同步移除。

### 本機持久化與資料完整性

- Recent History 與 Favorite 紀錄需要穩定唯一 ID、原始輸入、分析模式、可重建的分析結果、建立時間、收藏狀態，以及收藏時的 `favoritedAt`。
- 關閉並重開 App 後，History 與 Favorites 狀態必須一致。
- 儲存、收藏、取消收藏與刪除失敗時，畫面不得顯示假成功，資料也不得進入不一致狀態。
- History 與 Favorites 應支援單筆更新，不應因單一操作而整頁重新載入或跳動。

### 隱私邊界

- 只有完整成功的分析結果可自動寫入最多 20 筆的 Recent History；使用者可在設定中關閉新的 Recent History 寫入。
- 一般本機資料庫不得保存 API key、Authorization header、raw HTTP response、完整 prompt、telemetry 或 private log。
- History／Favorites 與系統 Cache 必須是兩套獨立資料；清除或調整其中一方不得意外改變另一方。

## 不在本功能範圍

- 搜尋、標籤、資料夾、匯出、雲端同步或多人共享。
- 快取命中、快取期限與 Cache 清除策略。
- 複習排程、學習成效分析、TTS 或新增 AI Provider。

## 建議開發與整合順序

1. PM 確認 Recent History 20 筆上限、Favorite 永久保留、取消收藏與刪除的產品規則及驗收情境。
2. Luke 先凍結 `HistoryRecord`／Favorite 的 Domain 契約、`favoritedAt`、保留與淘汰規則、Repository 介面及 typed failure。
3. Ethan 依契約設計本機資料 schema、migration、查詢與原子收藏／刪除交易；同時 Eason 可使用 fake Repository 建立 Application commands 與 state。
4. Eason 將完整成功分析、Recent History、收藏、取消收藏與刪除串成 use case；Joe 依已凍結的 UI state 製作結果頁、History 與 Favorites 畫面。
5. Ethan 的真實 Repository 交給 Eason 接線，完成跨層整合、重開 App 與失敗回復測試。
6. Joe 完成 Widget／semantics／畫面狀態驗證；PM 依 Recent History 淘汰、收藏保留、刪除與隱私情境驗收。

## 與後續功能的交接

- F-001 完成後應提供一個清楚的 Application 入口，接收「目前完整成功分析」並依本
  規格寫入 Recent History；實際 command／class 名稱由團隊決定。
- F-002 只需要交付完整 typed result、查詢識別與 Provider 資訊，不需知道 F-001 的 DB
  或淘汰實作。
- F-003 的 Cache hit 和 Provider success 最後都走同一個 F-001 保存入口，避免出現兩套
  History 規則。
- F-004／F-005 只使用永久 Favorite；F-001 要保留可靠的 `favoritedAt` 與完整結果，
  但不提前實作 Review 或個人化素材。

## 四位 Owner 的責任與交付

### Luke／Domain Owner

- 定義 History record、Favorite、`favoritedAt`、最近 20 筆、淘汰、取消收藏與刪除的
  資料意義及不可破壞的規則。
- 提供 Repository contracts、必要的 typed persistence failures，以及能接收 F-002 完整
  typed result 的保存邊界；具體 API 命名可與 Eason、Ethan 討論。
- 提供 Domain tests 與契約說明；不決定 DB schema、transaction 技術或 UI 呈現。

### Ethan／Infrastructure Owner

- 依 Luke 的契約選擇並實作合適的本機持久化、schema、migration、索引與 Repository
  adapter，讓 Windows／macOS 重開 App 後仍能讀回資料。
- 確保新增、Recent cleanup、Favorite、取消收藏與刪除具備必要的原子性，並維持
  History／Favorites 與 Cache 分離。
- 提供 Infrastructure／migration／reopen／failure tests 與平台限制說明；不得把
  credential、raw response、完整 prompt 或 private log 寫入一般 DB。

### Eason／Application Owner

- 將 F-002 的完整成功結果與未來 F-003 Cache hit 接到 F-001 唯一保存流程，並處理
  History 寫入開關、Favorite、取消收藏、刪除、載入與重試。
- 管理重複操作、同次查詢去重、stale／late completion、單筆 mutation 及 success／failure
  UI states；寫入失敗不得改變分析本身的成功結果。
- 使用 fake 與 Ethan 的真實 Repository 提供 Application／integration tests，並把穩定的
  commands、states 與錯誤狀態交給 Joe。

### Joe／Presentation Owner

- 製作分析結果中的 Recent History／Favorite 狀態、History、Favorites、刪除確認及
  Settings 寫入開關，並讓兩個列表共用同一紀錄元件。
- 呈現 loading、empty、success、disabled、單筆處理中與 failure／retry；單筆更新不應
  造成整頁 reload、selection 消失或列表跳動。
- 完成 responsive、keyboard、focus、Semantics 與 Widget tests；不直接呼叫 Repository、
  DB、Cache 或 Provider。
