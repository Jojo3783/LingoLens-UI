import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/analysis_action_contracts.dart';
import 'package:lingolens/application/analysis_action_controller.dart';
import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/application/analysis_state.dart';
import 'package:lingolens/application/persistence_controller.dart';
import 'package:lingolens/domain/analysis_models.dart';
import 'package:lingolens/domain/persistence_contracts.dart';
import 'package:lingolens/infrastructure/fake_analysis_provider.dart';
import 'package:lingolens/infrastructure/fake_speech_adapter.dart';
import 'package:lingolens/infrastructure/in_memory_persistence.dart';

void main() {
  test('mode-specific Copy and Fake Listen use the primary output', () async {
    final clipboard = _TestClipboard();
    final speech = FakeSpeechAdapter();
    final controller = _controller(clipboard: clipboard, speech: speech);
    addTearDown(controller.dispose);

    controller.submit('reading', mode: AnalysisMode.reading);
    final reading = await _success(controller);
    await controller.actions!.copy();
    await controller.actions!.listen();
    expect(clipboard.lastText, reading.result.reading.translation);
    expect(speech.spokenTexts, [reading.result.reading.translation]);

    controller.submit('expression', mode: AnalysisMode.expression);
    final expression = await _success(controller);
    await controller.actions!.copy();
    await controller.actions!.listen();
    expect(clipboard.lastText, expression.result.expression.natural);
    expect(speech.spokenTexts.last, expression.result.expression.natural);
  });

  test('Save is explicit, idempotent, and Favorite requires Save', () async {
    final history = InMemoryHistoryRepository();
    final favorites = InMemoryFavoriteRepository();
    final controller = _controller(history: history, favorites: favorites);
    addTearDown(controller.dispose);

    controller.submit('save me', mode: AnalysisMode.expression);
    final success = await _success(controller);
    await controller.actions!.setFavorite(true);
    expect(await favorites.listAll(), isEmpty);

    await controller.actions!.save();
    await controller.actions!.save();
    final records = await history.listAll();
    expect(records, hasLength(1));
    expect(records.single.input, success.input);
    expect(records.single.mode, AnalysisMode.expression);

    await controller.actions!.setFavorite(true);
    expect(
      (await favorites.listAll()).single.historyRecordId,
      records.single.id,
    );
  });

  test(
    'disabled History writes produce a truthful failure and no record',
    () async {
      final settings = InMemorySettingsRepository();
      final history = InMemoryHistoryRepository();
      final persistence = _persistence(history: history, settings: settings);
      await persistence.setHistoryWritesEnabled(false);
      final actions = AnalysisActionController(
        ports: _ports(persistence: persistence),
      );
      addTearDown(actions.dispose);
      final success = _successState(AnalysisMode.reading);
      actions.setSuccess(success);

      await actions.save();
      expect(actions.state.phase, AnalysisActionPhase.failure);
      expect(actions.state.message, contains('未儲存'));
      expect(await history.listAll(), isEmpty);
    },
  );

  test('Feedback stores one immutable, consent-scoped snapshot', () async {
    final feedback = InMemoryFeedbackRepository();
    final persistence = _persistence(feedback: feedback);
    final actions = AnalysisActionController(
      ports: _ports(persistence: persistence),
    );
    addTearDown(actions.dispose);
    final success = _successState(AnalysisMode.expression);
    actions.setSuccess(success);

    await actions.submitFeedback(
      requestId: success.requestId,
      reason: FeedbackReason.incorrect,
      comment: 'comment',
    );
    await actions.submitFeedback(
      requestId: success.requestId,
      reason: FeedbackReason.other,
    );
    final withoutConsent = (await feedback.listAll()).single;
    expect(withoutConsent.attachedInput, isNull);
    expect(withoutConsent.attachedOutput, isNull);

    final secondFeedback = InMemoryFeedbackRepository();
    final secondPersistence = _persistence(feedback: secondFeedback);
    final secondActions = AnalysisActionController(
      ports: _ports(persistence: secondPersistence),
    );
    addTearDown(secondActions.dispose);
    secondActions.setSuccess(success);
    await secondActions.submitFeedback(
      requestId: success.requestId,
      reason: FeedbackReason.unhelpful,
      consentToAttachContent: true,
    );
    final withConsent = (await secondFeedback.listAll()).single;
    expect(withConsent.attachedInput, success.input);
    expect(withConsent.attachedOutput, success.result.expression.natural);
  });

  test(
    'stale action completion cannot replace a newer request state',
    () async {
      final clipboard = _DelayedClipboard();
      final controller = _controller(clipboard: clipboard);
      addTearDown(controller.dispose);

      controller.submit('old');
      await _success(controller);
      final oldCopy = controller.actions!.copy();

      controller.submit('new');
      await _success(controller);
      clipboard.complete();
      await oldCopy;

      expect(
        controller.actions!.state.requestId,
        (controller.state as AnalysisSuccess).requestId,
      );
      expect(controller.actions!.state.message, isNull);
    },
  );

  test('same-request older Copy cannot replace newer Listen success', () async {
    final clipboard = _DelayedClipboard();
    final speech = _ControlledSpeech();
    final controller = _controller(clipboard: clipboard, speech: speech);
    addTearDown(controller.dispose);

    controller.submit('same request');
    await _success(controller);
    final oldCopy = controller.actions!.copy();
    final newerListen = controller.actions!.listen();
    speech.complete();
    await newerListen;
    clipboard.complete();
    await oldCopy;

    expect(controller.actions!.state.kind, AnalysisActionKind.listen);
    expect(controller.actions!.state.phase, AnalysisActionPhase.success);
    expect(controller.actions!.state.message, 'Fake Listen 已記錄結果文字。');
  });

  test(
    'same-request older Copy failure cannot replace newer success',
    () async {
      final clipboard = _DelayedClipboard();
      final controller = _controller(clipboard: clipboard);
      addTearDown(controller.dispose);

      controller.submit('same request failure');
      await _success(controller);
      final oldCopy = controller.actions!.copy();
      await controller.actions!.listen();
      clipboard.fail();
      await oldCopy;

      expect(controller.actions!.state.kind, AnalysisActionKind.listen);
      expect(controller.actions!.state.phase, AnalysisActionPhase.success);
      expect(controller.actions!.state.message, 'Fake Listen 已記錄結果文字。');
    },
  );

  test(
    'late Feedback success cannot clear newer RequestId ownership',
    () async {
      final feedback = _ControlledFeedbackRepository();
      final actions = AnalysisActionController(
        ports: _ports(persistence: _persistence(feedback: feedback)),
      );
      addTearDown(actions.dispose);
      final requestA = _successState(AnalysisMode.reading);
      final requestB = _successState(AnalysisMode.expression);

      actions.setSuccess(requestA);
      final feedbackA = actions.submitFeedback(
        requestId: requestA.requestId,
        reason: FeedbackReason.incorrect,
      );
      actions.setSuccess(requestB);
      final feedbackB = actions.submitFeedback(
        requestId: requestB.requestId,
        reason: FeedbackReason.unhelpful,
      );
      expect(feedback.saveCalls, 2);

      feedback.completeAt(0);
      await feedbackA;
      final duplicateB = actions.submitFeedback(
        requestId: requestB.requestId,
        reason: FeedbackReason.other,
      );
      await duplicateB;
      expect(feedback.saveCalls, 2);
      expect(actions.state.requestId, requestB.requestId);
      expect(actions.state.phase, AnalysisActionPhase.running);
      expect(actions.state.feedbackSubmitted, isFalse);

      feedback.completeAt(1);
      await feedbackB;
      final records = await feedback.listAll();
      expect(records.map((record) => record.id), [
        'feedback-${requestA.requestId.value}',
        'feedback-${requestB.requestId.value}',
      ]);
      expect(records, hasLength(2));
      expect(actions.state.requestId, requestB.requestId);
      expect(actions.state.feedbackSubmitted, isTrue);
      expect(actions.state.phase, AnalysisActionPhase.success);
    },
  );

  test(
    'late Feedback failure cannot clear newer RequestId ownership',
    () async {
      final feedback = _ControlledFeedbackRepository();
      final actions = AnalysisActionController(
        ports: _ports(persistence: _persistence(feedback: feedback)),
      );
      addTearDown(actions.dispose);
      final requestA = _successState(AnalysisMode.reading);
      final requestB = _successState(AnalysisMode.expression);

      actions.setSuccess(requestA);
      final feedbackA = actions.submitFeedback(
        requestId: requestA.requestId,
        reason: FeedbackReason.incorrect,
      );
      actions.setSuccess(requestB);
      final feedbackB = actions.submitFeedback(
        requestId: requestB.requestId,
        reason: FeedbackReason.unhelpful,
      );
      expect(feedback.saveCalls, 2);

      feedback.failAt(0);
      await feedbackA;
      await actions.submitFeedback(
        requestId: requestB.requestId,
        reason: FeedbackReason.other,
      );
      expect(feedback.saveCalls, 2);
      expect(actions.state.requestId, requestB.requestId);
      expect(actions.state.phase, AnalysisActionPhase.running);
      expect(actions.state.feedbackSubmitted, isFalse);

      feedback.completeAt(1);
      await feedbackB;
      final records = await feedback.listAll();
      expect(records, hasLength(1));
      expect(records.single.id, 'feedback-${requestB.requestId.value}');
      expect(actions.state.requestId, requestB.requestId);
      expect(actions.state.feedbackSubmitted, isTrue);
      expect(actions.state.phase, AnalysisActionPhase.success);
    },
  );
}

