# LingoLens UI Design Contract

## Product tone

LingoLens 是一個安靜、可信賴的語言工作台。畫面優先呈現目前任務、輸入內容與可採取的下一步；避免把 Provider、診斷資訊或未來功能誤呈現為已完成的產品能力。

## Visual system

- 使用 Flutter Material 3 與 `Theme.of(context).colorScheme`，支援 `ThemeMode.system` 的 light／dark theme。
- 以 `Colors.indigo` 作為 seed token；元件不得散落自訂 hex 色碼。
- 使用 4 的間距節奏，主要區塊採 16／24 內距，互動控制項維持至少 48 logical pixels 的可操作尺寸。
- 主要表面使用 `surface`、`surfaceContainer`、`surfaceContainerHighest` 與 `outlineVariant`，陰影只用於浮動或需要層次的表面。
- 文字階層由 Material 3 typography 定義；標題、說明、狀態與錯誤訊息必須有清楚的語意順序。

## Product parity target

- Ethan pinned source `df4f5424e8abfedc52f941c8c5c2f1a9463e8aac` 的 product behavior 與 UX 是產品 parity source；它不授權複製原始碼、native implementation 或 dependencies。
- 正式產品 shell 必須提供 Dashboard、History、Favorites、Review 與 Settings，並呈現 recent queries、learning state 與 speech／pronunciation support。
- 目前 `分析`／`設定` 兩個 destination 是現行 implementation snapshot，不是永久產品 scope；差距記錄於 `docs/product/T-12R3_ETHAN_PRODUCT_PARITY.md`。

## Layout contract

- Parity implementation 完成前，現有 shell 可暫時提供 `分析` 與 `設定`；目標 shell 必須納入 Dashboard、History、Favorites、Review 與 Settings。
- 寬畫面使用 `NavigationRail`；窄畫面使用 `NavigationBar`。切換依可用寬度，不依作業系統名稱。
- Shell 擁有主要 scroll surface；頁面不得在同一軸向建立無界 nested scroll。
- 分析頁的輸入、模式、主要動作與結果依序排列；設定頁以 section card 分組。
- 不得以 placeholder destination 宣稱 parity 已完成；各 parity destination 必須有對應的功能 contract、state 與 evidence。

## Component primitives

- `LingoLensSurface`：統一表面色彩、圓角與內距。
- `LingoLensSectionHeader`：統一 section 標題與輔助說明。
- `LingoLensStatusCard`：顯示 Provider、權限、失敗或安全設定狀態。
- `LingoLensNavigationShell`：集中 responsive navigation 與目前 destination。

## Interaction and accessibility

- 可見文字與 Semantics label 必須說明實際狀態，不得宣稱未執行的 network、native 或安全能力。
- 所有主要動作提供 keyboard 可達路徑；`Escape` 關閉浮動 panel。
- 錯誤與擷取狀態使用 live region；顏色不是唯一狀態識別方式。
- Focus 只有在 panel 顯示且 window activation 成功後才移入輸入框。
- Developer failure control 只在 `kDebugMode` 且位於收合的 Developer section。

## Reference boundary

Ethan 的 Material 3、indigo seed、NavigationRail、Dashboard、History、Favorites、Review、Settings、section-card、recent-query、learning-state 與 provider status 是產品行為與資訊架構的 parity source。LingoLens 的元件、文字與樣式在本文件定義，不複製來源 Repository 的 UI 實作；LAS 的 provider-neutral shell、responsive navigation、page introduction、status hierarchy 與 reusable surface 仍僅作概念參考。
