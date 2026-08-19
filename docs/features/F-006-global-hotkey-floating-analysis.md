# F-006：全域快捷鍵、選取文字與浮動分析視窗

- 狀態：`DRAFT`
- 建立日期：`2026-08-15`
- PM：Jimmy
- 優先級：`P0`
- 關聯 task／PR：尚未建立
- Implementation authorization：`NOT_AUTHORIZED_BY_THIS_DOCUMENT`

## 功能願景

LingoLens 的前五項功能完成後，使用者已能分析文字、重用 Cache、保存最近查詢、收藏
重要內容並進行複習；但如果每次都必須先複製文字、切換 App、貼上再送出，仍會打斷
閱讀、工作與學習情境。

F-006 將既有能力接到桌面上的主要入口。使用者在任何支援的 App 選取文字後，按下
全域快捷鍵，LingoLens 應擷取該段文字、喚醒同一個浮動分析視窗，並沿用 F-003 的
Cache-First 流程取得 F-002 的統一分析結果；完整成功後再由 F-001 處理 Recent History
與 Favorite。F-006 不重新實作 AI、Cache 或持久化，只負責安全可靠地把桌面選取內容
送入既有分析流程。

## 與前後功能的關係

```text
外部 App 選取文字
  ↓
F-006 全域快捷鍵
  ↓
F-006 選取文字擷取／Clipboard fallback
  ↓
F-006 開啟或喚醒單一浮動視窗
  ↓
F-003 Cache-First execution
  ├─ Cache hit：回傳既有完整 typed result
  └─ Cache miss：呼叫 F-002 使用者選定的 Provider
  ↓
F-002 統一 Reading／Expression result
  ↓
F-001 Recent History／Favorite
  ↓
F-007 日後讓浮動視窗中的英文內容可點擊播放
```

F-006 可以在 F-001～F-005 完成後直接串接，因為它只使用前面功能公開的 commands、
states 與 result models。F-006 不得從浮動視窗直接呼叫 Provider、Cache Repository 或
History DB。

## 使用者流程

### 流程 A：成功擷取並自動分析

```text
使用者在其他 App 選取文字
→ 按下全域快捷鍵
→ LingoLens 擷取選取內容
→ 開啟或喚醒唯一浮動視窗
→ 顯示擷取文字並帶入 F-002 的 mode suggestion
→ 透過 F-003 發起 Cache-First 分析
→ 顯示 Preview／完整結果或 typed failure
→ full success 依 F-001 規則進入 Recent History
```

使用者不需要再次按下「分析」。若擷取到合法非空文字，浮動視窗顯示後即自動送出；
使用者仍可取消、Retry、修改文字後重新送出，或依 F-001 加入 Favorite。

### 流程 B：無法取得選取文字

```text
使用者按下快捷鍵
→ 系統無法取得文字或目前沒有選取內容
→ 仍開啟／喚醒浮動視窗
→ 不自動送出分析
→ 顯示可理解原因並將焦點放到手動輸入
```

失敗時不可分析舊內容、Clipboard 中不相關的既有文字，或上一次成功擷取的文字。

### 流程 C：快速連續觸發

```text
快捷鍵觸發 A
→ A 正在擷取或分析
→ 快捷鍵觸發 B
→ 取消／淘汰 A 的 capture ownership
→ B 成為目前擷取與分析
→ A 的晚到結果不得覆蓋 B
```

F-006 capture 採 latest-capture-wins；交給 F-002 後，同時沿用 F-002 的
latest-request-wins 與 cancellation 規則。

### 流程 D：快捷鍵或權限不可用

```text
App 啟動或設定快捷鍵
→ 註冊失敗、組合衝突或缺少平台權限
→ Settings 顯示真實狀態與處理方式
→ 不宣稱快捷鍵可用
→ 使用者仍可從 App 內手動輸入分析
```

## 使用者價值

- 不必離開正在閱讀或工作的 App，就能取得 LingoLens 的完整分析。
- 同一個浮動視窗反覆使用，不會產生多個難以管理的視窗。
- Cache、Provider、History 與 Favorite 行為和主 App 完全一致。
- 擷取失敗時仍可立刻改用手動輸入，不會遺失原本工作情境。
- Clipboard 與外部 App 資料受到保護，不會為了擷取文字永久覆寫使用者內容。

## 重要實作細項

### 全域快捷鍵

- Windows 與 macOS 都必須在 App 執行期間註冊同一個產品預設快捷鍵；確切按鍵組合由
  PM 在實作前確認。
- 快捷鍵註冊結果必須有真實狀態：checking、registered、conflict、permissionRequired、
  unavailable 與 registrationFailed。