AnalysisController _controller({
  ClipboardWriter? clipboard,
  SpeechAdapter? speech,
  InMemoryHistoryRepository? history,
  InMemoryFavoriteRepository? favorites,
}) {
  final persistence = _persistence(history: history, favorites: favorites);
  return AnalysisController(
    provider: FakeAnalysisProvider(delay: Duration.zero),
    actionPorts: _ports(
      persistence: persistence,
      clipboard: clipboard,
      speech: speech,
    ),
  );
}

AnalysisActionPorts _ports({
  required PersistenceController persistence,
  ClipboardWriter? clipboard,
  SpeechAdapter? speech,
}) => AnalysisActionPorts(
  persistence: persistence,
  clipboard: clipboard ?? _TestClipboard(),
  speech: speech ?? FakeSpeechAdapter(),
  clock: const _FixedClock(),
  historyIds: const DeterministicHistoryIdGenerator(),
);

PersistenceController _persistence({
  InMemoryHistoryRepository? history,
  InMemorySettingsRepository? settings,
  InMemoryFavoriteRepository? favorites,
  FeedbackRepository? feedback,
}) => PersistenceController(
  history: history ?? InMemoryHistoryRepository(),
  cache: InMemoryAnalysisCacheRepository(),
  settings: settings ?? InMemorySettingsRepository(),
  favorites: favorites ?? InMemoryFavoriteRepository(),
  feedback: feedback ?? InMemoryFeedbackRepository(),
);

