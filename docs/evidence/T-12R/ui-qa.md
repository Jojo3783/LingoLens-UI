# T-12R UI QA

## Automated widget coverage

`test/widget_t12r_ui_test.dart` 覆蓋：

- wide window 顯示 `NavigationRail`；
- compact window 顯示 `NavigationBar`；
- destination 僅為 `分析` 與 `設定`；
- 切換至 `設定` 後可看到 Fake／OpenAI provider selection；
- secure save 成功後清除 API key field，並顯示不包含 key 的狀態文字；
- provider-neutral analysis flow 與實際 provider disclosure 不矛盾。

Task: T-12R UI regression
Command: `flutter test test/widget_t12r_ui_test.dart` as part of the focused suite
Working directory: disposable final clone `D:\\GitHub\\workspace\\lingolens-t12r-final4`
Result: `PASS`
Focused result: UI regression tests passed within the 48-test focused suite。
Limitations: automated widget coverage 不等同於 Windows native manual smoke。

## Design boundary

Material 3、system light/dark theme、indigo seed、surface hierarchy、最小可用寬度、
keyboard-accessible navigation 與 `Semantics` live-region failure disclosure 依
`DESIGN.md` 實作。未加入 History、Favorites、Review 或 placeholder destination。
