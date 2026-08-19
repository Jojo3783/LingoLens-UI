# F-005：生成客製化複習素材

- 狀態：`DRAFT`
- 建立日期：`2026-08-15`
- PM：Jimmy
- 優先級：`P1`
- 關聯 task／PR：尚未建立
- Implementation authorization：`NOT_AUTHORIZED_BY_THIS_DOCUMENT`

## 功能願景

在使用者已累積 Favorite 與低壓複習回饋後，LingoLens 應能辨識使用者真正常遇到、
重視或仍不熟的英文學習點，並把它們轉成貼近使用者原始情境的短小練習素材。

這不是建立一套通用題庫，而是讓使用者自己的閱讀、工作與表達情境，逐漸形成一份
個人化英文練習內容。每一個學習點與練習都應能說明它來自哪些已保存內容，讓使用
者知道自己為什麼正在複習它。

## 邏輯流程

### 個人化素材生成流程

```text
使用者的永久 Favorites + F-004 複習回饋
  ↓
建立個人學習地圖
  ├─ 擷取重要單字、片語、文法、語氣與特殊用法
  ├─ 保留每個學習點的來源 Favorite、原始句子與分析情境
  └─ 不使用 Recent History 或 Cache 作為學習素材來源
  ↓
評估學習優先順序
  ├─ Favorite 的重要性與出現關聯
  ├─ 最近複習時間
  └─ 「還不熟／差不多了／已熟悉」等使用者回饋
  ↓
使用者開啟個人化練習
  ↓
挑選少量最相關的學習單位
  ↓
有可重用且相容的生成素材？
  ├─ 有 → 顯示既有素材
  └─ 沒有 → 告知使用者需生成素材
            ↓
          使用使用者選定的 Provider 生成
            ↓
          驗證素材
            ├─ 有正確答案、說明與必要情境限制
            ├─ 可追溯至學習單位與 Favorite 來源
            └─ 品質不足／生成失敗：不取代既有 Review 內容
  ↓
顯示短小練習
  ├─ 作答後揭示建議答案與說明
  ├─ 跳過
  ├─ 不再練習
  └─ 要求替換
       └─ 只影響該素材，不刪除來源 Favorite 或 History
```

### 資料關係

```text
Favorite
  ↓
學習單位（單字／片語／文法／語氣）
  ↓
生成素材
  ↓
練習結果與素材偏好

每一層保留來源關係；Cache、Recent History、Favorite、Review 與生成素材各自管理。
```

## 使用者價值

- 使用者不只回看舊答案，也能用不同方式練習自己最需要的內容。
- 常出現、常收藏或仍不熟的單字、片語、文法與語氣會得到較多練習機會。
- 練習素材貼近使用者實際遇到的英文，比隨機題庫更有記憶點。
- 使用者可以理解每個練習的來源與目的，保有對個人學習資料的掌控。

## 重要實作細項

### 建立個人學習地圖

- 從使用者永久保留的 Favorite 與 F-004 複習回饋中，整理可複習的學習單位；不得將 Recent History 或 Cache 自動當成學習素材來源。
- 第一版的學習單位以重要單字、片語、文法、語氣與特殊用法為主。
- 學習單位需保留其來源紀錄與例句；不可只留下沒有情境的抽象標籤。
- 優先順序不只依出現次數，也應考慮 Favorite、使用者回饋、最近複習時間與是否仍不熟。

### 生成短小練習素材

- 系統可依選定的學習單位生成短小、明確且可快速完成的練習。
- 練習類型可包含：詞義或情境回想、關鍵字填空、句子改寫、語氣比較、文法辨識與中文情境轉英文表達。
- 每次優先產生少量與使用者目前需求相關的素材，不應一次建立大量題庫或長篇課程。
- 練習可先採「作答後揭示建議答案與說明」的方式；自由文字 AI 評分可留待後續產品決策。

### 品質、可追溯性與控制

- 每一份生成素材都必須連結到其學習單位與 Favorite 來源紀錄，使用者能查看它基於哪些內容。
- 生成內容應保留正確答案、說明與必要的情境限制，避免只有模糊或無法判定的題目。
- 使用者可以跳過、不再練習或要求替換某個素材；這不應刪除原始 History 或 Favorite。
- 生成失敗或結果品質不足時，不得取代既有複習內容或偽裝成已完成的練習。

### Provider、資料與隱私邊界

- 若生成素材需要呼叫 Codex CLI 或 OpenAI API，必須明確告知使用者並遵守其選擇的 Provider 與 credential 邊界。
- 不得在未告知的情況下，把 Recent History、未收藏的臨時輸入、Cache 或其他私密資料送去生成素材。
- 生成素材、其版本與來源關係需與 Cache、Recent History、Favorites 及 Review 狀態分開管理。
- 可重用的生成結果可採取受控快取，但不應自動變成使用者的 History 或 Favorite。

## 不在本功能範圍

- 取代 F-004 的基本低壓回想與熟悉度排程。
- 大型課程、完整教材路徑、教師指派、多人共用題庫或社群競賽。
- 高風險的自動能力評分、正式測驗成績、證照或學習診斷宣稱。
- 未取得額外授權的 live paid API 呼叫、雲端同步或跨裝置學習檔案共享。

## 建議開發與整合順序

1. PM 確認哪些 Favorite 與 Review 回饋可作為素材來源、生成前告知、可追溯性、跳過／替換與品質不足的驗收情境。
2. Luke 先凍結 Learning Unit、Generated Material、來源關係、素材偏好、生成介面與 typed generation failure 的 Domain 契約。
3. Ethan 實作學習單位／生成素材／來源關係的持久化及受控素材快取；同時 Eason 可用 fake generator 完成排序與生成流程。
4. Eason 實作由 Favorites 與 Review metadata 建立學習地圖、優先排序、明確告知後生成、品質失敗降級與素材操作；Joe 依 state 建立素材與來源呈現。
5. Ethan 的真實 Generator adapter 與資料儲存交給 Eason 接線，驗證來源追溯、取消／失敗不覆蓋既有內容與資料分離。
6. Joe 完成練習、答案揭示、來源查看、跳過／替換的畫面驗證；PM 驗收生成、重用、失敗與使用者控制情境。

## 四位 Owner 的責任與交付

### Luke／Domain Owner

- 定義 Learning Unit、Generated Material、來源追溯、素材偏好、品質條件與 generation interface。
- 強制素材只從 Favorite 與合法 Review metadata 衍生，並提供 Domain tests；不綁定 Provider 或資料庫。

### Ethan／Infrastructure Owner

- 實作素材、版本與來源關係的本機持久化、受控重用快取，以及 Provider generator adapter。
- 管理 credential boundary 與 failure mapping，不可把 Recent History、Cache 或私密資料未告知地送去生成；提供 Infrastructure tests。

### Eason／Application Owner

- 實作學習地圖建立、優先排序、少量素材選取、生成前告知、取消／失敗降級與跳過／替換 command。
- 將來源資訊與 typed failures 映射為穩定 UI state，並提供 Application／integration tests。

### Joe／Presentation Owner

- 製作個人化素材入口、題目、答案揭示、來源查看、跳過、不再練習與替換操作。
- 清楚揭示生成狀態與失敗，不假裝題目已生成；完成 Widget／semantics tests。
