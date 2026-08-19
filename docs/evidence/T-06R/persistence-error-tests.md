# T-06R Persistence Error Test Matrix

所有列出的 raw failure 都由 repository fake 拋出
StateError('synthetic raw repository failure')，並由測試確認最後只暴露
PERSISTENCE_FAILED 與 user-safe message。

| Repository | Public operation | Test |
|---|---|---|
| Settings | saveHistory read | raw settings read failure |
| Settings | setHistoryWritesEnabled | raw settings write failure |
| History | saveHistory save | raw history save failure |
| History | visibleHistory list | raw history list failure |
| History | deleteHistory | raw history delete failure |
| Cache | clearCache | raw cache clear failure |
| Cache | cache | raw cache write failure |
| Cache | cached | raw cache read failure |
| Favorite | visibleHistory list | raw favorite list failure |
| Favorite | setFavorite(isFavorite: true) | raw favorite save failure |
| Favorite | setFavorite(isFavorite: false) | raw favorite delete failure |
| Favorite | favorites | raw favorite list operation failure |
| Feedback | submitFeedback | raw feedback save failure |
| Feedback | feedback | raw feedback list failure |

另外保留：

- negative visible history limit remains ArgumentError
- existing visibility, favorite ordering, cache isolation、feedback consent tests

測試結果：focused suite 51 passed；complete suite 65 passed。
