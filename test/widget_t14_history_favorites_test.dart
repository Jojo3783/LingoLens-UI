import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/analysis_action_contracts.dart';
import 'package:lingolens/application/analysis_action_controller.dart';
import 'package:lingolens/application/analysis_state.dart';
import 'package:lingolens/application/persistence_controller.dart';
import 'package:lingolens/domain/analysis_models.dart';
import 'package:lingolens/domain/persistence_contracts.dart';
import 'package:lingolens/infrastructure/in_memory_persistence.dart';
import 'package:lingolens/presentation/analysis_action_panel.dart';
import 'package:lingolens/presentation/favorites_page.dart';
import 'package:lingolens/presentation/history_page.dart';

// ── Fake adapters ─────────────────────────────────────────────────────────────

final class _FakeClipboard implements ClipboardWriter {
  @override
  Future<void> writeText(String text) async {}
}

final class _FakeSpeech implements SpeechAdapter {
  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

final class _FakeClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 8, 15);
}

final class _FakeHistoryIds implements HistoryIdGenerator {
  @override
  String idFor(RequestId requestId) => 'history-${requestId.value}';
}

// ── Helpers ───────────────────────────────────────────────────────────────────

PersistenceController _makePersistence() => PersistenceController(
  history: InMemoryHistoryRepository(),
  cache: InMemoryAnalysisCacheRepository(),
  settings: InMemorySettingsRepository(),
  favorites: InMemoryFavoriteRepository(),
  feedback: InMemoryFeedbackRepository(),
);

AnalysisActionController _makeController(PersistenceController persistence) =>
    AnalysisActionController(
      ports: AnalysisActionPorts(
        persistence: persistence,
        clipboard: _FakeClipboard(),
        speech: _FakeSpeech(),
        clock: _FakeClock(),
        historyIds: _FakeHistoryIds(),
      ),
    );

AnalysisSuccess _makeSuccess({String input = 'Hello world'}) =>
    AnalysisSuccess(
      requestId: RequestId.create(),
      input: input,
      mode: AnalysisMode.reading,
      result: const AnalysisResult(
        providerLabel: 'Fake Provider',
        reading: ReadingAnalysis(
          translation: '你好世界',
          sentenceAnalysis: 'S+V+O',
          grammar: 'Simple Present',
          vocabulary: 'Hello, World',
          nuance: 'Friendly',
        ),
        expression: ExpressionAnalysis(
          natural: 'Hello world',
          polite: 'Hello world',
          formal: 'Hello world',
          context: 'General',
          tone: 'Neutral',
        ),
      ),
    );

HistoryRecord _makeRecord({
  String id = 'rec_1',
  String input = 'Hello world',
}) => HistoryRecord(
  id: id,
  input: input,
  mode: AnalysisMode.reading,
  result: const AnalysisResult(
    providerLabel: 'Fake Provider',
    reading: ReadingAnalysis(
      translation: '你好世界',
      sentenceAnalysis: 'S+V+O',
      grammar: 'Simple Present',
      vocabulary: 'Hello, World',
      nuance: 'Friendly',
    ),
    expression: ExpressionAnalysis(
      natural: 'Hello world',
      polite: 'Hello world',
      formal: 'Hello world',
      context: 'General',
      tone: 'Neutral',
    ),
  ),
  createdAt: DateTime(2026, 8, 15),
);

// ── F-001 AnalysisActionPanel tests ──────────────────────────────────────────

