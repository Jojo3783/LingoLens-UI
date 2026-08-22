import '../domain/persistence_contracts.dart';
import '../domain/analysis_models.dart';

final class PersistenceController {
  PersistenceController({
    required HistoryRepository history,
    required AnalysisCacheRepository cache,
    required SettingsRepository settings,
    required FavoriteRepository favorites,
    required FeedbackRepository feedback,
  }) : _history = history,
       _cache = cache,
       _settings = settings,
       _favorites = favorites,
       _feedback = feedback;

  final HistoryRepository _history;
  final AnalysisCacheRepository _cache;
  final SettingsRepository _settings;
  final FavoriteRepository _favorites;
  final FeedbackRepository _feedback;

  Future<bool> saveHistory(HistoryRecord record) async {
    final settings = await _mapPersistenceFailure(_settings.read);
    if (!settings.historyWritesEnabled) {
      return false;
    }
    await _mapPersistenceFailure(() => _history.save(record));
    return true;
  }

  Future<void> setHistoryWritesEnabled(bool enabled) {
    return _mapPersistenceFailure(
      () => _settings.setHistoryWritesEnabled(enabled),
    );
  }

  Future<List<HistoryRecord>> visibleHistory({
    int limit = visibleHistoryLimit,
  }) async {
    if (limit < 0) {
      throw ArgumentError.value(limit, 'limit', 'must not be negative');
    }
    if (limit == 0) {
      return const <HistoryRecord>[];
    }

    final records = await _mapPersistenceFailure(_history.listAll);
    final favoriteIds = (await _mapPersistenceFailure(
      _favorites.listAll,
    )).map((favorite) => favorite.historyRecordId).toSet();
    final favorites =
        records.where((record) => favoriteIds.contains(record.id)).toList()
          ..sort(_compareHistoryRecords);
    final unpinned =
        records.where((record) => !favoriteIds.contains(record.id)).toList()
          ..sort(_compareHistoryRecords);

    return List<HistoryRecord>.unmodifiable(
      <HistoryRecord>[...favorites, ...unpinned].take(limit),
    );
  }

  Future<void> deleteHistory(String recordId) =>
      _mapPersistenceFailure(() => _history.delete(recordId));

  Future<void> clearCache() => _mapPersistenceFailure(_cache.clear);

  Future<void> cache(AnalysisCacheEntry entry) =>
      _mapPersistenceFailure(() => _cache.put(entry));

  Future<AnalysisCacheEntry?> cached(String key) =>
      _mapPersistenceFailure(() => _cache.get(key));

  Future<void> setFavorite({
    required String historyRecordId,
    required DateTime createdAt,
    required bool isFavorite,
  }) {
    if (isFavorite) {
      return _mapPersistenceFailure(
        () => _favorites.save(
          FavoriteRecord(
            historyRecordId: historyRecordId,
            createdAt: createdAt,
          ),
        ),
      );
    }
    return _mapPersistenceFailure(() => _favorites.delete(historyRecordId));
  }

  Future<List<FavoriteRecord>> favorites() =>
      _mapPersistenceFailure(_favorites.listAll);

  Future<List<HistoryRecord>> reviewCandidates({
    DateTime? now,
    int days = 10,
    int maxCount = 5,
  }) async {
    final referenceTime = now ?? DateTime.now();
    final threshold = referenceTime.subtract(Duration(days: days));
    final favList = await _mapPersistenceFailure(_favorites.listAll);
    final validFavs = favList
        .where(
          (f) =>
              f.createdAt.isAfter(threshold) ||
              f.createdAt.isAtSameMomentAs(threshold),
        )
        .toList();
    if (validFavs.isEmpty) {
      return const <HistoryRecord>[];
    }
    final favIds = validFavs.map((f) => f.historyRecordId).toSet();
    final allRecords = await _mapPersistenceFailure(_history.listAll);
    final candidateRecords =
        allRecords.where((r) => favIds.contains(r.id)).toList()
          ..sort(_compareHistoryRecords);
    return List<HistoryRecord>.unmodifiable(candidateRecords.take(maxCount));
  }

  Future<void> submitFeedback({
    required String id,
    required FeedbackReason reason,
    required bool consentToAttachContent,
    String? comment,
    String? input,
    String? output,
    required DateTime createdAt,
  }) {
    return _mapPersistenceFailure(
      () => _feedback.save(
        FeedbackRecord(
          id: id,
          reason: reason,
          comment: comment,
          attachedInput: consentToAttachContent ? input : null,
          attachedOutput: consentToAttachContent ? output : null,
          createdAt: createdAt,
        ),
      ),
    );
  }

  Future<List<FeedbackRecord>> feedback() =>
      _mapPersistenceFailure(_feedback.listAll);
}

Future<T> _mapPersistenceFailure<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on AnalysisApplicationException {
    rethrow;
  } catch (_) {
    throw const AnalysisPersistenceException();
  }
}

int _compareHistoryRecords(HistoryRecord left, HistoryRecord right) {
  final createdAtOrder = right.createdAt.compareTo(left.createdAt);
  return createdAtOrder == 0 ? left.id.compareTo(right.id) : createdAtOrder;
}
