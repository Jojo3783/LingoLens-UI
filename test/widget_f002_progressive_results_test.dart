import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/analysis_action_contracts.dart';
import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/application/analysis_execution_strategy.dart';
import 'package:lingolens/application/analysis_state.dart';
import 'package:lingolens/application/persistence_controller.dart';
import 'package:lingolens/domain/analysis_models.dart';
import 'package:lingolens/infrastructure/fake_speech_adapter.dart';
import 'package:lingolens/infrastructure/in_memory_persistence.dart';
import 'package:lingolens/presentation/analysis_page.dart';
import 'package:lingolens/presentation/analysis_result_card.dart';

void main() {
  group('F-002 Progressive Disclosure & Unified Result Tests', () {
    testWidgets('Reading mode displays Layer 1, Layer 2, and Layer 3 properly', (
      tester,
    ) async {
      const result = AnalysisResult(
        reading: ReadingAnalysis(
          translation: '這是測試翻譯',
          sentenceAnalysis: '這是一個簡單句結構',
          grammar: '現在式主詞與動詞一致',
          vocabulary: 'test: 測試 (名詞/動詞)',
          nuance: '具有正式且客觀的細微語氣',
        ),
        expression: ExpressionAnalysis(
          natural: 'This is a test natural expression',
          polite: 'This would be a test expression, please',
          formal: 'This constitutes a formal test expression',
          context: 'Used in software testing environments',
          tone: 'Professional and concise',
        ),
        providerLabel: 'Fake Provider',
      );

      final success = AnalysisSuccess(
        requestId: RequestId.create(),
        input: 'this is a test',
        mode: AnalysisMode.reading,
        result: result,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnalysisResultCard(success: success),
            ),
          ),
        ),
      );

      // Layer 1 (Immediate Answer)
      expect(find.byKey(const ValueKey('reading-translation')), findsOneWidget);
      expect(find.text('Translation'), findsOneWidget);
      expect(find.text('這是測試翻譯'), findsOneWidget);

      // Layer 2 (Core Learning Points)
      expect(
        find.byKey(const ValueKey('reading-sentence-analysis')),
        findsOneWidget,
      );
      expect(find.text('Sentence analysis'), findsOneWidget);
      expect(find.text('這是一個簡單句結構'), findsOneWidget);

      expect(find.byKey(const ValueKey('reading-grammar')), findsOneWidget);
      expect(find.text('Grammar'), findsOneWidget);
      expect(find.text('現在式主詞與動詞一致'), findsOneWidget);

      expect(find.byKey(const ValueKey('reading-vocabulary')), findsOneWidget);
      expect(find.text('Vocabulary'), findsOneWidget);
      expect(find.text('test: 測試 (名詞/動詞)'), findsOneWidget);

      // Layer 3 (Deep-dive Nuance)
      expect(find.byKey(const ValueKey('reading-nuance')), findsOneWidget);
      expect(find.text('Nuance'), findsOneWidget);
      expect(find.text('具有正式且客觀的細微語氣'), findsOneWidget);
    });

    testWidgets('Expression mode displays Layer 1 and Layer 2 properly', (
      tester,
    ) async {
      const result = AnalysisResult(
        reading: ReadingAnalysis(
          translation: '測試翻譯',
          sentenceAnalysis: '結構分析',
          grammar: '文法說明',
          vocabulary: '單字說明',
          nuance: '語氣細微差異',
        ),
        expression: ExpressionAnalysis(
          natural: 'Keep up the great work',
          polite: 'Please continue the good work',
          formal: 'Kindly maintain this commendable performance',
          context: 'Workplace encouragement and praise',
          tone: 'Encouraging and friendly',
        ),
        providerLabel: 'Fake Provider',
      );

      final success = AnalysisSuccess(
        requestId: RequestId.create(),
        input: '繼續保持',
        mode: AnalysisMode.expression,
        result: result,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnalysisResultCard(success: success),
            ),
          ),
        ),
      );

      // Layer 1 (Immediate Answer)
      expect(find.byKey(const ValueKey('expression-natural')), findsOneWidget);
      expect(find.text('Natural'), findsOneWidget);
      expect(find.text('Keep up the great work'), findsOneWidget);

      // Layer 2 (Core Learning Points)
      expect(find.byKey(const ValueKey('expression-polite')), findsOneWidget);
      expect(find.text('Polite'), findsOneWidget);
      expect(find.text('Please continue the good work'), findsOneWidget);

      expect(find.byKey(const ValueKey('expression-formal')), findsOneWidget);
      expect(find.text('Formal'), findsOneWidget);
      expect(
        find.text('Kindly maintain this commendable performance'),
        findsOneWidget,
      );

      expect(find.byKey(const ValueKey('expression-context')), findsOneWidget);
      expect(find.text('Context'), findsOneWidget);
      expect(
        find.text('Workplace encouragement and praise'),
        findsOneWidget,
      );

      expect(find.byKey(const ValueKey('expression-tone')), findsOneWidget);
      expect(find.text('Tone'), findsOneWidget);
      expect(find.text('Encouraging and friendly'), findsOneWidget);
    });

    testWidgets('Loading cancellation and Failure retry work end-to-end', (
      tester,
    ) async {
      final controlledProvider = _ControlledDelayedProvider();
      final controller = _createTestController(controlledProvider);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: AnalysisPage(
            controller: controller,
            onFailureScenarioChanged: (_) {},
          ),
        ),
      );

      // 1. Submit input
      await tester.enterText(
        find.byKey(const ValueKey('analysis-input')),
        'Test input for cancellation',
      );
      await tester.tap(find.byKey(const ValueKey('submit-analysis')));
      await tester.pump();

      // Verify Loading & Cancel button
      expect(find.byKey(const ValueKey('cancel-analysis')), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.byKey(const ValueKey('cancel-analysis')));
      await tester.pumpAndSettle();

      expect(find.text('分析已取消。'), findsOneWidget);
      expect(find.byKey(const ValueKey('retry-analysis')), findsOneWidget);

      // 2. Retry triggers new analysis
      await tester.tap(find.byKey(const ValueKey('retry-analysis')));
      await tester.pump();
      expect(find.byKey(const ValueKey('cancel-analysis')), findsOneWidget);

      // Complete analysis
      controlledProvider.completeSuccess();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('reading-result')), findsOneWidget);
    });
  });
}

