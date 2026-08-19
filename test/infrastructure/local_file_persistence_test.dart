import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/domain/analysis_models.dart';
import 'package:lingolens/domain/persistence_contracts.dart';
import 'package:lingolens/infrastructure/local_file_persistence.dart';

void main() {
  late Directory tempDir;
  late LocalFilePersistenceBundle bundle;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lingolens_persist_test_');
    bundle = LocalFilePersistenceBundle(baseDirectory: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  HistoryRecord createSampleRecord({
    String id = 'hist_1',
    String input = 'Hello World',
    AnalysisMode mode = AnalysisMode.reading,
  }) {
    return HistoryRecord(
      id: id,
      input: input,
      mode: mode,
      result: const AnalysisResult(
        providerLabel: 'Fake Provider',
        reading: ReadingAnalysis(
          translation: '你好世界',
          sentenceAnalysis: 'S + V + O',
          grammar: 'Present Simple',
          vocabulary: 'Hello, World',
          nuance: 'Friendly',
        ),
        expression: ExpressionAnalysis(
          natural: 'Hello World',
          polite: 'Hello World',
          formal: 'Hello World',
          context: 'Greeting',
          tone: 'Warm',
        ),
      ),
      createdAt: DateTime(2026, 8, 15, 10, 0),
    );
  }

  test('LocalFileHistoryRepository saves and survives repository restart', () async {
    final record = createSampleRecord(id: 'hist_persisted', input: 'Persistent test');
    await bundle.history.save(record);

    final initialList = await bundle.history.listAll();
    expect(initialList.length, 1);
    expect(initialList.first.input, 'Persistent test');

    // Simulate App restart by creating a new bundle pointing to the same folder
    final restartedBundle = LocalFilePersistenceBundle(baseDirectory: tempDir);
    final restoredList = await restartedBundle.history.listAll();

    expect(restoredList.length, 1);
    expect(restoredList.first.id, 'hist_persisted');
    expect(restoredList.first.input, 'Persistent test');
    expect(restoredList.first.result.reading.translation, '你好世界');
  });

  test('LocalFileFavoriteRepository saves and survives repository restart', () async {
    final fav = FavoriteRecord(
      historyRecordId: 'hist_persisted',
      createdAt: DateTime(2026, 8, 15, 10, 5),
    );
    await bundle.favorites.save(fav);

    // Recreate bundle
    final restartedBundle = LocalFilePersistenceBundle(baseDirectory: tempDir);
    final restoredFavorites = await restartedBundle.favorites.listAll();

    expect(restoredFavorites.length, 1);
    expect(restoredFavorites.first.historyRecordId, 'hist_persisted');
  });

  test('LocalFileSettingsRepository persists historyWritesEnabled', () async {
    expect((await bundle.settings.read()).historyWritesEnabled, isTrue);

    await bundle.settings.setHistoryWritesEnabled(false);
    expect((await bundle.settings.read()).historyWritesEnabled, isFalse);

    // Recreate bundle
    final restartedBundle = LocalFilePersistenceBundle(baseDirectory: tempDir);
    expect((await restartedBundle.settings.read()).historyWritesEnabled, isFalse);
  });

  test('LocalFileAnalysisCacheRepository enforces max capacity FIFO eviction', () async {
    for (int i = 0; i < 35; i++) {
      await bundle.cache.put(AnalysisCacheEntry(
        key: 'key_$i',
        output: 'output_$i',
        createdAt: DateTime(2026, 8, 15, 10, i),
      ));
    }

    // Capacity is 30, so oldest 5 entries (0 to 4) should be evicted
    expect(await bundle.cache.get('key_0'), isNull);
    expect(await bundle.cache.get('key_4'), isNull);
    expect(await bundle.cache.get('key_34'), isNotNull);
  });
}