void main() {
  group('F-001 AnalysisActionPanel – manual save & direct favorite', () {
    late PersistenceController persistence;
    late AnalysisActionController controller;
    late AnalysisSuccess success;

    setUp(() {
      persistence = _makePersistence();
      controller = _makeController(persistence);
      success = _makeSuccess();
      controller.setSuccess(success);
    });

    testWidgets(
      'analysis result shows unsaved state by default – no auto-save',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalysisActionPanel(
                controller: controller,
                success: success,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 手動儲存按鈕顯示
        expect(find.byKey(const ValueKey('save-action')), findsOneWidget);
        // 未儲存時不顯示 saved-badge
        expect(find.byKey(const ValueKey('saved-badge')), findsNothing);
        // History 未被寫入
        final history = await persistence.visibleHistory();
        expect(history, isEmpty);
      },
    );

    testWidgets(
      'manual save button writes to history and shows saved badge',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalysisActionPanel(
                controller: controller,
                success: success,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('save-action')));
        await tester.pumpAndSettle();

        // 儲存後顯示 saved-badge，save-action 按鈕消失
        expect(find.byKey(const ValueKey('saved-badge')), findsOneWidget);
        expect(find.byKey(const ValueKey('save-action')), findsNothing);

        // History 新增一筆紀錄
        final history = await persistence.visibleHistory();
        expect(history.length, 1);
        expect(history.first.input, 'Hello world');
      },
    );

    testWidgets(
      'direct favorite tap saves to history and marks favorite in one step',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalysisActionPanel(
                controller: controller,
                success: success,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 尚未儲存，直接點「加入最愛」
        await tester.tap(find.byKey(const ValueKey('favorite-toggle')));
        await tester.pumpAndSettle();

        // 同時顯示 saved-badge 與 favorite-badge
        expect(find.byKey(const ValueKey('saved-badge')), findsOneWidget);
        expect(find.byKey(const ValueKey('favorite-badge')), findsOneWidget);
        // save-action 按鈕消失（已儲存）
        expect(find.byKey(const ValueKey('save-action')), findsNothing);

        // History 與 Favorites 各有一筆，且指向同一筆紀錄
        final history = await persistence.visibleHistory();
        final favorites = await persistence.favorites();
        expect(history.length, 1);
        expect(favorites.length, 1);
        expect(favorites.first.historyRecordId, history.first.id);
      },
    );
  });

  // ── F-001 HistoryPage delete dialog tests ────────────────────────────────

  group('F-001 HistoryPage – delete confirmation dialog', () {
    late PersistenceController persistence;

    setUp(() async {
      persistence = _makePersistence();
      await persistence.saveHistory(_makeRecord(id: 'hist_1', input: 'Delete me'));
    });

    testWidgets('cancel in delete dialog keeps the record', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HistoryPage(persistence: persistence)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete me'), findsOneWidget);

      // 點擊刪除按鈕
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // 確認 Dialog 出現
      expect(
        find.byKey(const ValueKey('delete-confirm-dialog')),
        findsOneWidget,
      );

      // 點擊「取消」
      await tester.tap(find.byKey(const ValueKey('delete-cancel-btn')));
      await tester.pumpAndSettle();

      // 紀錄仍存在
      final history = await persistence.visibleHistory();
      expect(history.length, 1);
    });

    testWidgets('confirm in delete dialog removes the record', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HistoryPage(persistence: persistence)),
        ),
      );
      await tester.pumpAndSettle();

      // 點擊刪除按鈕
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // 點擊「確認刪除」
      await tester.tap(find.byKey(const ValueKey('delete-confirm-btn')));
      await tester.pumpAndSettle();

      // History 已清空
      final history = await persistence.visibleHistory();
      expect(history, isEmpty);
    });
  });

  // ── F-001 FavoritesPage unpin-keeps-history test ──────────────────────────

  group('F-001 FavoritesPage – unpin keeps history', () {
    late PersistenceController persistence;

    setUp(() async {
      persistence = _makePersistence();
      await persistence.saveHistory(
        _makeRecord(id: 'hist_fav', input: 'Favorite record'),
      );
      await persistence.setFavorite(
        historyRecordId: 'hist_fav',
        createdAt: DateTime(2026, 8, 15),
        isFavorite: true,
      );
    });

    testWidgets(
      'unpinning removes from favorites but history record remains',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: FavoritesPage(persistence: persistence)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Favorite record'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);

        // 點擊取消最愛
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Favorites 已清空
        final favorites = await persistence.favorites();
        expect(favorites, isEmpty);

        // History 仍保留該筆紀錄
        final history = await persistence.visibleHistory();
        expect(history.length, 1);
        expect(history.first.id, 'hist_fav');
      },
    );
  });

  // ── T-14 原有測試（保持相容）──────────────────────────────────────────────

  group('T-14 History and Favorites UI tests', () {
    late PersistenceController persistence;

    setUp(() {
      persistence = _makePersistence();
    });

    testWidgets('HistoryPage renders empty state when no records exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HistoryPage(persistence: persistence)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('目前沒有歷史紀錄'), findsOneWidget);
    });

    testWidgets('HistoryPage renders records and allows pin to favorite', (
      tester,
    ) async {
      await persistence.saveHistory(
        _makeRecord(id: 'rec_1', input: 'Hello world'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HistoryPage(persistence: persistence)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello world'), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsOneWidget);

      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pumpAndSettle();

      final favorites = await persistence.favorites();
      expect(favorites.length, 1);
      expect(favorites.first.historyRecordId, 'rec_1');
    });

    testWidgets(
      'FavoritesPage renders pinned records and allows unpinning',
      (tester) async {
        final record = HistoryRecord(
          id: 'rec_1',
          input: 'Pinned input text',
          mode: AnalysisMode.expression,
          result: const AnalysisResult(
            providerLabel: 'Fake Provider',
            reading: ReadingAnalysis(
              translation: 'Pinned translation',
              sentenceAnalysis: 'N/A',
              grammar: 'N/A',
              vocabulary: 'N/A',
              nuance: 'N/A',
            ),
            expression: ExpressionAnalysis(
              natural: 'Pinned natural expression',
              polite: 'Polite pinned text',
              formal: 'Formal pinned text',
              context: 'General',
              tone: 'Neutral',
            ),
          ),
          createdAt: DateTime.now(),
        );
        await persistence.saveHistory(record);
        await persistence.setFavorite(
          historyRecordId: 'rec_1',
          createdAt: DateTime.now(),
          isFavorite: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: FavoritesPage(persistence: persistence)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pinned input text'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);

        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        expect(await persistence.favorites(), isEmpty);
      },
    );
  });
}
