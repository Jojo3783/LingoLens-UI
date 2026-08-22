import 'package:flutter/material.dart';

import '../application/analysis_state.dart';
import '../application/persistence_controller.dart';
import '../application/review_controller.dart';
import '../domain/analysis_models.dart';
import 'analysis_result_card.dart';
import 'lingolens_surface.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    required this.persistence,
    this.controller,
    super.key,
  });

  final PersistenceController persistence;
  final ReviewController? controller;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late final ReviewController _controller;
  late final bool _isInternalController;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isInternalController = false;
    } else {
      _controller = ReviewController(persistence: widget.persistence);
      _isInternalController = true;
      _controller.loadSession();
    }
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onSpeakText(BuildContext context, String text) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const ValueKey('review-tts-snackbar'),
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '語音播放中：「$text」',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return switch (state) {
          ReviewSessionLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          ReviewSessionEmpty() => _buildEmptyState(context),
          ReviewCardPrompt() => _buildPromptState(context, state),
          ReviewCardRevealed() => _buildRevealedState(context, state),
          ReviewSessionCompleted() => _buildCompletedState(context, state),
        };
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: LingoLensSurface(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_outlined,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '最近 10 天沒有可複習的收藏',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '在分析查詢時點擊 ⭐️ 將重要內容加入收藏，系統會自動為您安排 3～5 筆回想小練習，輕鬆加深語感記憶。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  key: const ValueKey('review-refresh-btn'),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('重新整理'),
                  onPressed: () => _controller.loadSession(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromptState(BuildContext context, ReviewCardPrompt state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isReading = state.currentRecord.mode == AnalysisMode.reading;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSessionHeader(
                context,
                currentIndex: state.currentIndex,
                totalCount: state.totalCount,
              ),
              const SizedBox(height: 16),
              LingoLensSurface(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isReading
                                ? colorScheme.primaryContainer
                                : colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isReading ? '閱讀回想 (Reading)' : '表達回想 (Expression)',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isReading
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('review-tts-btn'),
                          icon: const Icon(Icons.volume_up_rounded),
                          tooltip: '播放發音 (TTS)',
                          onPressed: () => _onSpeakText(
                            context,
                            state.currentRecord.input,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.currentRecord.input,
                      key: const ValueKey('review-card-input-text'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 22,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isReading
                                  ? '在心中回想這句話的意思、重點文法或語氣...'
                                  : '在心中嘗試用英文說說看這句話...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        key: const ValueKey('review-reveal-btn'),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text(
                          '查看解析 (Reveal)',
                          style: TextStyle(fontSize: 16),
                        ),
                        onPressed: () => _controller.reveal(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevealedState(BuildContext context, ReviewCardRevealed state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: GestureDetector(
            key: const ValueKey('review-revealed-gesture-area'),
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _dragOffset = 0.0,
            onHorizontalDragUpdate: (details) {
              _dragOffset += details.primaryDelta ?? 0.0;
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0.0;
              if (velocity < -100 || _dragOffset < -50) {
                // 向左滑：還不熟
                _controller.submitFeedback(ReviewFamiliarity.needsPractice);
              } else if (velocity > 100 || _dragOffset > 50) {
                // 向右滑：已熟悉
                _controller.submitFeedback(ReviewFamiliarity.mastered);
              }
              _dragOffset = 0.0;
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSessionHeader(
                  context,
                  currentIndex: state.currentIndex,
                  totalCount: state.totalCount,
                ),
                const SizedBox(height: 16),
                LingoLensSurface(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '原始文字',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.currentRecord.input,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('review-revealed-tts-btn'),
                        icon: const Icon(Icons.volume_up_rounded),
                        tooltip: '播放發音 (TTS)',
                        onPressed: () => _onSpeakText(
                          context,
                          state.currentRecord.input,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AnalysisResultCard(
                  key: const ValueKey('review-analysis-result-card'),
                  isCollapsible: true,
                  success: AnalysisSuccess(
                    requestId: RequestId.create(),
                    input: state.currentRecord.input,
                    mode: state.currentRecord.mode,
                    result: state.currentRecord.result,
                  ),
                ),
                const SizedBox(height: 20),
                LingoLensSurface(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '您的熟悉程度：',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '👈 左滑：還不熟 | 右滑：已熟悉 👉',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // 1. 還不熟 (暖橘/淺紅暗示色)
                          Expanded(
                            child: FilledButton.tonalIcon(
                              key: const ValueKey(
                                'review-feedback-needs-practice-btn',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFFF3E0),
                                foregroundColor: const Color(0xFFE65100),
                                side: const BorderSide(
                                  color: Color(0xFFFFB74D),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.replay_rounded,
                                size: 18,
                                color: Color(0xFFE65100),
                              ),
                              label: const Text(
                                '還不熟',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _controller.submitFeedback(
                                ReviewFamiliarity.needsPractice,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 2. 差不多了 (中性穩健調)
                          Expanded(
                            child: FilledButton.tonalIcon(
                              key: const ValueKey(
                                'review-feedback-getting-there-btn',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.secondaryContainer,
                                foregroundColor:
                                    colorScheme.onSecondaryContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.thumb_up_alt_outlined,
                                size: 18,
                              ),
                              label: const Text('差不多了'),
                              onPressed: () => _controller.submitFeedback(
                                ReviewFamiliarity.gettingThere,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 3. 已熟悉 (正向翡翠綠暗示色)
                          Expanded(
                            child: FilledButton.tonalIcon(
                              key: const ValueKey(
                                'review-feedback-mastered-btn',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFE8F5E9),
                                foregroundColor: const Color(0xFF2E7D32),
                                side: const BorderSide(
                                  color: Color(0xFF81C784),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                                color: Color(0xFF2E7D32),
                              ),
                              label: const Text(
                                '已熟悉',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _controller.submitFeedback(
                                ReviewFamiliarity.mastered,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedState(
    BuildContext context,
    ReviewSessionCompleted state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: LingoLensSurface(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.celebration_rounded,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '🎉 太棒了！已完成回想練習',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '本次已回想 ${state.reviewedCount} 筆收藏重點。\n低壓練習積少成多，隨時有空再來遇見您的學習內容！',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('review-restart-btn'),
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('再複習一組'),
                      onPressed: () => _controller.restart(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionHeader(
    BuildContext context, {
    required int currentIndex,
    required int totalCount,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = totalCount > 0 ? (currentIndex + 1) / totalCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '第 ${currentIndex + 1} / $totalCount 筆',
                    key: const ValueKey('review-progress-label'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              key: const ValueKey('review-skip-btn'),
              icon: const Icon(Icons.skip_next_outlined, size: 18),
              label: const Text('略過'),
              onPressed: () => _controller.skip(),
            ),
            const SizedBox(width: 4),
            IconButton(
              key: const ValueKey('review-finish-btn'),
              icon: const Icon(Icons.close_rounded, size: 20),
              tooltip: '結束本次複習',
              onPressed: () => _controller.finish(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            key: const ValueKey('review-progress-bar'),
            value: progress,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