- 快捷鍵被其他程式占用時不得假裝成功；Settings 應提供說明與重新嘗試。
- 快捷鍵 callback 只提交 Application intent，不可直接在 native callback 呼叫 Provider、
  更新 Widget 或寫入 DB。
- App 關閉或 platform adapter dispose 時必須解除自己註冊的快捷鍵。

### 選取文字擷取

- 優先使用平台支援的 selection／accessibility 能力取得文字；不可用時才使用 bounded
  Clipboard fallback。
- 擷取只接受本次快捷鍵操作取得的文字；空白、失敗、取消、timeout 或較舊 generation
  不得沿用前一次內容。
- 文字 normalization 必須沿用 F-002 的 input contract，不在 platform adapter 另做翻譯、
  小寫化或語意改寫。
- 每次 capture 都有唯一 ownership、deadline、cancellation 與 single completion。
- macOS 缺少 Accessibility 權限時，顯示權限說明與前往系統設定的操作；不得無限重試。

### Clipboard fallback 與還原

- fallback 開始前保存 Clipboard ownership／sequence 與可安全還原的原始內容。
- 模擬 Copy 後只讀取本次操作產生的新 Clipboard 內容；不得把 fallback 前的舊文字誤當
  成目前 selection。
- capture 完成、失敗、取消或 timeout 後都必須進入 cleanup。
- 只有仍持有本次 Clipboard sequence 時才還原原內容；若使用者或其他 App 已更新
  Clipboard，不得以舊資料覆寫較新的內容。
- capture deadline 與 cleanup deadline 分開；分析 request 不得持有 Clipboard ownership。
- Clipboard 內容、選取文字與還原資料不得寫入一般 log、telemetry 或暫存檔。

### 浮動視窗

- 全 App 只維護一個浮動分析視窗；重複快捷鍵應喚醒、更新並重用既有視窗，而不是建立
  多個 window instance。
- 視窗應預先或快速初始化，顯示時避免長時間白屏；真實 loading 狀態由 F-002／F-003
  提供。
- 視窗定位在目前游標、作用中螢幕或選取位置附近，且整個可操作區必須落在目前螢幕
  working area 內。
- Windows scaling、macOS Retina 與多螢幕不同 scale factor 必須正確處理 logical／physical
  coordinates。
- 視窗成功顯示並取得適當 activation 後才將焦點放到輸入或結果；activation failure 要
  保留已擷取文字並回傳 typed state，不能丟失內容。
- 使用者可用 Escape 或關閉操作隱藏視窗；是否同時取消 active analysis 由 PM 在實作前
  確認，不能由 Joe 或 platform adapter 自行決定。

### 與 F-001／F-002／F-003 的整合

- F-006 只呼叫 Eason 提供的「以擷取文字開始分析」Application command。
- 每次成功 capture 建立新的 F-002 `queryExecutionId`；相同文字再次擷取仍是新的查詢。
- F-003 Cache hit 與 Provider success 都回到 F-002 的同一 typed result state。
- full success 只由 F-002 向 F-001 completion 入口交付一次；F-006 不直接保存。
- Preview、capture failure、cancel、stale 或 window activation failure 不得被 F-006 當成
  full result 寫入 History。
- F-001 persistence failure 不影響浮動視窗顯示完整分析結果。

### 隱私與安全

- 選取文字只為使用者明確觸發的本次分析使用，不在背景持續監聽鍵盤、Clipboard 或
  active application。
- 不記錄 raw selection、Clipboard、完整 prompt、Provider response、credential、window
  title 或來源 App 私密資訊。
- Native adapter 只能操作自己建立的 hotkey registration、capture operation 與 window；
  cancellation 不得終止其他 App 的 process 或清除其他 App 的 Clipboard 更新。
- 錯誤訊息可包含平台與 failure category，但不可顯示 raw Clipboard、private text 或
  native exception dump。

## 畫面與狀態需求

### 浮動分析視窗

| 狀態 | 畫面應顯示 | 使用者可以做什麼 |
| --- | --- | --- |
| Opening | 輕量啟動畫面，不顯示舊結果為本次內容 | 等待或關閉 |
| Capturing | 正在取得選取文字 | 取消或關閉 |
| Captured | 本次文字與 mode suggestion | 修改、取消或等待自動分析 |
| Capture failure | 無法取得文字的具體說明 | 手動輸入、重試或開啟權限設定 |
| Analyzing | F-003／F-002 的真實 loading／Preview | 取消或關閉 |
| Success | F-002 typed result 與 F-001 persistence／Favorite 狀態 | 複製、Favorite、Retry 或關閉 |
| Failure | F-002 typed failure，不顯示舊結果為新結果 | Retry、調整 Provider 或手動修改 |
| Activation failure | 已擷取文字仍保留，顯示視窗啟動問題 | 回主 App、重試或複製文字 |

