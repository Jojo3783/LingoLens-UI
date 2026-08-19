import '../domain/analysis_models.dart';

enum AnalysisPhase { idle, loading, success, failure, cancelled }

enum AnalysisLoadingStage { preview, full }

sealed class AnalysisSessionState {
  const AnalysisSessionState(this.phase);

  final AnalysisPhase phase;
}

final class AnalysisIdle extends AnalysisSessionState {
  const AnalysisIdle() : super(AnalysisPhase.idle);
}

final class AnalysisLoading extends AnalysisSessionState {
  const AnalysisLoading({
    required this.requestId,
    required this.input,
    required this.mode,
    this.stage = AnalysisLoadingStage.full,
    this.previewError,
  }) : super(AnalysisPhase.loading);

  final RequestId requestId;
  final String input;
  final AnalysisMode mode;
  final AnalysisLoadingStage stage;
  final AnalysisError? previewError;
}

final class AnalysisPartial extends AnalysisSessionState {
  const AnalysisPartial({
    required this.requestId,
    required this.input,
    required this.mode,
    required this.preview,
    this.previewError,
  }) : super(AnalysisPhase.loading);

  final RequestId requestId;
  final String input;
  final AnalysisMode mode;
  final AnalysisPreview preview;
  final AnalysisError? previewError;
}

final class AnalysisSuccess extends AnalysisSessionState {
  const AnalysisSuccess({
    required this.requestId,
    required this.input,
    required this.mode,
    required this.result,
  }) : super(AnalysisPhase.success);

  final RequestId requestId;
  final String input;
  final AnalysisMode mode;
  final AnalysisResult result;
}

final class AnalysisFailure extends AnalysisSessionState {
  const AnalysisFailure({
    required this.requestId,
    required this.input,
    required this.mode,
    required this.error,
    this.previewError,
  }) : super(AnalysisPhase.failure);

  final RequestId requestId;
  final String input;
  final AnalysisMode mode;
  final AnalysisError error;
  final AnalysisError? previewError;
}

final class AnalysisPartialFailure extends AnalysisSessionState {
  const AnalysisPartialFailure({
    required this.requestId,
    required this.input,
    required this.mode,
    required this.preview,
    required this.error,
    this.previewError,
  }) : super(AnalysisPhase.failure);

  final RequestId requestId;
  final String input;
  final AnalysisMode mode;
  final AnalysisPreview preview;
  final AnalysisError error;
  final AnalysisError? previewError;
}

final class AnalysisCancelled extends AnalysisSessionState {
  const AnalysisCancelled({
    required this.requestId,
    required this.input,
    required this.mode,
    this.preview,
    this.previewError,
  }) : super(AnalysisPhase.cancelled);

  final RequestId requestId;
  final String input;
  final AnalysisMode mode;
  final AnalysisPreview? preview;
  final AnalysisError? previewError;
}
