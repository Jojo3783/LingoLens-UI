import '../domain/analysis_models.dart';
import 'analysis_state.dart';

typedef AnalysisPreviewListener = void Function(AnalysisPreview preview);
typedef AnalysisPreviewFailureListener = void Function(AnalysisError error);

abstract interface class AnalysisExecutionStrategy {
  AnalysisLoadingStage initialStage(AnalysisProvider provider);

  Future<AnalysisResult> execute(
    AnalysisProvider provider,
    AnalysisRequest request,
    RequestContext context, {
    required AnalysisPreviewListener onPreview,
    required AnalysisPreviewFailureListener onPreviewFailure,
  });
}

final class FullOnlyStrategy implements AnalysisExecutionStrategy {
  const FullOnlyStrategy();

  @override
  AnalysisLoadingStage initialStage(AnalysisProvider provider) =>
      AnalysisLoadingStage.full;

  @override
  Future<AnalysisResult> execute(
    AnalysisProvider provider,
    AnalysisRequest request,
    RequestContext context, {
    required AnalysisPreviewListener onPreview,
    required AnalysisPreviewFailureListener onPreviewFailure,
  }) => provider.analyzeFull(request, context);
}

final class TwoStageStrategy implements AnalysisExecutionStrategy {
  const TwoStageStrategy();

  @override
  AnalysisLoadingStage initialStage(AnalysisProvider provider) =>
      provider is ProgressiveAnalysisProviderCapability
      ? AnalysisLoadingStage.preview
      : AnalysisLoadingStage.full;

  @override
  Future<AnalysisResult> execute(
    AnalysisProvider provider,
    AnalysisRequest request,
    RequestContext context, {
    required AnalysisPreviewListener onPreview,
    required AnalysisPreviewFailureListener onPreviewFailure,
  }) async {
    if (provider is! ProgressiveAnalysisProviderCapability) {
      return provider.analyzeFull(request, context);
    }
    final capability = provider as ProgressiveAnalysisProviderCapability;

    try {
      context.cancellation.throwIfCancelled();
      final preview = await capability.analyzePreview(request, context);
      _validatePreview(preview, request);
      context.cancellation.throwIfCancelled();
      onPreview(preview);
    } on AnalysisApplicationException catch (exception) {
      if (exception.error.code == AnalysisErrorCode.requestCancelled) {
        rethrow;
      }
      onPreviewFailure(exception.error);
    } catch (_) {
      onPreviewFailure(const AnalysisError.unknownError());
    }

    context.cancellation.throwIfCancelled();
    return provider.analyzeFull(request, context);
  }

  void _validatePreview(AnalysisPreview preview, AnalysisRequest request) {
    if (preview.mode != request.mode ||
        preview.providerLabel.trim().isEmpty ||
        preview.primaryText.trim().isEmpty) {
      throw const AnalysisProviderException.invalidStructuredOutput();
    }
  }
}