### Settings

- 顯示目前快捷鍵、註冊狀態與平台權限狀態。
- 提供重新註冊／重新檢查，以及 macOS 必要的系統設定引導。
- 不把「設定已保存」和「快捷鍵已成功向 OS 註冊」混成同一個成功狀態。

## 不在本功能範圍

- 修改 F-001 History／Favorite 保留政策。
- 修改 F-002 result schema、Provider、prompt 或 credential 行為。
- 實作 F-003 Cache key、TTL、容量或清除策略。
- Review、個人化素材或學習狀態演算法。
- F-007 TTS、錄音、語音辨識或發音評分。
- OCR、螢幕截圖辨識、瀏覽器 extension 或行動裝置 share sheet。
- 背景監控所有鍵盤、Clipboard 或使用者正在輸入的內容。

## 建議開發與整合順序

1. PM 確認預設快捷鍵、無選取文字行為、浮動視窗關閉是否取消分析，以及 Windows／
   macOS 驗收路徑。
2. Luke 定義 capture、hotkey、window activation、positioning、permission 與 typed platform
   failures 的 Domain／Application contracts。
3. Eason 先以 fake platform services 建立 hotkey → capture → floating window → F-003／F-002
   → F-001 的完整 orchestration 與 latest-capture-wins tests。
4. Ethan 分別實作 Windows／macOS hotkey、selection、Clipboard fallback、window 與 permission
   adapters；Joe 同時以 Eason states 製作浮動視窗及 Settings。
5. Eason 接上真實 adapters，驗證快速連續觸發、cancel、timeout、late completion、視窗重用
   與 F-001／F-002／F-003 regression。
6. Joe 完成 keyboard、focus、Semantics、compact window 與多狀態 Widget tests。
7. 四位 Owner 分別在 Windows／macOS 執行 native harness、build 與人工桌面互動；PM 完成
   選取文字、Clipboard、快捷鍵衝突、多螢幕與浮動視窗驗收。

## 四位 Owner 的責任與交付

### Luke／Domain Owner

- 定義 `GlobalHotkeyService`、`SelectedTextService`、`FloatingWindowService`、
  `WindowActivationService`、capture context、capability 與 typed platform failures。
- 定義 capture latest-wins、Clipboard ownership、activation success 與 F-002 submit 的邊界。
- 提供 contracts、failure matrix 與 Domain tests；不處理 Win32、macOS API 或 Widget。

### Ethan／Infrastructure Owner

- 實作 Windows／macOS hotkey、selected-text、bounded Clipboard fallback、single floating
  window、activation、positioning 與 permission adapters。
- 確保 Clipboard cleanup、owned cancellation、native resource disposal 與敏感資料不落 log。
- 提供 native harness、Infrastructure tests、平台 build 與人工驗證限制。

### Eason／Application Owner

- 實作 hotkey intent、capture generation、latest-capture-wins、浮動視窗 orchestration，並將
  成功文字交給 F-003／F-002 的唯一分析 command。
- 將 capture、window、analysis 與 F-001 persistence 組成互不混淆的 UI states。
- 提供 controlled fake tests、race／cancel／timeout tests 及跨功能 integration tests。

### Joe／Presentation Owner

- 製作浮動分析視窗、capture／permission／activation failure、F-002 result 與 F-001 actions
  的畫面，以及 Settings 中的快捷鍵／權限狀態。
- 完成 compact／wide、keyboard、focus、Semantics、多螢幕可用性與 Widget tests。
- 不直接呼叫 native platform、Provider、Cache 或 Repository。

## 草稿驗收方向

- 全域快捷鍵可在 Windows／macOS 真實註冊、觸發、解除與回報衝突。
- 選取文字可在代表性外部 App 擷取；沒有選取文字時不分析舊內容。
- Clipboard fallback 成功、失敗、取消與 timeout 都不覆寫較新的 Clipboard 內容。
- 快速連續觸發時只有最新 capture／analysis 可以更新浮動視窗與 F-001。
- 浮動視窗維持單一 instance，在多螢幕／不同縮放下可見、可操作、可取得焦點。
- F-003 hit／miss、F-002 success／failure／cancel 與 F-001 persistence 狀態均沿用既有契約。
- Windows／macOS 的人工桌面 QA 分開記錄；未執行平台不得標示通過。

本文件為功能草稿，不代表 production implementation authorization。詳細 Owner 工作包、
正式測試矩陣與 Definition of Done 應在 PM 確認上述未決產品行為後再凍結。
