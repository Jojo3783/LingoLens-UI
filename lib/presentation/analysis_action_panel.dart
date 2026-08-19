import 'package:flutter/material.dart';

import '../application/analysis_action_controller.dart';
import '../application/analysis_action_contracts.dart';
import '../application/analysis_state.dart';
import '../domain/analysis_models.dart';
import '../domain/persistence_contracts.dart';

final class AnalysisActionPanel extends StatefulWidget {
  const AnalysisActionPanel({
    required this.controller,
    required this.success,
    super.key,
  });

  final AnalysisActionController controller;
  final AnalysisSuccess success;

  @override
  State<AnalysisActionPanel> createState() => _AnalysisActionPanelState();
}

final class _AnalysisActionPanelState extends State<AnalysisActionPanel> {
  final _commentController = TextEditingController();
  FeedbackReason? _reason;
  bool _consent = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AnalysisActionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.success.requestId != widget.success.requestId) {
      _reason = null;
      _commentController.clear();
      _consent = false;
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<AnalysisActionState>(
      initialData: widget.controller.state,
      stream: widget.controller.states,
      builder: (context, snapshot) {
        final actionState = snapshot.data ?? widget.controller.state;
        final isReading = widget.success.mode == AnalysisMode.reading;
        final isRunning = actionState.phase == AnalysisActionPhase.running;
        final feedbackSubmitted = actionState.feedbackSubmitted;
        final isSaved = actionState.isSaved;
        final isFavorite = actionState.isFavorite;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 儲存狀態標籤列 ─────────────────────────────────────────
            if (isSaved || isFavorite)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (isSaved) ...[
                      Semantics(
                        label: '已儲存至歷史紀錄',
                        child: Chip(
                          key: const ValueKey('saved-badge'),
                          avatar: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('已儲存'),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (isFavorite)
                      Semantics(
                        label: '已加入最愛',
                        child: Chip(
                          key: const ValueKey('favorite-badge'),
                          avatar: Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber.shade600,
                          ),
                          label: const Text('已加入最愛'),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                  ],
                ),
              ),
            // ── 操作按鈕列 ────────────────────────────────────────────
            Semantics(
              container: true,
              label: isReading
                  ? 'Reading session actions'
                  : 'Expression session actions',
              child: Wrap(
                key: ValueKey(
                  isReading
                      ? 'reading-session-actions'
                      : 'expression-session-actions',
                ),
                spacing: 8,
                runSpacing: 8,
                children: [
                  // 手動儲存按鈕（未儲存時顯示）
                  if (!isSaved)
                    FilledButton.icon(
                      key: const ValueKey('save-action'),
                      icon: isRunning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(isRunning ? '儲存中…' : '儲存紀錄'),
                      onPressed: isRunning
                          ? null
                          : () async {
                              try {
                                await widget.controller.save();
                              } catch (_) {
                                _showErrorSnackBar('儲存失敗，請稍後再試。');
                              }
                            },
                    ),
                  // 加入最愛按鈕
                  OutlinedButton.icon(
                    key: const ValueKey('favorite-toggle'),
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite
                          ? Colors.amber.shade600
                          : colorScheme.onSurfaceVariant,
                    ),
                    label: Text(isFavorite ? '已加入最愛' : '加入最愛'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isFavorite
                            ? Colors.amber.shade600
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    onPressed: isRunning
                        ? null
                        : () async {
                            try {
                              // 未儲存時，直接加入最愛會自動先儲存（一鍵儲存並收藏）
                              if (!isSaved) {
                                await widget.controller.save();
                              }
                              await widget.controller.setFavorite(!isFavorite);
                            } catch (_) {
                              _showErrorSnackBar(
                                isFavorite ? '取消最愛失敗，請稍後再試。' : '加入最愛失敗，請稍後再試。',
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
            if (actionState.message != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                container: true,
                child: Text(
                  actionState.message!,
                  key: const ValueKey('action-message'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              key: const ValueKey('feedback-panel'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Feedback',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<FeedbackReason>(
                      key: const ValueKey('feedback-reason'),
                      initialValue: _reason,
                      decoration: const InputDecoration(
                        labelText: '原因',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: FeedbackReason.incorrect,
                          child: Text('Incorrect'),
                        ),
                        DropdownMenuItem(
                          value: FeedbackReason.unhelpful,
                          child: Text('Unhelpful'),
                        ),
                        DropdownMenuItem(
                          value: FeedbackReason.other,
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: isRunning || feedbackSubmitted
                          ? null
                          : (value) => setState(() => _reason = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('feedback-comment'),
                      controller: _commentController,
                      enabled: !isRunning && !feedbackSubmitted,
                      decoration: const InputDecoration(
                        labelText: 'Comment（選填）',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    CheckboxListTile(
                      key: const ValueKey('feedback-consent'),
                      value: _consent,
                      onChanged: isRunning || feedbackSubmitted
                          ? null
                          : (value) =>
                              setState(() => _consent = value ?? false),
                      title: const Text('同意附加目前輸入與結果'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const ValueKey('feedback-submit'),
                      onPressed:
                          isRunning || feedbackSubmitted || _reason == null
                              ? null
                              : _submitFeedback,
                      child: Text(
                        feedbackSubmitted ? 'Feedback 已送出' : '送出 Feedback',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitFeedback() async {
    final reason = _reason;
    if (reason == null) {
      return;
    }
    await widget.controller.submitFeedback(
      requestId: widget.success.requestId,
      reason: reason,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      consentToAttachContent: _consent,
    );
  }
}
