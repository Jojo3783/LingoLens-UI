# T-05R Implementation Summary

## P1-01 ADR-003 Contracts

新增 framework-agnostic Domain contracts：

- `HistoryRepository`
- `AnalysisCacheRepository`
- `SettingsRepository`
- `FavoriteRepository`
- `FeedbackRepository`
- `HistoryRecord`
- `AnalysisCacheEntry`
- `SettingsSnapshot`
- `FavoriteRecord`
- `FeedbackRecord`

新增 deterministic in-memory implementations：

- `InMemoryHistoryRepository`
- `InMemoryAnalysisCacheRepository`
- `InMemorySettingsRepository`
- `InMemoryFavoriteRepository`
- `InMemoryFeedbackRepository`

## Application-owned Policies

`PersistenceController` 負責：

- history-write setting gate；停用時不寫入新 History。
- `visibleHistoryLimit = 20` query/domain policy，不進行 destructive physical retention。
- Favorite records 置於獨立 repository，並在 visible query 中受保護，不因 limit 自動 eviction。
- `clearCache()` 只呼叫 Cache repository。
- `deleteHistory()` 只呼叫 History repository，與 cache clear 分離。
- Feedback input/output 僅在 `consentToAttachContent == true` 時附加。

## P2 Lifecycle Tests

`AnalysisController` 的既有 latest-wins/stale guard 經新增測試覆蓋：

- user cancellation 在 cancellation-ignoring provider late success 後仍維持 `cancelled`。
- stale success 與 stale failure 都不能覆寫新 request。
- unexpected provider exception 轉為 sanitized `UNKNOWN_ERROR`。
- empty input 使 provider invocation count 保持 `0`。
- typed provider failure 不轉成 Fake success。
- retry 建立新 `RequestId`。
- dispose 後 late fake completion 不產生 terminal overwrite。

所有資料皆為 synthetic test data；未新增 UI、database package、schema、migration 或 T-06 features。
