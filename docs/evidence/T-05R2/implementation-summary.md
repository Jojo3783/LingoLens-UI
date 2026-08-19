# T-05R2 Implementation Summary

## Root Cause

原本 `visibleHistory(limit)` 將結果組成為「全部 Favorites 加上 `limit` 筆 Non-Favorites」，因此 Favorite 被錯誤地排除在總 query count 外。

## Corrected Policy

`PersistenceController.visibleHistory` 現在：

1. 驗證 `limit < 0` 仍拋出 `ArgumentError`。
2. 對 Favorite 與 Non-Favorite History records 分組。
3. 每組依 `createdAt` descending、`id` ascending 排序。
4. 先合併排序後的 Favorites，再接上排序後的 Non-Favorites。
5. 對完整合併序列套用 `.take(limit)`，因此所有回傳 records 都計入 limit。
6. 不進行任何 physical eviction；排除的 History 與 Favorite records 仍留在各自 repository。

## Scope Boundary

只修改：

- `lib/application/persistence_controller.dart`
- `test/application/persistence_controller_test.dart`
- T-05R2 governance metadata、Root `handoff.md` 與專屬 evidence

未修改 repository interfaces、dependencies、UI、durable storage、platform integration 或 T-06。
