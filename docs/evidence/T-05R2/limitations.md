# T-05R2 Limitations

- 本輪只修正 `visibleHistory(limit)` 的總 query limit 與 deterministic ordering。
- Favorites 只獲得 selection priority，仍計入 returned records limit。
- visible query 永遠不 physical delete History 或 Favorite records。
- 沒有新增 durable storage、Drift、SQLite、Isar、schema、migration、UI、dependency 或 platform integration。
- `flutter build windows` 為 `BLOCKED`，原因是找不到預期 CMake executable path。
- macOS build/runtime 為 `NOT_RUN`，目前 host 為 Windows。
- T-05、T-05R 與 T-05R2 尚未被 Team Review 接受。
- T-06 維持 `NOT_AUTHORIZED`。
