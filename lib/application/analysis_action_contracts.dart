import '../domain/analysis_models.dart';
import 'persistence_controller.dart';

abstract interface class ClipboardWriter {
  Future<void> writeText(String text);
}

abstract interface class SpeechAdapter {
  Future<void> speak(String text);

  Future<void> stop();
}

abstract interface class Clock {
  DateTime now();
}

abstract interface class HistoryIdGenerator {
  String idFor(RequestId requestId);
}

final class AnalysisActionPorts {
  const AnalysisActionPorts({
    required this.persistence,
    required this.clipboard,
    required this.speech,
    required this.clock,
    required this.historyIds,
  });

  final PersistenceController persistence;
  final ClipboardWriter clipboard;
  final SpeechAdapter speech;
  final Clock clock;
  final HistoryIdGenerator historyIds;
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

final class DeterministicHistoryIdGenerator implements HistoryIdGenerator {
  const DeterministicHistoryIdGenerator();

  @override
  String idFor(RequestId requestId) => 'history-${requestId.value}';
}

enum AnalysisActionKind { copy, listen, save, favorite, feedback }

enum AnalysisActionPhase { idle, running, success, failure }

final class AnalysisActionState {
  const AnalysisActionState({
    this.phase = AnalysisActionPhase.idle,
    this.requestId,
    this.kind,
    this.message,
    this.isSaved = false,
    this.isFavorite = false,
    this.feedbackSubmitted = false,
  });

  final AnalysisActionPhase phase;
  final RequestId? requestId;
  final AnalysisActionKind? kind;
  final String? message;
  final bool isSaved;
  final bool isFavorite;
  final bool feedbackSubmitted;
}
