# T-06R Implementation Summary

## Persistence boundary

PersistenceController 現在以 _mapPersistenceFailure 包住每一個實際
repository operation。raw exception 會轉為 sanitized
AnalysisPersistenceException，其 wire code 為 PERSISTENCE_FAILED；
既有 AnalysisApplicationException 會 rethrow，不會被重包。

涵蓋的 public operation：

- Settings：saveHistory 的 read、setHistoryWritesEnabled
- History：saveHistory 的 save、visibleHistory 的 list、deleteHistory
- Cache：clearCache、cache、cached
- Favorite：visibleHistory 的 list、setFavorite 的 save／delete、favorites
- Feedback：submitFeedback、feedback

visibleHistory(limit: -1) 的 input validation 位於 repository mapping 之外，
因此仍拋出 ArgumentError。

## Test correction

- 移除 provider fake 直接拋出 AnalysisPersistenceException 的測試。
- 新增 throwing repository fakes，逐一覆蓋上述 public operation。
- 每個 raw failure 均確認轉為 PERSISTENCE_FAILED，且 exception text 不包含
  synthetic raw repository failure。
- 移除未連接 AnalysisController 與 PersistenceController 的 History／Cache
  測試；保留 empty、whitespace 與 2,001-character 的 provider invocation zero tests。

## Architecture limitation recorded

T-06／T-06R 沒有宣稱存在 integrated analysis-to-persistence workflow。這需要未授權
的 coordinator／product flow，留待後續經明確授權的 task。
