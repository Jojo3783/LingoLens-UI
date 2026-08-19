import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/analysis_action_contracts.dart';
import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/application/analysis_state.dart';
import 'package:lingolens/application/persistence_controller.dart';
import 'package:lingolens/domain/analysis_models.dart';
import 'package:lingolens/infrastructure/fake_analysis_provider.dart';
import 'package:lingolens/infrastructure/fake_speech_adapter.dart';
import 'package:lingolens/infrastructure/in_memory_persistence.dart';
import 'package:lingolens/presentation/analysis_page.dart';

void main() {
  testWidgets('提交後顯示 typed Fake Provider result', (tester) async {
    final controller = AnalysisController(
      provider: FakeAnalysisProvider(delay: Duration.zero),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisPage(
          controller: controller,
          onFailureScenarioChanged: (_) {},
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('analysis-input')),
      'hello',
    );
    final submit = find.byKey(const ValueKey('submit-analysis'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(
      find.text('Fake Provider（deterministic development data）'),
      findsOneWidget,
    );
    expect(find.textContaining('FAKE TRANSLATION: hello'), findsOneWidget);
  });

  testWidgets('loading 可取消並顯示 cancelled state', (tester) async {
    final controller = AnalysisController(
      provider: FakeAnalysisProvider(delay: const Duration(seconds: 1)),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisPage(
          controller: controller,
          onFailureScenarioChanged: (_) {},
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('analysis-input')),
      'slow',
    );
    final submit = find.byKey(const ValueKey('submit-analysis'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('分析中…'), findsOneWidget);

    final cancel = find.byKey(const ValueKey('cancel-analysis'));
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pump();
    expect(find.text('分析已取消。'), findsOneWidget);
  });

  testWidgets('typed Provider failure 可顯示並支援重試', (tester) async {
    final provider = FakeAnalysisProvider(
      delay: Duration.zero,
      shouldFail: true,
    );
    final controller = AnalysisController(provider: provider);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisPage(
          controller: controller,
          onFailureScenarioChanged: (_) {},
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('analysis-input')),
      'retry',
    );
    final submit = find.byKey(const ValueKey('submit-analysis'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.textContaining('providerFailed'), findsOneWidget);

    provider.shouldFail = false;
    controller.retry();
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('FAKE TRANSLATION: retry'), findsOneWidget);
  });

  testWidgets('T-07 Expression UI exposes only mode-specific result actions', (
    tester,
  ) async {
    final controller = AnalysisController(
      provider: FakeAnalysisProvider(delay: Duration.zero),
      actionPorts: AnalysisActionPorts(
        persistence: PersistenceController(
          history: InMemoryHistoryRepository(),
          cache: InMemoryAnalysisCacheRepository(),
          settings: InMemorySettingsRepository(),
          favorites: InMemoryFavoriteRepository(),
          feedback: InMemoryFeedbackRepository(),
        ),
        clipboard: _WidgetClipboard(),
        speech: FakeSpeechAdapter(),
        clock: const SystemClock(),
        historyIds: const DeterministicHistoryIdGenerator(),
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisPage(
          controller: controller,
          onFailureScenarioChanged: (_) {},
        ),
      ),
    );
    controller.selectMode(AnalysisMode.expression);
    await tester.pump();
    expect(find.text('Manual override: Expression'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('analysis-input')),
      'expression input',
    );
    final submit = find.byKey(const ValueKey('submit-analysis'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(
      find.textContaining('FAKE NATURAL: expression input'),
      findsOneWidget,
    );
    expect(find.textContaining('FAKE TRANSLATION:'), findsNothing);
    expect(find.text('Listen（Fake）'), findsOneWidget);
    expect(find.text('加入最愛'), findsOneWidget);
    expect(find.byKey(const ValueKey('feedback-submit')), findsOneWidget);
  });

  testWidgets('T-07R Mode Dropdown tracks effective mode and submitted mode', (
    tester,
  ) async {
    final controller = AnalysisController(
      provider: FakeAnalysisProvider(delay: Duration.zero),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    final selector = find.byKey(const ValueKey('mode-selector'));
    expect(
      find.descendant(of: selector, matching: find.text('Reading')),
      findsOneWidget,
    );

    controller.selectMode(AnalysisMode.expression);
    await tester.pump();
    expect(
      find.descendant(of: selector, matching: find.text('Expression')),
      findsOneWidget,
    );
    expect(find.text('Manual override: Expression'), findsOneWidget);

    final useSuggestion = find.byKey(const ValueKey('use-suggestion'));
    await tester.ensureVisible(useSuggestion);
    await tester.tap(useSuggestion);
    await tester.pump();
    expect(
      find.descendant(of: selector, matching: find.text('Reading')),
      findsOneWidget,
    );
    expect(find.text('Using suggestion: Reading'), findsOneWidget);

    controller.submit('suggested mode request');
    await tester.pump();
    expect((controller.state as AnalysisSuccess).mode, AnalysisMode.reading);
  });

  testWidgets('T-07R Feedback state resets at a new RequestId boundary', (
    tester,
  ) async {
    final feedback = InMemoryFeedbackRepository();
    final controller = _actionController(feedback: feedback);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    await _submitText(tester, 'request A');
    await _chooseFeedbackReason(tester, 'Incorrect');
    await tester.enterText(
      find.byKey(const ValueKey('feedback-comment')),
      'old comment',
    );
    final consent = find.byKey(const ValueKey('feedback-consent'));
    await tester.ensureVisible(consent);
    await tester.tap(consent);

    controller.submit('request B');
    await tester.pump();

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('feedback-comment')))
          .controller!
          .text,
      isEmpty,
    );
    expect(tester.widget<CheckboxListTile>(consent).value, isFalse);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('feedback-submit')))
          .onPressed,
      isNull,
    );

    await _chooseFeedbackReason(tester, 'Other');
    final feedbackSubmit = find.byKey(const ValueKey('feedback-submit'));
    await tester.ensureVisible(feedbackSubmit);
    await tester.tap(feedbackSubmit);
    await tester.pump();

    expect((await feedback.listAll()).last.attachedInput, isNull);
    expect((await feedback.listAll()).last.attachedOutput, isNull);
  });
}

Widget _pageFor(AnalysisController controller) => MaterialApp(
  home: AnalysisPage(controller: controller, onFailureScenarioChanged: (_) {}),
);

AnalysisController _actionController({InMemoryFeedbackRepository? feedback}) =>
    AnalysisController(
      provider: FakeAnalysisProvider(delay: Duration.zero),
      actionPorts: AnalysisActionPorts(
        persistence: PersistenceController(
          history: InMemoryHistoryRepository(),
          cache: InMemoryAnalysisCacheRepository(),
          settings: InMemorySettingsRepository(),
          favorites: InMemoryFavoriteRepository(),
          feedback: feedback ?? InMemoryFeedbackRepository(),
        ),
        clipboard: _WidgetClipboard(),
        speech: FakeSpeechAdapter(),
        clock: const SystemClock(),
        historyIds: const DeterministicHistoryIdGenerator(),
      ),
    );

Future<void> _submitText(WidgetTester tester, String input) async {
  await tester.enterText(find.byKey(const ValueKey('analysis-input')), input);
  final submit = find.byKey(const ValueKey('submit-analysis'));
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pump();
}

Future<void> _chooseFeedbackReason(WidgetTester tester, String reason) async {
  final field = find.byKey(const ValueKey('feedback-reason'));
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(reason).last);
  await tester.pump();
}

final class _WidgetClipboard implements ClipboardWriter {
  @override
  Future<void> writeText(String text) async {}
}
