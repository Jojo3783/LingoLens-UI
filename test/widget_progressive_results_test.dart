import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/analysis_action_contracts.dart';
import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/application/analysis_execution_strategy.dart';
import 'package:lingolens/domain/analysis_models.dart';
import 'package:lingolens/infrastructure/fake_speech_adapter.dart';
import 'package:lingolens/infrastructure/in_memory_persistence.dart';
import 'package:lingolens/application/persistence_controller.dart';
import 'package:lingolens/presentation/analysis_page.dart';

void main() {
  testWidgets('Reading Preview uses Translation identity and no Full actions', (
    tester,
  ) async {
    final history = InMemoryHistoryRepository();
    final provider = _ProgressiveWidgetProvider();
    final controller = _controller(provider, history);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    controller.submit('reading preview', mode: AnalysisMode.reading);
    provider.completePreview();
    await tester.pump();

    expect(find.bySemanticsLabel('Preview／部分結果'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reading-preview-translation')),
      findsOneWidget,
    );
    expect(
      find.text('FAKE TRANSLATION PREVIEW: reading preview'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('reading-session-actions')), findsNothing);
    expect(find.byKey(const ValueKey('feedback-panel')), findsNothing);
    expect(await history.listAll(), isEmpty);
  });

  testWidgets('Expression Preview uses Natural identity and no Full actions', (
    tester,
  ) async {
    final history = InMemoryHistoryRepository();
    final provider = _ProgressiveWidgetProvider();
    final controller = _controller(provider, history);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_pageFor(controller));

    controller.submit('expression preview', mode: AnalysisMode.expression);
    provider.completePreview();
    await tester.pump();

    expect(find.bySemanticsLabel('Preview／部分結果'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('expression-preview-natural')),
      findsOneWidget,
    );
    expect(
      find.text('FAKE NATURAL PREVIEW: expression preview'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('expression-session-actions')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('feedback-panel')), findsNothing);
    expect(await history.listAll(), isEmpty);
  });
}

Widget _pageFor(AnalysisController controller) => MaterialApp(
  home: AnalysisPage(controller: controller, onFailureScenarioChanged: (_) {}),
);

AnalysisController _controller(
  _ProgressiveWidgetProvider provider,
  InMemoryHistoryRepository history,
) => AnalysisController(
  provider: provider,
  strategy: const TwoStageStrategy(),
  actionPorts: AnalysisActionPorts(
    persistence: PersistenceController(
      history: history,
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

final class _ProgressiveWidgetProvider
    implements AnalysisProvider, ProgressiveAnalysisProviderCapability {
  final _preview = Completer<AnalysisPreview>();
  final _full = Completer<AnalysisResult>();
  late AnalysisRequest request;

  @override
  Future<AnalysisPreview> analyzePreview(
    AnalysisRequest request,
    RequestContext context,
  ) {
    this.request = request;
    return _preview.future;
  }

  @override
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  ) => _full.future;

  void completePreview() {
    final primary = request.mode == AnalysisMode.reading
        ? 'FAKE TRANSLATION PREVIEW: ${request.input}'
        : 'FAKE NATURAL PREVIEW: ${request.input}';
    _preview.complete(
      AnalysisPreview(
        mode: request.mode,
        providerLabel: 'Widget Preview Provider',
        primaryText: primary,
      ),
    );
  }
}

final class _NoopClipboard implements ClipboardWriter {
  const _NoopClipboard();

  @override
  Future<void> writeText(String text) async {}
}
