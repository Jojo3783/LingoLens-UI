import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/analysis_action_contracts.dart';
import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/application/persistence_controller.dart';
import 'package:lingolens/domain/analysis_models.dart';
import 'package:lingolens/domain/persistence_contracts.dart';
import 'package:lingolens/infrastructure/fake_analysis_provider.dart';
import 'package:lingolens/infrastructure/fake_speech_adapter.dart';
import 'package:lingolens/infrastructure/in_memory_persistence.dart';
import 'package:lingolens/presentation/analysis_page.dart';

void main() {
  testWidgets('Reading hierarchy places quick actions after Translation', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    controller.submit('reading hierarchy');
    await tester.pump();

    final labels = [
      'Translation',
      'Copy',
      'Listen（Fake）',
      'Sentence analysis',
      'Grammar',
      'Vocabulary',
      'Nuance',
    ];
    final positions = labels
        .map((label) => tester.getTopLeft(find.text(label)).dy)
        .toList();
    expect(positions, orderedEquals([...positions]..sort()));
    expect(find.byKey(const ValueKey('reading-translation')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reading-sentence-analysis')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('reading-grammar')), findsOneWidget);
    expect(find.byKey(const ValueKey('reading-vocabulary')), findsOneWidget);
    expect(find.byKey(const ValueKey('reading-nuance')), findsOneWidget);
    expect(find.byKey(const ValueKey('reading-quick-actions')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('expression-quick-actions')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('reading-session-actions')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('expression-session-actions')),
      findsNothing,
    );
    expect(find.bySemanticsLabel('Sentence analysis'), findsWidgets);
    expect(find.bySemanticsLabel('複製主要翻譯'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Translation: FAKE TRANSLATION: reading hierarchy'),
      findsOneWidget,
    );
  });

  testWidgets('Reading Copy and Fake Listen use Translation', (tester) async {
    final clipboard = _RecordingClipboard();
    final speech = _RecordingSpeech();
    final controller = _controller(clipboard: clipboard, speech: speech);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    controller.submit('primary reading');
    await tester.pump();

    await _tapAction(tester, 'copy-result');
    await _tapAction(tester, 'listen-fake');

    expect(clipboard.lastText, 'FAKE TRANSLATION: primary reading');
    expect(speech.lastText, 'FAKE TRANSLATION: primary reading');
  });

  testWidgets('Expression exposes mode-aware actions and Natural output', (
    tester,
  ) async {
    final clipboard = _RecordingClipboard();
    final speech = _RecordingSpeech();
    final feedback = InMemoryFeedbackRepository();
    final controller = _controller(
      clipboard: clipboard,
      speech: speech,
      feedback: feedback,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    controller.selectMode(AnalysisMode.expression);
    controller.submit('expression actions');
    await tester.pump();

    expect(
      find.byKey(const ValueKey('expression-quick-actions')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('expression-session-actions')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('reading-quick-actions')), findsNothing);
    expect(find.byKey(const ValueKey('reading-session-actions')), findsNothing);
    expect(find.bySemanticsLabel('Expression quick actions'), findsOneWidget);
    expect(find.bySemanticsLabel('Expression session actions'), findsOneWidget);
    expect(find.bySemanticsLabel('Reading quick actions'), findsNothing);
    expect(find.bySemanticsLabel('Reading session actions'), findsNothing);
    expect(find.bySemanticsLabel('複製 Natural 結果'), findsOneWidget);
    expect(find.bySemanticsLabel('朗讀 Natural 結果（Fake）'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Natural: FAKE NATURAL: expression actions'),
      findsOneWidget,
    );
    for (final entry in const <String, String>{
      'expression-natural': 'Natural',
      'expression-polite': 'Polite',
      'expression-formal': 'Formal',
      'expression-context': 'Context',
      'expression-tone': 'Tone',
    }.entries) {
      expect(find.byKey(ValueKey(entry.key)), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          '${entry.value}: FAKE ${entry.value.toUpperCase()}: expression actions',
        ),
        findsOneWidget,
      );
    }

    await _tapAction(tester, 'copy-result');
    await _tapAction(tester, 'listen-fake');
    expect(clipboard.lastText, 'FAKE NATURAL: expression actions');
    expect(speech.lastText, 'FAKE NATURAL: expression actions');

    await _tapAction(tester, 'favorite-toggle');
    await _chooseFeedbackReason(tester, 'Other');
    await _tapAction(tester, 'feedback-submit');

    final records = await feedback.listAll();
    expect(records, hasLength(1));
    expect(records.single.attachedInput, isNull);
    expect(records.single.attachedOutput, isNull);
  });

  testWidgets('Expression consent attaches Natural output only', (
    tester,
  ) async {
    final feedback = InMemoryFeedbackRepository();
    final controller = _controller(feedback: feedback);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    controller.selectMode(AnalysisMode.expression);
    controller.submit('expression consent');
    await tester.pump();
    await _chooseFeedbackReason(tester, 'Other');
    await tester.tap(find.byKey(const ValueKey('feedback-consent')));
    await tester.pump();
    await _tapAction(tester, 'feedback-submit');

    final record = (await feedback.listAll()).single;
    expect(record.attachedInput, 'expression consent');
    expect(record.attachedOutput, 'FAKE NATURAL: expression consent');
  });

  testWidgets('Mode switching replaces action semantics without stale labels', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    controller.submit('reading before expression');
    await tester.pump();
    expect(find.bySemanticsLabel('Reading quick actions'), findsOneWidget);

    controller.selectMode(AnalysisMode.expression);
    controller.submit('expression after reading');
    await tester.pump();

    expect(find.bySemanticsLabel('Reading quick actions'), findsNothing);
    expect(find.bySemanticsLabel('Reading session actions'), findsNothing);
    expect(find.byKey(const ValueKey('reading-quick-actions')), findsNothing);
    expect(find.byKey(const ValueKey('reading-session-actions')), findsNothing);
    expect(find.bySemanticsLabel('Expression quick actions'), findsOneWidget);
    expect(find.bySemanticsLabel('Expression session actions'), findsOneWidget);
  });

  testWidgets('Reading result identity survives action-state rebuild', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    controller.submit('stable selection surface');
    await tester.pump();
    final resultElement = tester.element(
      find.byKey(const ValueKey('reading-result')),
    );
    final translationElement = tester.element(
      find.byKey(const ValueKey('reading-translation')),
    );

    await _tapAction(tester, 'copy-result');
    await _tapAction(tester, 'listen-fake');
    await _tapAction(tester, 'favorite-toggle');

    expect(
      tester.element(find.byKey(const ValueKey('reading-result'))),
      same(resultElement),
    );
    expect(
      tester.element(find.byKey(const ValueKey('reading-translation'))),
      same(translationElement),
    );
    expect(find.byType(SelectionArea), findsOneWidget);
  });

  testWidgets('Reading session actions remain operable', (tester) async {
    final feedback = InMemoryFeedbackRepository();
    final controller = _controller(feedback: feedback);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    controller.submit('session actions');
    await tester.pump();

    await _tapAction(tester, 'favorite-toggle');
    expect(find.byKey(const ValueKey('favorite-badge')), findsOneWidget);

    final feedbackReason = find.byKey(const ValueKey('feedback-reason'));
    await tester.ensureVisible(feedbackReason);
    await tester.tap(feedbackReason);
    await tester.pump();
    await tester.tap(find.text('Other').last);
    await tester.pump();

    await _tapAction(tester, 'feedback-submit');
    final records = await feedback.listAll();
    expect(records, hasLength(1));
    expect(records.single.reason, FeedbackReason.other);
    expect(records.single.attachedInput, isNull);
    expect(records.single.attachedOutput, isNull);
    expect(find.text('Feedback 已送出'), findsOneWidget);
  });

  testWidgets('Reading long output scrolls to Nuance at desktop widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _controller(provider: _LongReadingProvider());
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    controller.submit('long reading');
    await tester.pump();
    final nuance = find.byKey(const ValueKey('reading-nuance'));
    await tester.ensureVisible(nuance);

    expect(nuance, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reading narrow viewport wraps without horizontal overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(520, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _controller(provider: _LongReadingProvider());
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    controller.submit('narrow reading');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('reading-nuance')));

    expect(find.byKey(const ValueKey('reading-nuance')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Expression long output scrolls to Tone at desktop widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _controller(provider: _LongReadingProvider());
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    controller.selectMode(AnalysisMode.expression);
    controller.submit('long expression');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('expression-tone')));

    expect(find.byKey(const ValueKey('expression-tone')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Expression narrow viewport wraps without horizontal overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(520, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _controller(provider: _LongReadingProvider());
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    controller.selectMode(AnalysisMode.expression);
    controller.submit('narrow expression');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('expression-tone')));

    expect(find.byKey(const ValueKey('expression-tone')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Expression regression excludes Reading sections', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));
    controller.selectMode(AnalysisMode.expression);
    controller.submit('expression regression');
    await tester.pump();

    expect(find.byKey(const ValueKey('expression-natural')), findsOneWidget);
    expect(find.byKey(const ValueKey('expression-polite')), findsOneWidget);
    expect(find.byKey(const ValueKey('expression-formal')), findsOneWidget);
    expect(find.byKey(const ValueKey('expression-context')), findsOneWidget);
    expect(find.byKey(const ValueKey('expression-tone')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reading-sentence-analysis')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('reading-grammar')), findsNothing);
    expect(find.byKey(const ValueKey('reading-vocabulary')), findsNothing);
    expect(find.byKey(const ValueKey('reading-nuance')), findsNothing);
    expect(find.textContaining('FAKE TRANSLATION:'), findsNothing);
    expect(
      find.textContaining('FAKE NATURAL: expression regression'),
      findsOneWidget,
    );
  });
}

Widget _pageFor(AnalysisController controller) => MaterialApp(
  home: AnalysisPage(controller: controller, onFailureScenarioChanged: (_) {}),
);

Future<void> _tapAction(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
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

AnalysisController _controller({
  AnalysisProvider? provider,
  ClipboardWriter? clipboard,
  SpeechAdapter? speech,
  InMemoryFeedbackRepository? feedback,
}) => AnalysisController(
  provider: provider ?? FakeAnalysisProvider(delay: Duration.zero),
  actionPorts: AnalysisActionPorts(
    persistence: PersistenceController(
      history: InMemoryHistoryRepository(),
      cache: InMemoryAnalysisCacheRepository(),
      settings: InMemorySettingsRepository(),
      favorites: InMemoryFavoriteRepository(),
      feedback: feedback ?? InMemoryFeedbackRepository(),
    ),
    clipboard: clipboard ?? _RecordingClipboard(),
    speech: speech ?? FakeSpeechAdapter(),
    clock: const SystemClock(),
    historyIds: const DeterministicHistoryIdGenerator(),
  ),
);

final class _RecordingClipboard implements ClipboardWriter {
  String? lastText;

  @override
  Future<void> writeText(String text) async {
    lastText = text;
  }
}

final class _RecordingSpeech implements SpeechAdapter {
  String? lastText;

  @override
  Future<void> speak(String text) async {
    lastText = text;
  }

  @override
  Future<void> stop() async {}
}

final class _LongReadingProvider implements AnalysisProvider {
  @override
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  ) async {
    final text = List<String>.filled(80, request.input).join(' ');
    return AnalysisResult(
      providerLabel: 'Fake Provider（deterministic long development data）',
      reading: ReadingAnalysis(
        translation: 'FAKE TRANSLATION: $text',
        sentenceAnalysis: 'FAKE SENTENCE ANALYSIS: $text',
        grammar: 'FAKE GRAMMAR: $text',
        vocabulary: 'FAKE VOCABULARY: $text',
        nuance: 'FAKE NUANCE: $text',
      ),
      expression: ExpressionAnalysis(
        natural: 'FAKE NATURAL: $text',
        polite: 'FAKE POLITE: $text',
        formal: 'FAKE FORMAL: $text',
        context: 'FAKE CONTEXT: $text',
        tone: 'FAKE TONE: $text',
      ),
    );
  }
}
