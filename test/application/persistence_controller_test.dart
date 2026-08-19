import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/persistence_controller.dart';
import 'package:lingolens/domain/analysis_models.dart';
import 'package:lingolens/domain/persistence_contracts.dart';
import 'package:lingolens/infrastructure/in_memory_persistence.dart';

void main() {
  test('persistence areas remain logically isolated', () async {
    final persistence = _createPersistence();
    final record = _historyRecord('synthetic-history');
    final cache = _cacheEntry('synthetic-cache');

    await persistence.saveHistory(record);
    await persistence.cache(cache);
    await persistence.setFavorite(
      historyRecordId: record.id,
      createdAt: record.createdAt,
      isFavorite: true,
    );

    await persistence.clearCache();

    expect(await persistence.cached(cache.key), isNull);
    expect((await persistence.visibleHistory()).single.id, record.id);
    expect((await persistence.favorites()).single.historyRecordId, record.id);
  });

  test('deleting history does not implicitly clear cache', () async {
    final persistence = _createPersistence();
    final record = _historyRecord('synthetic-delete');
    final cache = _cacheEntry('synthetic-cache-preserved');

    await persistence.saveHistory(record);
    await persistence.cache(cache);
    await persistence.deleteHistory(record.id);

    expect(await persistence.visibleHistory(), isEmpty);
    expect((await persistence.cached(cache.key))?.output, cache.output);
  });

  test('disabled history writes prevent new history records', () async {
    final persistence = _createPersistence();
    await persistence.setHistoryWritesEnabled(false);

    final didWrite = await persistence.saveHistory(
      _historyRecord('synthetic-disabled-write'),
    );

    expect(didWrite, isFalse);
    expect(await persistence.visibleHistory(), isEmpty);
  });

  test('default visible history limit counts favorites', () async {
    final fixture = _createFixture();
    final records = List<HistoryRecord>.generate(
      visibleHistoryLimit + 1,
      (index) => _historyRecord(
        'synthetic-history-$index',
        DateTime.utc(2026, 1, 1).add(Duration(days: index)),
      ),
    );
    for (final record in records) {
      await fixture.persistence.saveHistory(record);
    }
    await fixture.persistence.setFavorite(
      historyRecordId: records.first.id,
      createdAt: records.first.createdAt,
      isFavorite: true,
    );

    final visible = await fixture.persistence.visibleHistory();

    expect(visible.length, visibleHistoryLimit);
    expect(
      visible,
      contains(
        predicate<HistoryRecord>((record) => record.id == records.first.id),
      ),
    );
    expect((await fixture.history.listAll()).length, visibleHistoryLimit + 1);
    expect((await fixture.favorites.listAll()).length, 1);
  });

  test(
    'zero visible history limit returns no records without eviction',
    () async {
      final fixture = _createFixture();
      final record = _historyRecord('synthetic-zero-limit');
      await fixture.persistence.saveHistory(record);
      await fixture.persistence.setFavorite(
        historyRecordId: record.id,
        createdAt: record.createdAt,
        isFavorite: true,
      );

      final visible = await fixture.persistence.visibleHistory(limit: 0);

      expect(visible, isEmpty);
      expect((await fixture.history.listAll()).map((item) => item.id), [
        record.id,
      ]);
      expect(
        (await fixture.favorites.listAll()).map((item) => item.historyRecordId),
        [record.id],
      );
    },
  );

  test('favorites exceeding the limit remain stored and are ordered', () async {
    final fixture = _createFixture();
    final records = List<HistoryRecord>.generate(
      25,
      (index) => _historyRecord(
        'synthetic-favorite-${index.toString().padLeft(2, '0')}',
        DateTime.utc(2026, 1, 1).add(Duration(days: index % 3)),
      ),
    );
    for (final record in records.reversed) {
      await fixture.persistence.saveHistory(record);
      await fixture.persistence.setFavorite(
        historyRecordId: record.id,
        createdAt: record.createdAt,
        isFavorite: true,
      );
    }

    final visible = await fixture.persistence.visibleHistory(limit: 20);
    final expected = records.map((record) => record.id).toList()
      ..sort((left, right) {
        final leftRecord = records.firstWhere((record) => record.id == left);
        final rightRecord = records.firstWhere((record) => record.id == right);
        final dateOrder = rightRecord.createdAt.compareTo(leftRecord.createdAt);
        return dateOrder == 0 ? left.compareTo(right) : dateOrder;
      });

    expect(visible.map((record) => record.id), expected.take(20));
    expect((await fixture.history.listAll()).length, 25);
    expect((await fixture.favorites.listAll()).length, 25);
  });

  test(
    'no favorites returns the newest records in deterministic order',
    () async {
      final fixture = _createFixture();
      final records = List<HistoryRecord>.generate(
        21,
        (index) => _historyRecord(
          'synthetic-newest-$index',
          DateTime.utc(2026, 1, 1).add(Duration(days: index)),
        ),
      );
      for (final record in records.reversed) {
        await fixture.persistence.saveHistory(record);
      }

      final visible = await fixture.persistence.visibleHistory(limit: 20);

      expect(visible.map((record) => record.id), [
        for (var index = 20; index >= 1; index--) 'synthetic-newest-$index',
      ]);
      expect((await fixture.history.listAll()).length, 21);
      expect(
        (await fixture.history.listAll()).map((record) => record.id),
        contains('synthetic-newest-0'),
      );
    },
  );

  test(
    'mixed records use favorite-first and deterministic group ordering',
    () async {
      final fixture = _createFixture();
      final records = <HistoryRecord>[
        _historyRecord('normal-b', DateTime.utc(2026, 1, 3)),
        _historyRecord('fav-c', DateTime.utc(2026, 1, 2)),
        _historyRecord('normal-c', DateTime.utc(2026, 1, 1)),
        _historyRecord('fav-b', DateTime.utc(2026, 1, 3)),
        _historyRecord('normal-a', DateTime.utc(2026, 1, 3)),
        _historyRecord('fav-a', DateTime.utc(2026, 1, 3)),
      ];
      for (final record in records) {
        await fixture.persistence.saveHistory(record);
      }
      for (final id in ['fav-b', 'fav-a', 'fav-c']) {
        final record = records.firstWhere((item) => item.id == id);
        await fixture.persistence.setFavorite(
          historyRecordId: record.id,
          createdAt: record.createdAt,
          isFavorite: true,
        );
      }

      final visible = await fixture.persistence.visibleHistory(limit: 4);

      expect(visible.map((record) => record.id), [
        'fav-a',
        'fav-b',
        'fav-c',
        'normal-a',
      ]);
      expect(visible.length, 4);
    },
  );

  test('negative visible history limit throws without mutation', () async {
    final fixture = _createFixture();
    final record = _historyRecord('synthetic-negative-limit');
    await fixture.persistence.saveHistory(record);
    await fixture.persistence.setFavorite(
      historyRecordId: record.id,
      createdAt: record.createdAt,
      isFavorite: true,
    );

    await expectLater(
      fixture.persistence.visibleHistory(limit: -1),
      throwsArgumentError,
    );
    expect((await fixture.history.listAll()).map((item) => item.id), [
      record.id,
    ]);
    expect(
      (await fixture.favorites.listAll()).map((item) => item.historyRecordId),
      [record.id],
    );
  });

  test('feedback content is attached only with explicit consent', () async {
    final persistence = _createPersistence();

    await persistence.submitFeedback(
      id: 'synthetic-feedback-without-consent',
      reason: FeedbackReason.unhelpful,
      consentToAttachContent: false,
      input: 'synthetic input',
      output: 'synthetic output',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    await persistence.submitFeedback(
      id: 'synthetic-feedback-with-consent',
      reason: FeedbackReason.incorrect,
      consentToAttachContent: true,
      input: 'synthetic input',
      output: 'synthetic output',
      createdAt: DateTime.utc(2026, 1, 2),
    );

    final feedback = await persistence.feedback();
    expect(feedback[0].attachedInput, isNull);
    expect(feedback[0].attachedOutput, isNull);
    expect(feedback[1].attachedInput, 'synthetic input');
    expect(feedback[1].attachedOutput, 'synthetic output');
  });

  test('raw settings read failure maps to PERSISTENCE_FAILED', () async {
    final persistence = _createPersistenceWith(
      settings: _ThrowingSettingsRepository(),
    );

    await _expectPersistenceFailure(
      () => persistence.saveHistory(_historyRecord('synthetic-settings-read')),
    );
  });

  test('raw history save failure maps to PERSISTENCE_FAILED', () async {
    final persistence = _createPersistenceWith(
      history: _ThrowingHistoryRepository(),
    );

    await _expectPersistenceFailure(
      () => persistence.saveHistory(_historyRecord('synthetic-history-save')),
    );
  });

  test('raw settings write failure maps to PERSISTENCE_FAILED', () async {
    final persistence = _createPersistenceWith(
      settings: _ThrowingSettingsRepository(),
    );

    await _expectPersistenceFailure(
      () => persistence.setHistoryWritesEnabled(false),
    );
  });

  test('raw history list failure maps to PERSISTENCE_FAILED', () async {
    final persistence = _createPersistenceWith(
      history: _ThrowingHistoryRepository(),
    );

    await _expectPersistenceFailure(() => persistence.visibleHistory());
  });

  test('raw favorite list failure maps to PERSISTENCE_FAILED', () async {
    final persistence = _createPersistenceWith(
      favorites: _ThrowingFavoriteRepository(),
    );

    await _expectPersistenceFailure(() => persistence.visibleHistory());
  });

  test('raw history delete failure maps to PERSISTENCE_FAILED', () async {
    final persistence = _createPersistenceWith(
      history: _ThrowingHistoryRepository(),
    );

    await _expectPersistenceFailure(
      () => persistence.deleteHistory('synthetic-history-delete'),
    );
  });

  test('raw cache clear failure maps to PERSISTENCE_FAILED', () async {
    final persistence = _createPersistenceWith(
      cache: _ThrowingCacheRepository(),
    );

    await _expectPersistenceFailure(persistence.clearCache);
  });

  test('raw cache write failure maps to PERSISTENCE_FAILED', () async {
    final persistence = _createPersistenceWith(
      cache: _ThrowingCacheRepository(),
    );

    await _expectPersistenceFailure(
      () => persistence.cache(_cacheEntry('synthetic-cache-write')),
    );
  });

  test('raw cache read failure maps to PERSISTENCE_FAILED', () async {
    final persistence = _createPersistenceWith(
      cache: _ThrowingCacheRepository(),
    );

    await _expectPersistenceFailure(
      () => persistence.cached('synthetic-cache-read'),
    );
  });

  test('raw favorite save failure maps to PERSISTENCE_FAILED', () async {
    final persistence = _createPersistenceWith(
      favorites: _ThrowingFavoriteRepository(),
    );

    await _expectPersistenceFailure(
      () => persistence.setFavorite(
        historyRecordId: 'synthetic-favorite-save',
        createdAt: DateTime.utc(2026, 1, 1),
        isFavorite: true,
      ),
    );
  });

  test('raw favorite delete failure maps to PERSISTENCE_FAILED', () async {
    final persistence = _createPersistenceWith(
      favorites: _ThrowingFavoriteRepository(),
    );

    await _expectPersistenceFailure(
      () => persistence.setFavorite(
        historyRecordId: 'synthetic-favorite-delete',
        createdAt: DateTime.utc(2026, 1, 1),
        isFavorite: false,
      ),
    );
  });

  test('raw favorite list operation maps to PERSISTENCE_FAILED', () async {
    final persistence = _createPersistenceWith(
      favorites: _ThrowingFavoriteRepository(),
    );

    await _expectPersistenceFailure(persistence.favorites);
  });

  test('raw feedback save failure maps to PERSISTENCE_FAILED', () async {
    final persistence = _createPersistenceWith(
      feedback: _ThrowingFeedbackRepository(),
    );

    await _expectPersistenceFailure(
      () => persistence.submitFeedback(
        id: 'synthetic-feedback-save',
        reason: FeedbackReason.unhelpful,
        consentToAttachContent: false,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
  });

  test('raw feedback list failure maps to PERSISTENCE_FAILED', () async {
    final persistence = _createPersistenceWith(
      feedback: _ThrowingFeedbackRepository(),
    );

    await _expectPersistenceFailure(persistence.feedback);
  });

  test('negative visible history limit remains ArgumentError', () async {
    final persistence = _createPersistenceWith(
      history: _ThrowingHistoryRepository(),
      favorites: _ThrowingFavoriteRepository(),
    );

    await expectLater(
      persistence.visibleHistory(limit: -1),
      throwsArgumentError,
    );
  });
}

PersistenceController _createPersistence() => _createFixture().persistence;

PersistenceController _createPersistenceWith({
  HistoryRepository? history,
  AnalysisCacheRepository? cache,
  SettingsRepository? settings,
  FavoriteRepository? favorites,
  FeedbackRepository? feedback,
}) => PersistenceController(
  history: history ?? InMemoryHistoryRepository(),
  cache: cache ?? InMemoryAnalysisCacheRepository(),
  settings: settings ?? InMemorySettingsRepository(),
  favorites: favorites ?? InMemoryFavoriteRepository(),
  feedback: feedback ?? InMemoryFeedbackRepository(),
);

Future<void> _expectPersistenceFailure(
  Future<Object?> Function() operation,
) async {
  try {
    await operation();
    fail('Expected a persistence failure.');
  } on AnalysisPersistenceException catch (error) {
    expect(error.error.code, AnalysisErrorCode.persistenceFailed);
    expect(error.error.message, '無法儲存分析結果。');
    expect(
      error.toString(),
      isNot(contains('synthetic raw repository failure')),
    );
  }
}

_PersistenceFixture _createFixture() {
  final history = InMemoryHistoryRepository();
  final cache = InMemoryAnalysisCacheRepository();
  final settings = InMemorySettingsRepository();
  final favorites = InMemoryFavoriteRepository();
  final feedback = InMemoryFeedbackRepository();
  return _PersistenceFixture(
    history: history,
    cache: cache,
    settings: settings,
    favorites: favorites,
    feedback: feedback,
    persistence: PersistenceController(
      history: history,
      cache: cache,
      settings: settings,
      favorites: favorites,
      feedback: feedback,
    ),
  );
}

final class _PersistenceFixture {
  const _PersistenceFixture({
    required this.history,
    required this.cache,
    required this.settings,
    required this.favorites,
    required this.feedback,
    required this.persistence,
  });

  final InMemoryHistoryRepository history;
  final InMemoryAnalysisCacheRepository cache;
  final InMemorySettingsRepository settings;
  final InMemoryFavoriteRepository favorites;
  final InMemoryFeedbackRepository feedback;
  final PersistenceController persistence;
}

final class _ThrowingHistoryRepository implements HistoryRepository {
  Future<T> _failure<T>() =>
      Future<T>.error(StateError('synthetic raw repository failure'));

  @override
  Future<void> save(HistoryRecord record) => _failure<void>();

  @override
  Future<List<HistoryRecord>> listAll() => _failure<List<HistoryRecord>>();

  @override
  Future<void> delete(String recordId) => _failure<void>();

  @override
  Future<void> clear() => _failure<void>();
}

final class _ThrowingCacheRepository implements AnalysisCacheRepository {
  Future<T> _failure<T>() =>
      Future<T>.error(StateError('synthetic raw repository failure'));

  @override
  Future<void> put(AnalysisCacheEntry entry) => _failure<void>();

  @override
  Future<AnalysisCacheEntry?> get(String key) =>
      _failure<AnalysisCacheEntry?>();

  @override
  Future<void> clear() => _failure<void>();
}

final class _ThrowingSettingsRepository implements SettingsRepository {
  Future<T> _failure<T>() =>
      Future<T>.error(StateError('synthetic raw repository failure'));

  @override
  Future<SettingsSnapshot> read() => _failure<SettingsSnapshot>();

  @override
  Future<void> setHistoryWritesEnabled(bool enabled) => _failure<void>();
}

final class _ThrowingFavoriteRepository implements FavoriteRepository {
  Future<T> _failure<T>() =>
      Future<T>.error(StateError('synthetic raw repository failure'));

  @override
  Future<void> save(FavoriteRecord record) => _failure<void>();

  @override
  Future<List<FavoriteRecord>> listAll() => _failure<List<FavoriteRecord>>();

  @override
  Future<void> delete(String historyRecordId) => _failure<void>();
}

final class _ThrowingFeedbackRepository implements FeedbackRepository {
  Future<T> _failure<T>() =>
      Future<T>.error(StateError('synthetic raw repository failure'));

  @override
  Future<void> save(FeedbackRecord record) => _failure<void>();

  @override
  Future<List<FeedbackRecord>> listAll() => _failure<List<FeedbackRecord>>();
}

HistoryRecord _historyRecord(String id, [DateTime? createdAt]) => HistoryRecord(
  id: id,
  input: id,
  mode: AnalysisMode.reading,
  result: AnalysisResult(
    providerLabel: 'Synthetic Test Provider',
    reading: ReadingAnalysis(
      translation: id,
      sentenceAnalysis: 'synthetic sentence',
      grammar: 'synthetic grammar',
      vocabulary: 'synthetic vocabulary',
      nuance: 'synthetic nuance',
    ),
    expression: ExpressionAnalysis(
      natural: id,
      polite: id,
      formal: id,
      context: id,
      tone: id,
    ),
  ),
  createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
);

AnalysisCacheEntry _cacheEntry(String key) => AnalysisCacheEntry(
  key: key,
  output: 'synthetic cache output',
  createdAt: DateTime.utc(2026, 1, 1),
);
