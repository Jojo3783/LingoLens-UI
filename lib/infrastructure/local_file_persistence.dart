import 'dart:convert';
import 'dart:io';

import '../domain/analysis_models.dart';
import '../domain/persistence_contracts.dart';

/// Helper to safely write string content to a file atomically.
Future<void> _atomicWriteString(File file, String content) async {
  await file.parent.create(recursive: true);
  final tempFile = File('${file.path}.tmp_${DateTime.now().microsecondsSinceEpoch}');
  await tempFile.writeAsString(content, flush: true);
  try {
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  } catch (_) {
    // If rename fails (e.g. on some Windows environments), fallback to copy + delete
    await tempFile.copy(file.path);
    await tempFile.delete().catchError((_) => tempFile);
  }
}

/// A [HistoryRepository] that persists records to a JSON file on disk.
final class LocalFileHistoryRepository implements HistoryRepository {
  LocalFileHistoryRepository(this.file) {
    _loadSync();
  }

  final File file;
  final List<HistoryRecord> _records = <HistoryRecord>[];
  bool _loaded = false;

  void _loadSync() {
    if (_loaded) return;
    _loaded = true;
    if (!file.existsSync()) return;
    try {
      final raw = file.readAsStringSync();
      if (raw.trim().isEmpty) return;
      final list = jsonDecode(raw);
      if (list is List) {
        for (final item in list) {
          if (item is Map<String, Object?>) {
            try {
              final modeStr = item['mode'] as String?;
              final mode = modeStr == 'expression'
                  ? AnalysisMode.expression
                  : AnalysisMode.reading;
              final record = HistoryRecord(
                id: item['id'] as String,
                input: item['input'] as String,
                mode: mode,
                result: AnalysisResult.fromJson(item['result']),
                createdAt: DateTime.parse(item['createdAt'] as String),
              );
              _records.add(record);
            } catch (_) {
              // Ignore corrupted individual entry
            }
          }
        }
      }
    } catch (_) {
      // Ignore corrupted whole file
    }
  }

  Future<void> _flush() async {
    final list = _records.map((r) => <String, Object?>{
      'id': r.id,
      'input': r.input,
      'mode': r.mode.name,
      'result': r.result.toJson(),
      'createdAt': r.createdAt.toIso8601String(),
    }).toList();
    await _atomicWriteString(file, jsonEncode(list));
  }

  @override
  Future<void> save(HistoryRecord record) async {
    _records.removeWhere((existing) => existing.id == record.id);
    _records.add(record);
    await _flush();
  }

  @override
  Future<List<HistoryRecord>> listAll() async {
    return List<HistoryRecord>.unmodifiable(_records);
  }

  @override
  Future<void> delete(String recordId) async {
    _records.removeWhere((record) => record.id == recordId);
    await _flush();
  }

  @override
  Future<void> clear() async {
    _records.clear();
    await _flush();
  }
}

/// A [FavoriteRepository] that persists records to a JSON file on disk.
final class LocalFileFavoriteRepository implements FavoriteRepository {
  LocalFileFavoriteRepository(this.file) {
    _loadSync();
  }

  final File file;
  final Map<String, FavoriteRecord> _records = <String, FavoriteRecord>{};
  bool _loaded = false;

  void _loadSync() {
    if (_loaded) return;
    _loaded = true;
    if (!file.existsSync()) return;
    try {
      final raw = file.readAsStringSync();
      if (raw.trim().isEmpty) return;
      final list = jsonDecode(raw);
      if (list is List) {
        for (final item in list) {
          if (item is Map<String, Object?>) {
            try {
              final record = FavoriteRecord(
                historyRecordId: item['historyRecordId'] as String,
                createdAt: DateTime.parse(item['createdAt'] as String),
              );
              _records[record.historyRecordId] = record;
            } catch (_) {
              // Ignore corrupted individual entry
            }
          }
        }
      }
    } catch (_) {
      // Ignore corrupted file
    }
  }

  Future<void> _flush() async {
    final list = _records.values.map((r) => <String, Object?>{
      'historyRecordId': r.historyRecordId,
      'createdAt': r.createdAt.toIso8601String(),
    }).toList();
    await _atomicWriteString(file, jsonEncode(list));
  }

  @override
  Future<void> save(FavoriteRecord record) async {
    _records[record.historyRecordId] = record;
    await _flush();
  }

  @override
  Future<List<FavoriteRecord>> listAll() async {
    return List<FavoriteRecord>.unmodifiable(_records.values);
  }

  @override
  Future<void> delete(String historyRecordId) async {
    _records.remove(historyRecordId);
    await _flush();
  }
}

/// A [SettingsRepository] that persists preferences to a JSON file on disk.
final class LocalFileSettingsRepository implements SettingsRepository {
  LocalFileSettingsRepository(this.file) {
    _loadSync();
  }

  final File file;
  bool _historyWritesEnabled = true;
  bool _loaded = false;

  void _loadSync() {
    if (_loaded) return;
    _loaded = true;
    if (!file.existsSync()) return;
    try {
      final raw = file.readAsStringSync();
      if (raw.trim().isEmpty) return;
      final map = jsonDecode(raw);
      if (map is Map<String, Object?>) {
        if (map.containsKey('historyWritesEnabled')) {
          _historyWritesEnabled = map['historyWritesEnabled'] as bool? ?? true;
        }
      }
    } catch (_) {
      // Ignore corrupted file
    }
  }

  Future<void> _flush() async {
    final map = <String, Object?>{
      'historyWritesEnabled': _historyWritesEnabled,
    };
    await _atomicWriteString(file, jsonEncode(map));
  }