Future<AnalysisSuccess> _success(AnalysisController controller) => controller
    .states
    .where((state) => state is AnalysisSuccess)
    .cast<AnalysisSuccess>()
    .first;

AnalysisSuccess _successState(AnalysisMode mode) => AnalysisSuccess(
  requestId: RequestId.create(),
  input: 'immutable input',
  mode: mode,
  result: const AnalysisResult(
    providerLabel: 'test',
    reading: ReadingAnalysis(
      translation: 'reading',
      sentenceAnalysis: 'sentence analysis',
      grammar: 'grammar',
      vocabulary: 'vocabulary',
      nuance: 'nuance',
    ),
    expression: ExpressionAnalysis(
      natural: 'natural',
      polite: 'polite',
      formal: 'formal',
      context: 'context',
      tone: 'tone',
    ),
  ),
);

final class _TestClipboard implements ClipboardWriter {
  String? lastText;

  @override
  Future<void> writeText(String text) async {
    lastText = text;
  }
}

final class _DelayedClipboard implements ClipboardWriter {
  late final Completer<void> _completion = Completer<void>();

  @override
  Future<void> writeText(String text) => _completion.future;

  void complete() => _completion.complete();

  void fail() =>
      _completion.completeError(StateError('synthetic copy failure'));
}

final class _ControlledSpeech implements SpeechAdapter {
  Completer<void>? _completion;

  @override
  Future<void> speak(String text) {
    final completion = Completer<void>();
    _completion = completion;
    return completion.future;
  }

  @override
  Future<void> stop() async {}

  void complete() => _completion!.complete();
}

final class _ControlledFeedbackRepository implements FeedbackRepository {
  final List<FeedbackRecord> _records = <FeedbackRecord>[];
  final List<({FeedbackRecord record, Completer<void> completion})> _pending =
      <({FeedbackRecord record, Completer<void> completion})>[];

  int saveCalls = 0;

  @override
  Future<void> save(FeedbackRecord record) {
    saveCalls++;
    final completion = Completer<void>();
    _pending.add((record: record, completion: completion));
    return completion.future.then((_) => _records.add(record));
  }

  @override
  Future<List<FeedbackRecord>> listAll() async =>
      List<FeedbackRecord>.unmodifiable(_records);

  void completeAt(int index) => _pending[index].completion.complete();

  void failAt(int index) => _pending[index].completion.completeError(
    StateError('synthetic feedback failure'),
  );
}

final class _FixedClock implements Clock {
  const _FixedClock();

  @override
  DateTime now() => DateTime.utc(2026, 7, 28);
}
