# T-05R2 Test Evidence

## TDD Red-Green Evidence

修正前執行 `flutter test test/application/persistence_controller_test.dart`，exit code `1`。失敗原因符合 root cause：

- 21 筆含 1 個 Favorite 的 default query 實際回傳 21，不是 20。
- `limit: 0` 實際回傳 1 筆 Favorite，不是空集合。
- Favorite 超過 limit 時依插入順序，不符合 deterministic ordering。
- Mixed records 未依 Favorite-first、createdAt descending、id ascending 排序。

修正後同一 focused test 通過。

## Mandatory Policy Tests

- Default total limit：21 stored、1 Favorite，回傳 20；History 仍 21、Favorite 仍 1。
- Zero limit：回傳空集合；兩個 repository 均未變更。
- Favorites exceed limit：25 Favorites、limit 20，回傳排序後前 20；兩個 repository 均保留 25。
- No Favorites：21 筆只回傳最新 20；最舊排除 record 仍保留。
- Mixed deterministic ordering：Favorites first，兩組均依日期 descending、id ascending，總數不超過 limit。
- Negative limit：`ArgumentError`，repositories 不變更。

## Final Counts

- Focused command：`flutter test test/application/persistence_controller_test.dart`
- Focused result：`PASS`，10 tests passed
- Full command：`flutter test`
- Full result：`PASS`，24 tests passed