AnalysisController _createTestController(AnalysisProvider provider) {
  return AnalysisController(
    provider: provider,
    strategy: const FullOnlyStrategy(),
    actionPorts: AnalysisActionPorts(
      persistence: PersistenceController(
        history: InMemoryHistoryRepository(),
        cache: InMemoryAnalysisCacheRepository(),
        settings: InMemorySettingsRepository(),
        favorites: InMemoryFavoriteRepository(),
        feedback: InMemoryFeedbackRepository(),
      ),
      clipboard: const _NoopClipboard(),
      speech: FakeSpeechAdapter(),
      clock: const SystemClock(),
      historyIds: const DeterministicHistoryIdGenerator(),
    ),
  );
}

final class _ControlledDelayedProvider implements AnalysisProvider {
  Completer<AnalysisResult> _completer = Completer<AnalysisResult>();

  @override
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  ) {
    _completer = Completer<AnalysisResult>();
    final c = _completer;
    context.cancellation.addListener(() {
      if (!c.isCompleted) {
        c.completeError(
          const AnalysisProviderException.requestCancelled(),
        );
      }
    });
    return c.future;
  }

  void completeSuccess() {
    if (!_completer.isCompleted) {
      _completer.complete(
        const AnalysisResult(
          reading: ReadingAnalysis(
            translation: '測試成功翻譯',
            sentenceAnalysis: '分析',
            grammar: '文法',
            vocabulary: '單字',
            nuance: '語氣',
          ),
          expression: ExpressionAnalysis(
            natural: 'Natural',
            polite: 'Polite',
            formal: 'Formal',
            context: 'Context',
            tone: 'Tone',
          ),
          providerLabel: 'Controlled Provider',
        ),
      );
    }
  }
}

final class _NoopClipboard implements ClipboardWriter {
  const _NoopClipboard();

  @override
  Future<void> writeText(String text) async {}
}
