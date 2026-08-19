import 'package:flutter/material.dart';

import '../application/analysis_controller.dart';
import '../application/analysis_state.dart';
import '../domain/analysis_models.dart';
import 'analysis_action_panel.dart';
import 'analysis_result_panel.dart';

final class AnalysisStatePanel extends StatelessWidget {
  const AnalysisStatePanel({
    required this.controller,
    required this.state,
    super.key,
  });

  final AnalysisController controller;
  final AnalysisSessionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state is AnalysisLoading) {
      final loading = state as AnalysisLoading;
      final message = loading.stage == AnalysisLoadingStage.preview
          ? '正在取得 Preview…'
          : loading.previewError != null
              ? 'Preview 無法取得，正在等待完整結果…'
              : '分析中…';
      return Semantics(
        liveRegion: true,
        label: loading.stage == AnalysisLoadingStage.preview
            ? '正在取得 Preview'
            : '正在取得完整結果',
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (state is AnalysisPartial) {
      final partial = state as AnalysisPartial;
      return _partialResult(
        context,
        partial.mode,
        partial.preview,
        previewError: partial.previewError,
      );
    }
    if (state is AnalysisSuccess) {
      final success = state as AnalysisSuccess;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalysisResultPanel(success: success, actions: controller.actions),
          if (controller.actions != null) ...[
            const SizedBox(height: 12),
            AnalysisActionPanel(
              key: ValueKey('analysis-actions-${success.requestId.value}'),
              controller: controller.actions!,
              success: success,
            ),
          ],
        ],
      );
    }
    if (state is AnalysisFailure) {
      final failure = state as AnalysisFailure;
      return Semantics(
        liveRegion: true,
        label: 'Typed analysis error',
        child: Card(
          color: colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage(failure.error, failure.previewError),
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (state is AnalysisPartialFailure) {
      final failure = state as AnalysisPartialFailure;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _partialResult(
            context,
            failure.mode,
            failure.preview,
            previewError: failure.previewError,
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            label: 'Typed analysis error after Preview',
            child: Card(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage(failure.error, failure.previewError),
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (state is AnalysisCancelled) {
      final cancelled = state as AnalysisCancelled;
      if (cancelled.preview != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _partialResult(
              context,
              cancelled.preview!.mode,
              cancelled.preview!,
              previewError: cancelled.previewError,
            ),
            const SizedBox(height: 12),
            _cancelledCard(context),
          ],
        );
      }
      return _cancelledCard(context);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '請輸入文字並送出分析。',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '選擇閱讀或表達模式後點擊「送出分析」以取得結構化解析結果。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partialResult(
    BuildContext context,
    AnalysisMode mode,
    AnalysisPreview preview, {
    AnalysisError? previewError,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryLabel = mode == AnalysisMode.reading
        ? 'Translation'
        : 'Natural';
    return Semantics(
      container: true,
      label: 'Preview／部分結果',
      child: Card(
        key: const ValueKey('analysis-preview'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preview／部分結果',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Provider: ${preview.providerLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                primaryLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                preview.primaryText,
                key: ValueKey(
                  mode == AnalysisMode.reading
                      ? 'reading-preview-translation'
                      : 'expression-preview-natural',
                ),
                style: theme.textTheme.bodyLarge,
              ),
              if (previewError != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Preview 狀態：${previewError.message}',
                  style: TextStyle(color: colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _cancelledCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: '分析已取消',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('分析已取消。'),
            ],
          ),
        ),
      ),
    );
  }

  String _errorMessage(AnalysisError error, AnalysisError? previewError) {
    final previewText = previewError == null
        ? ''
        : ' Preview：${previewError.code.name}。';
    return '${error.code.name}: ${error.message}$previewText';
  }
}
