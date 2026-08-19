# F-004：低壓複習與回想

- 狀態：`DRAFT`
- 建立日期：`2026-08-15`
- PM：Jimmy
- 優先級：`P1`
- 關聯 task／PR：尚未建立
- Implementation authorization：`NOT_AUTHORIZED_BY_THIS_DOCUMENT`

## 功能願景

LingoLens 的複習不是考試、打卡或每日作業，而是讓使用者用很短的時間，重新遇見
自己最近加星、認為重要的英文內容。使用者不需要準備一段完整讀書時間；只要在有
空時回想幾筆內容，就能把一次性的理解逐漸變成記憶與實際語感。

這個功能要讓使用者感覺「我今天不必完成很多，也仍然有在學習」，而不是因為漏掉
複習、答錯或累積待辦而感到壓力。

## 邏輯流程

### 低壓回想流程

```text
使用者在任何頁面點擊「複習」
  ↓
取得最近 10 天內加星的 Favorites
  ├─ 以 `favoritedAt`（加星時間）判斷是否落在 10 天範圍內
  └─ 不使用 Recent History 或 Cache 作為複習來源
  ↓
系統挑選 3～5 筆內容開始 session
  ├─ 少於 3 筆時，顯示所有符合條件的內容
  └─ 沒有符合條件時，顯示「最近 10 天沒有可複習的 Favorite」
  ↓
逐筆先想、再揭示
  ├─ Reading：先顯示英文原句或提示
  │    └─ 回想意思、用法或語氣後，再看已保存的翻譯與重點
  │
  └─ Expression：先顯示中文意圖或情境
       └─ 回想英文表達後，再看自然表達與關鍵片語
  ↓
使用者選擇回饋
  ├─ 還不熟 → 較早再次出現
  ├─ 差不多了 → 以正常間隔再次出現
  ├─ 已熟悉 → 拉長下次複習間隔
  └─ 略過／結束 → 不扣分、不顯示失敗或待辦壓力
  ↓
更新該 Favorite 的最近複習時間、熟悉度與下次建議複習時間
```

### 與 Recent History／Favorites 的關係

```text
Recent History（最近 20 筆）
  └─ 不自動進入 Review

Favorite（使用者加星的永久內容）
  └─ 加星時間在最近 10 天內時，可直接作為 Review 來源

Review
  ├─ 每次點擊「複習」時即時取得候選內容，不需事先加入
  ├─ 不會重新呼叫 Provider
  └─ 刪除 Favorite 時，同步移除相關複習紀錄與排程
```

## 使用者價值

- 使用者能重新遇見自己最近 10 天內加星的英文，而不是陌生題庫。
- 每次複習量小，隨時可以開始、跳過或結束。
- 使用者先回想再揭示答案，比單純重看 History 更能形成記憶。
- 使用者的回饋會讓之後的複習更貼近自己的熟悉程度。

## 重要實作細項

### 複習內容來源

- 使用者在任何頁面點擊「複習」時，系統直接取得最近 10 天內加星的 Favorite，作為當次 session 的候選內容。
- 複習只使用符合 10 天範圍的 Favorite；不得把 Cache 或 Recent History 的短期查詢自動當成學習素材。
- Favorite 必須保存 `favoritedAt`（加星時間），以便正確判斷 10 天複習範圍。
- Review 不需要事先加入、暫停或停止狀態；每次 session 依當下符合條件的 Favorite 建立。
- 刪除 Favorite 後，該紀錄相關的複習狀態與排程必須一併移除。

### 低壓回想流程

- 使用者可在 Dashboard 或 Review 頁主動開始一個小型複習 session，例如 3～5 筆內容。
- 英文閱讀內容先顯示原句或提示，讓使用者回想意思、用法或語氣，再揭示已保存的翻譯與重點。
- 中文表達內容先顯示中文意圖或情境，讓使用者在心中想出英文，再揭示自然表達與關鍵片語。
- 第一版以「先想、再揭示」為主，不要求打字作答或即時 AI 批改。
- 使用者可以略過某筆、隨時結束 session，系統不得以失敗、扣分或未完成待辦呈現。

### 使用者回饋與簡單排程

- 每筆複習後，使用者可用簡單回饋表達熟悉程度，例如「還不熟」、「差不多了」或「已熟悉」。
- 還不熟的內容應較早再次出現；熟悉的內容則拉長間隔。
- 初始排程規則必須簡單、可理解且可預期，不在第一版追求複雜的記憶模型。
- 系統需要保存複習狀態、最近複習時間、下一次建議複習時間與使用者回饋，供後續學習分析使用。

### 體驗與隱私

- Review 頁需清楚區分「現在可複習」與「最近 10 天沒有可複習的 Favorite」等狀態。
- 複習應使用已保存的分析結果，不應為每一張卡片重新呼叫 Provider。
- 複習紀錄與使用者保存內容屬本機學習資料；不得另行寫入 credential、raw HTTP response、telemetry 或 private log。

## 不在本功能範圍

- AI 即時批改、自由輸入答案評分或口說評分。
- 自動產生新的題目、填空題、選擇題或情境練習。
- 複雜 spaced-repetition 演算法、每日強制任務、streak、XP、排行榜或懲罰機制。
- 推播通知、雲端同步、社群或教師管理功能。

## 建議開發與整合順序

1. PM 確認「最近 10 天加星」的時間邊界、每次 3～5 筆、無內容、略過與三種熟悉度回饋的驗收情境。
2. Luke 先凍結以 `favoritedAt` 篩選候選內容的契約、session 選題規則、Review metadata 與回饋／排程的 Domain 意義。
3. Ethan 實作 Favorite 的 10 天查詢與 Review metadata 持久化；同時 Eason 可用 fake Repository 建立直接開啟 session 的流程。
4. Eason 實作任何頁面開始 Review、候選選取、先想再揭示、略過／結束及回饋更新；Joe 依固定 state 製作 Review 介面。
5. 將真實 Repository 接線，驗證跨重開 App 的回饋資料、刪除 Favorite 時的相關資料清理，以及不呼叫 Provider 的限制。
6. Joe 完成 Widget／semantics／低壓互動驗證；PM 驗收有內容、少於 3 筆、無內容、略過與回饋後再開啟 session 的流程。

## 四位 Owner 的責任與交付

### Luke／Domain Owner

- 定義最近 10 天 Favorite 候選、3～5 筆 session、熟悉度回饋、Review metadata 與刪除連動規則。
- 提供查詢與更新介面、typed errors、Domain tests；不選擇 DB 或定義畫面流程細節。

### Ethan／Infrastructure Owner

- 實作按 `favoritedAt` 查詢 Favorite、Review metadata 的保存與原始 Favorite 刪除時的關聯清理。
- 確保資料重開後一致，且不讓 Review 重新呼叫 Provider；提供 Infrastructure tests。

### Eason／Application Owner

- 實作隨時開始 Review、候選內容挑選、session ownership、揭示答案、回饋、略過與結束狀態。
- 將回饋與最近複習時間寫入 Domain contract，提供 Application／integration tests。

### Joe／Presentation Owner

- 製作從任何入口開始的 Review UI、Reading／Expression 提示、揭示答案、回饋按鈕與無內容狀態。
- 確保略過或結束不呈現扣分／失敗壓力，並完成 Widget／semantics tests。
