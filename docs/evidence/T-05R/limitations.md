# T-05R Limitations

- T-05R 只實作 ADR-003 最小 contracts、deterministic in-memory fakes、Application policies 與 lifecycle tests。
- 沒有 durable History、Cache、Settings、Favorite 或 Feedback storage。
- 沒有 Drift、SQLite、Isar、schema、migration、database file 或 persistence UI。
- 沒有 real AI、CLI、HTTP、local model、credentials、secret 或 donor production-code reuse。
- Cancellation 只驗證 controlled fake 與 Application stale-result protection；不宣稱 real process/network cancellation。
- `flutter build windows` 為 `BLOCKED`，原因是 Flutter 找不到預期 CMake executable path。
- macOS build/runtime 為 `NOT_RUN`，目前 host 為 Windows。
- 所有 tests 使用 synthetic data；沒有寫入 raw user text、private logs 或 credentials。
- T-05 仍為 `REQUEST_CHANGES`，T-05R 為 `REMEDIATION_IN_PROGRESS`；兩者均未被 Team Review 接受。
- T-06 仍為 `NOT_AUTHORIZED`。
