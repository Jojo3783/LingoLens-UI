import 'analysis_models.dart';

const int visibleHistoryLimit = 20;

final class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.input,
    required this.mode,
    required this.result,
    required this.createdAt,
  });

  final String id;
  final String input;
  final AnalysisMode mode;
  final AnalysisResult result;
  final DateTime createdAt;
}

final class AnalysisCacheEntry {
  const AnalysisCacheEntry({
    required this.key,
    required this.output,
    required this.createdAt,
  });

  final String key;
  final String output;
  final DateTime createdAt;
}

final class SettingsSnapshot {
  const SettingsSnapshot({this.historyWritesEnabled = true});

  final bool historyWritesEnabled;
}

final class FavoriteRecord {
  const FavoriteRecord({
    required this.historyRecordId,
    required this.createdAt,
  });

  final String historyRecordId;
  final DateTime createdAt;
}

enum FeedbackReason { incorrect, unhelpful, other }

final class FeedbackRecord {
  const FeedbackRecord({
    required this.id,
    required this.reason,
    required this.comment,
    required this.attachedInput,
    required this.attachedOutput,
    required this.createdAt,
  });

  final String id;
  final FeedbackReason reason;
  final String? comment;
  final String? attachedInput;
  final String? attachedOutput;
  final DateTime createdAt;
}

abstract interface class HistoryRepository {
  Future<void> save(HistoryRecord record);

  Future<List<HistoryRecord>> listAll();

  Future<void> delete(String recordId);

  Future<void> clear();
}

abstract interface class AnalysisCacheRepository {
  Future<void> put(AnalysisCacheEntry entry);

  Future<AnalysisCacheEntry?> get(String key);

  Future<void> clear();
}

abstract interface class SettingsRepository {
  Future<SettingsSnapshot> read();

  Future<void> setHistoryWritesEnabled(bool enabled);
}

abstract interface class FavoriteRepository {
  Future<void> save(FavoriteRecord record);

  Future<List<FavoriteRecord>> listAll();

  Future<void> delete(String historyRecordId);
}

abstract interface class FeedbackRepository {
  Future<void> save(FeedbackRecord record);

  Future<List<FeedbackRecord>> listAll();
}
