import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/application/persistence_controller.dart';
import 'package:lingolens/application/provider_settings_controller.dart';
import 'package:lingolens/domain/analysis_models.dart';
import 'package:lingolens/domain/persistence_contracts.dart';
import 'package:lingolens/domain/provider_contracts.dart';
import 'package:lingolens/infrastructure/fake_analysis_provider.dart';
import 'package:lingolens/infrastructure/in_memory_persistence.dart';
import 'package:lingolens/infrastructure/openai/secure_credential_store.dart';
import 'package:lingolens/presentation/navigation_shell.dart';
import 'package:lingolens/presentation/review_page.dart';

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

AnalysisResult _syntheticReadingResult(String translation) {
  return AnalysisResult(
    providerLabel: 'fake',
    reading: ReadingAnalysis(
      translation: translation,
      sentenceAnalysis: 'S + V + O structure.',
      grammar: 'Simple Present tense.',
      vocabulary: 'synthetic: synthesized for testing',
      nuance: 'Neutral and informative.',
    ),
    expression: const ExpressionAnalysis(
      natural: 'natural',
      polite: 'polite',
      formal: 'formal',
      context: 'context',
      tone: 'tone',
    ),
  );
}

void main() {
  group('F-004 Low-Pressure Review UI Tests', () {
    late InMemoryHistoryRepository historyRepo;
    late InMemoryFavoriteRepository favoriteRepo;
    late PersistenceController persistence;
    late ProviderSettingsController settingsController;

    setUp(() async {
      historyRepo = InMemoryHistoryRepository();
      favoriteRepo = InMemoryFavoriteRepository();
      persistence = PersistenceController(
        history: historyRepo,
        cache: InMemoryAnalysisCacheRepository(),
        settings: InMemorySettingsRepository(),
        favorites: favoriteRepo,
        feedback: InMemoryFeedbackRepository(),
      );
      settingsController = ProviderSettingsController(
        credentials: InMemorySecureCredentialStore(),
      );
      await settingsController.initialize();
    });

    testWidgets('shows empty state when no favorites exist in past 10 days', (
      tester,
    ) async {
      _setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewPage(persistence: persistence),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('最近 10 天沒有可複習的收藏'), findsOneWidget);
      expect(find.byKey(const ValueKey('review-refresh-btn')), findsOneWidget);
    });

    testWidgets(
      'runs flashcard flow: prompt -> reveal -> feedback -> next -> complete',
      (tester) async {
        _setViewport(tester);

        // 建立 2 筆 10 天內的收藏紀錄
        final now = DateTime.now();
        final rec1 = HistoryRecord(
          id: 'rec-1',
          input: 'She reads a book every night.',
          mode: AnalysisMode.reading,
          result: _syntheticReadingResult('她每天晚上讀一本書。'),
          createdAt: now.subtract(const Duration(days: 1)),
        );
        final rec2 = HistoryRecord(
          id: 'rec-2',
          input: 'He plays tennis on weekends.',
          mode: AnalysisMode.reading,
          result: _syntheticReadingResult('他週末打網球。'),
          createdAt: now.subtract(const Duration(days: 2)),
        );

        await historyRepo.save(rec1);
        await historyRepo.save(rec2);
        await persistence.setFavorite(
          historyRecordId: 'rec-1',
          createdAt: now.subtract(const Duration(days: 1)),
          isFavorite: true,
        );
        await persistence.setFavorite(
          historyRecordId: 'rec-2',
          createdAt: now.subtract(const Duration(days: 2)),
          isFavorite: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReviewPage(persistence: persistence),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. 第一筆 Prompt 階段
        expect(find.byKey(const ValueKey('review-progress-label')), findsOneWidget);
        expect(find.byKey(const ValueKey('review-progress-bar')), findsOneWidget);
        expect(find.text('第 1 / 2 筆'), findsOneWidget);
        expect(find.text('She reads a book every night.'), findsOneWidget);
        expect(find.text('在心中回想這句話的意思、重點文法或語氣...'), findsOneWidget);
        expect(find.byKey(const ValueKey('review-reveal-btn')), findsOneWidget);
        expect(find.byKey(const ValueKey('review-tts-btn')), findsOneWidget);
        // 尚未揭示時不應看見答案
        expect(find.text('她每天晚上讀一本書。'), findsNothing);

        // 測試 TTS 發音點擊
        await tester.tap(find.byKey(const ValueKey('review-tts-btn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('review-tts-snackbar')), findsOneWidget);

        // 2. 點擊查看解析 (Reveal)
        await tester.tap(find.byKey(const ValueKey('review-reveal-btn')));
        await tester.pumpAndSettle();

        // 3. Revealed 階段：答案揭示且出現三段回饋與 Accordion 控制
        expect(find.text('她每天晚上讀一本書。'), findsOneWidget);
        expect(find.byKey(const ValueKey('review-revealed-tts-btn')), findsOneWidget);
        expect(find.byKey(const ValueKey('accordion-toggle-all-btn')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('review-feedback-needs-practice-btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('review-feedback-getting-there-btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('review-feedback-mastered-btn')),
          findsOneWidget,
        );

        // 測試 Accordion 全部展開/收起
        await tester.tap(find.byKey(const ValueKey('accordion-toggle-all-btn')));
        await tester.pumpAndSettle();
        expect(find.text('全部收起'), findsOneWidget);

        // 4. 點擊回饋「已熟悉」進入第 2 筆
        await tester.tap(
          find.byKey(const ValueKey('review-feedback-mastered-btn')),
        );
        await tester.pumpAndSettle();

        // 5. 第二筆 Prompt 階段
        expect(find.text('第 2 / 2 筆'), findsOneWidget);
        expect(find.text('He plays tennis on weekends.'), findsOneWidget);

        // 揭示第二筆
        await tester.tap(find.byKey(const ValueKey('review-reveal-btn')));
        await tester.pumpAndSettle();
        expect(find.text('他週末打網球。'), findsOneWidget);

        // 回饋第二筆「差不多了」
        await tester.tap(
          find.byKey(const ValueKey('review-feedback-getting-there-btn')),
        );
        await tester.pumpAndSettle();

        // 6. Session 完成頁面
        expect(find.text('🎉 太棒了！已完成回想練習'), findsOneWidget);
        expect(find.textContaining('本次已回想 2 筆收藏重點'), findsOneWidget);
        expect(find.byKey(const ValueKey('review-restart-btn')), findsOneWidget);
      },
    );

    testWidgets('swiping card left submits needsPractice and right submits mastered', (
      tester,
    ) async {
      _setViewport(tester);
      final now = DateTime.now();
      final rec1 = HistoryRecord(
        id: 'rec-1',
        input: 'Swipe Left Card',
        mode: AnalysisMode.reading,
        result: _syntheticReadingResult('向左滑卡片'),
        createdAt: now,
      );
      final rec2 = HistoryRecord(
        id: 'rec-2',
        input: 'Swipe Right Card',
        mode: AnalysisMode.reading,
        result: _syntheticReadingResult('向右滑卡片'),
        createdAt: now,
      );

      await historyRepo.save(rec1);
      await historyRepo.save(rec2);
      await persistence.setFavorite(
        historyRecordId: 'rec-1',
        createdAt: now,
        isFavorite: true,
      );
      await persistence.setFavorite(
        historyRecordId: 'rec-2',
        createdAt: now,
        isFavorite: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewPage(persistence: persistence),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 揭示第一筆
      await tester.tap(find.byKey(const ValueKey('review-reveal-btn')));
      await tester.pumpAndSettle();

      // 向左滑動 -> 觸發 needsPractice
      await tester.drag(
        find.text('原始文字'),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();

      // 進入第二筆
      expect(find.text('Swipe Right Card'), findsOneWidget);

      // 揭示第二筆
      await tester.tap(find.byKey(const ValueKey('review-reveal-btn')));
      await tester.pumpAndSettle();

      // 向右滑動 -> 觸發 mastered
      await tester.drag(
        find.text('原始文字'),
        const Offset(300, 0),
      );
      await tester.pumpAndSettle();

      // 完成
      expect(find.text('🎉 太棒了！已完成回想練習'), findsOneWidget);
    });

    testWidgets('skipping a card advances without negative marks', (
      tester,
    ) async {
      _setViewport(tester);
      final now = DateTime.now();
      final rec1 = HistoryRecord(
        id: 'rec-1',
        input: 'Card 1',
        mode: AnalysisMode.reading,
        result: _syntheticReadingResult('卡片 1 翻譯'),
        createdAt: now,
      );
      final rec2 = HistoryRecord(
        id: 'rec-2',
        input: 'Card 2',
        mode: AnalysisMode.reading,
        result: _syntheticReadingResult('卡片 2 翻譯'),
        createdAt: now,
      );

      await historyRepo.save(rec1);
      await historyRepo.save(rec2);
      await persistence.setFavorite(
        historyRecordId: 'rec-1',
        createdAt: now,
        isFavorite: true,
      );
      await persistence.setFavorite(
        historyRecordId: 'rec-2',
        createdAt: now,
        isFavorite: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewPage(persistence: persistence),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('第 1 / 2 筆'), findsOneWidget);

      // 點擊略過按鈕
      await tester.tap(find.byKey(const ValueKey('review-skip-btn')));
      await tester.pumpAndSettle();

      // 直接前往第 2 筆
      expect(find.text('第 2 / 2 筆'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);
    });

    testWidgets('navigation shell includes Review destination and displays ReviewPage', (
      tester,
    ) async {
      _setViewport(tester);
      final analysisController = AnalysisController(
        provider: FakeAnalysisProvider(),
      );
      addTearDown(analysisController.dispose);
      addTearDown(settingsController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: LingoLensNavigationShell(
            controller: analysisController,
            providerDisclosure: null,
            onFailureScenarioChanged: (_) {},
            selectedProvider: ProviderKind.fake,
            onProviderChanged: (_) {},
            settings: settingsController,
            onCredentialChanged: () {},
            persistence: persistence,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 打開選單 Drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // 點擊「複習」選單項
      expect(find.text('複習'), findsOneWidget);
      await tester.tap(find.text('複習'));
      await tester.pumpAndSettle();

      // 成功切換至 ReviewPage (顯示空狀態)
      expect(find.text('最近 10 天沒有可複習的收藏'), findsOneWidget);
    });
  });
}
