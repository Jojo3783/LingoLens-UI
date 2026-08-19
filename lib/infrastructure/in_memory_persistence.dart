import '../domain/persistence_contracts.dart';

final class InMemoryHistoryRepository implements HistoryRepository {
  final List<HistoryRecord> _records = <HistoryRecord>[];

  @override
  Future<void> save(HistoryRecord record) async {
    _records.removeWhere((existing) => existing.id == record.id);
    _records.add(record);
  }

  @override
  Future<List<HistoryRecord>> listAll() async =>
      List<HistoryRecord>.unmodifiable(_records);

  @override
  Future<void> delete(String recordId) async {
    _records.removeWhere((record) => record.id == recordId);
  }

  @override
  Future<void> clear() async => _records.clear();
}

final class InMemoryAnalysisCacheRepository implements AnalysisCacheRepository {
  final Map<String, AnalysisCacheEntry> _entries =
      <String, AnalysisCacheEntry>{};

  @override
  Future<void> put(AnalysisCacheEntry entry) async {
    _entries[entry.key] = entry;
  }

  @override
  Future<AnalysisCacheEntry?> get(String key) async => _entries[key];

  @override
  Future<void> clear() async => _entries.clear();
}

final class InMemorySettingsRepository implements SettingsRepository {
  bool _historyWritesEnabled = true;

  @override
  Future<SettingsSnapshot> read() async =>
      SettingsSnapshot(historyWritesEnabled: _historyWritesEnabled);

  @override
  Future<void> setHistoryWritesEnabled(bool enabled) async {
    _historyWritesEnabled = enabled;
  }
}

final class InMemoryFavoriteRepository implements FavoriteRepository {
  final Map<String, FavoriteRecord> _records = <String, FavoriteRecord>{};

  @override
  Future<void> save(FavoriteRecord record) async {
    _records[record.historyRecordId] = record;
  }

  @override
  Future<List<FavoriteRecord>> listAll() async =>
      List<FavoriteRecord>.unmodifiable(_records.values);

  @override
  Future<void> delete(String historyRecordId) async {
    _records.remove(historyRecordId);
  }
}

final class InMemoryFeedbackRepository implements FeedbackRepository {
  final List<FeedbackRecord> _records = <FeedbackRecord>[];

  @override
  Future<void> save(FeedbackRecord record) async {
    _records.add(record);
  }

  @override
  Future<List<FeedbackRecord>> listAll() async =>
      List<FeedbackRecord>.unmodifiable(_records);
}