  @override
  Future<SettingsSnapshot> read() async =>
      SettingsSnapshot(historyWritesEnabled: _historyWritesEnabled);

  @override
  Future<void> setHistoryWritesEnabled(bool enabled) async {
    _historyWritesEnabled = enabled;
    await _flush();
  }
}

/// An [AnalysisCacheRepository] that persists cached outputs to disk with capacity limit.
final class LocalFileAnalysisCacheRepository implements AnalysisCacheRepository {
  LocalFileAnalysisCacheRepository(this.file, {this.maxCapacity = 30}) {
    _loadSync();
  }

  final File file;
  final int maxCapacity;
  final Map<String, AnalysisCacheEntry> _entries = <String, AnalysisCacheEntry>{};
  bool _loaded = false;

  void _loadSync() {
    if (_loaded) return;
    _loaded = true;
    if (!file.existsSync()) return;
    try {
      final raw = file.readAsStringSync();
      if (raw.trim().isEmpty) return;
      final list = jsonDecode(raw);
      if (list is List) {
        for (final item in list) {
          if (item is Map<String, Object?>) {
            try {
              final entry = AnalysisCacheEntry(
                key: item['key'] as String,
                output: item['output'] as String,
                createdAt: DateTime.parse(item['createdAt'] as String),
              );
              _entries[entry.key] = entry;
            } catch (_) {
              // Ignore corrupted entry
            }
          }
        }
      }
    } catch (_) {
      // Ignore corrupted file
    }
  }

  Future<void> _flush() async {
    final list = _entries.values.map((e) => <String, Object?>{
      'key': e.key,
      'output': e.output,
      'createdAt': e.createdAt.toIso8601String(),
    }).toList();
    await _atomicWriteString(file, jsonEncode(list));
  }

  @override
  Future<void> put(AnalysisCacheEntry entry) async {
    _entries[entry.key] = entry;
    // FIFO eviction if capacity exceeded
    if (_entries.length > maxCapacity) {
      final oldestKey = _entries.entries
          .reduce((a, b) => a.value.createdAt.isBefore(b.value.createdAt) ? a : b)
          .key;
      _entries.remove(oldestKey);
    }
    await _flush();
  }

  @override
  Future<AnalysisCacheEntry?> get(String key) async => _entries[key];

  @override
  Future<void> clear() async {
    _entries.clear();
    await _flush();
  }
}

/// A [FeedbackRepository] that persists feedback to disk.
final class LocalFileFeedbackRepository implements FeedbackRepository {
  LocalFileFeedbackRepository(this.file) {
    _loadSync();
  }

  final File file;
  final List<FeedbackRecord> _records = <FeedbackRecord>[];
  bool _loaded = false;

  void _loadSync() {
    if (_loaded) return;
    _loaded = true;
    if (!file.existsSync()) return;
    try {
      final raw = file.readAsStringSync();
      if (raw.trim().isEmpty) return;
      final list = jsonDecode(raw);
      if (list is List) {
        for (final item in list) {
          if (item is Map<String, Object?>) {
            try {
              final reasonStr = item['reason'] as String?;
              final reason = FeedbackReason.values.firstWhere(
                (r) => r.name == reasonStr,
                orElse: () => FeedbackReason.other,
              );
              final record = FeedbackRecord(
                id: item['id'] as String,
                reason: reason,
                comment: item['comment'] as String?,
                attachedInput: item['attachedInput'] as String?,
                attachedOutput: item['attachedOutput'] as String?,
                createdAt: DateTime.parse(item['createdAt'] as String),
              );
              _records.add(record);
            } catch (_) {
              // Ignore corrupted entry
            }
          }
        }
      }
    } catch (_) {
      // Ignore corrupted file
    }
  }

  Future<void> _flush() async {
    final list = _records.map((r) => <String, Object?>{
      'id': r.id,
      'reason': r.reason.name,
      'comment': r.comment,
      'attachedInput': r.attachedInput,
      'attachedOutput': r.attachedOutput,
      'createdAt': r.createdAt.toIso8601String(),
    }).toList();
    await _atomicWriteString(file, jsonEncode(list));
  }

  @override
  Future<void> save(FeedbackRecord record) async {
    _records.add(record);
    await _flush();
  }

  @override
  Future<List<FeedbackRecord>> listAll() async =>
      List<FeedbackRecord>.unmodifiable(_records);
}

/// Resolves standard directory for LingoLens local storage on Windows / Desktop.
Directory getDefaultStorageDirectory() {
  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return Directory('$appData\\LingoLens');
    }
  }
  final userHome = Platform.environment['USERPROFILE'] ??
      Platform.environment['HOME'] ??
      '.';
  return Directory('$userHome/.lingolens');
}

/// Convenience bundle for instantiating all local file-backed persistence repositories.
final class LocalFilePersistenceBundle {
  LocalFilePersistenceBundle({Directory? baseDirectory}) {
    final dir = baseDirectory ?? getDefaultStorageDirectory();
    final path = dir.path;
    final separator = Platform.pathSeparator;
    history = LocalFileHistoryRepository(File('$path${separator}history.json'));
    favorites = LocalFileFavoriteRepository(File('$path${separator}favorites.json'));
    settings = LocalFileSettingsRepository(File('$path${separator}settings.json'));
    cache = LocalFileAnalysisCacheRepository(File('$path${separator}cache.json'));
    feedback = LocalFileFeedbackRepository(File('$path${separator}feedback.json'));
  }

  late final LocalFileHistoryRepository history;
  late final LocalFileFavoriteRepository favorites;
  late final LocalFileSettingsRepository settings;
  late final LocalFileAnalysisCacheRepository cache;
  late final LocalFileFeedbackRepository feedback;
}
