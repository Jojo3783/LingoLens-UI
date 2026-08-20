import 'package:flutter/material.dart';

import '../application/analysis_action_controller.dart';
import '../application/analysis_state.dart';
import '../domain/analysis_models.dart';
import 'analysis_quick_actions.dart';

/// 借鑒 Design Course 的 CourseInfoScreen/細節卡片樣式封裝的獨立結果 UI 切片元件
final class AnalysisResultCard extends StatelessWidget {
  const AnalysisResultCard({
    required this.success,
    this.actions,
    super.key,
  });

  final AnalysisSuccess success;
  final AnalysisActionController? actions;

  @override
  Widget build(BuildContext context) {
    final isReading = success.mode == AnalysisMode.reading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      container: true,
      liveRegion: true,
      label: '${isReading ? 'Reading' : 'Expression'} result',
      child: Card(
        key: ValueKey(isReading ? 'reading-result' : 'expression-result'),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Mode 標籤與 Provider 說明
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isReading ? 'Reading' : 'Expression',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Provider: ${success.result.providerLabel}',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          success.result.providerLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ==================== LAYER 1: 即時直接答案 ====================
                if (isReading) ...[
                  _ResultSection(
                    key: const ValueKey('reading-translation'),
                    label: 'Translation',
                    text: success.result.reading.translation,
                    isPrimary: true,
                  ),
                  if (actions != null) ...[
                    const SizedBox(height: 12),
                    AnalysisQuickActions(
                      controller: actions!,
                      mode: success.mode,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // ==================== LAYER 2: 核心學習重點 ====================
                  _ResultSection(
                    key: const ValueKey('reading-sentence-analysis'),
                    label: 'Sentence analysis',
                    text: success.result.reading.sentenceAnalysis,
                  ),
                  const SizedBox(height: 12),
                  _ResultSection(
                    key: const ValueKey('reading-grammar'),
                    label: 'Grammar',
                    text: success.result.reading.grammar,
                  ),
                  const SizedBox(height: 12),
                  _ResultSection(
                    key: const ValueKey('reading-vocabulary'),
                    label: 'Vocabulary',
                    text: success.result.reading.vocabulary,
                  ),
                  const SizedBox(height: 12),
                  // ==================== LAYER 3: 深入細微解析 ====================
                  _ResultSection(
                    key: const ValueKey('reading-nuance'),
                    label: 'Nuance',
                    text: success.result.reading.nuance,
                  ),
                ] else ...[
                  _ResultSection(
                    key: const ValueKey('expression-natural'),
                    label: 'Natural',
                    text: success.result.expression.natural,
                    isPrimary: true,
                  ),
                  if (actions != null) ...[
                    const SizedBox(height: 12),
                    AnalysisQuickActions(
                      controller: actions!,
                      mode: success.mode,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _ResultSection(
                    key: const ValueKey('expression-polite'),
                    label: 'Polite',
                    text: success.result.expression.polite,
                  ),
                  const SizedBox(height: 12),
                  _ResultSection(
                    key: const ValueKey('expression-formal'),
                    label: 'Formal',
                    text: success.result.expression.formal,
                  ),
                  const SizedBox(height: 12),
                  _ResultSection(
                    key: const ValueKey('expression-context'),
                    label: 'Context',
                    text: success.result.expression.context,
                  ),
                  const SizedBox(height: 12),
                  _ResultSection(
                    key: const ValueKey('expression-tone'),
                    label: 'Tone',
                    text: success.result.expression.tone,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.label,
    required this.text,
    this.isPrimary = false,
    super.key,
  });

  final String label;
  final String text;
  final bool isPrimary;

  IconData _iconForLabel(String label) {
    switch (label) {
      case 'Translation':
        return Icons.translate_rounded;
      case 'Natural':
        return Icons.chat_bubble_outline_rounded;
      case 'Sentence analysis':
        return Icons.account_tree_outlined;
      case 'Grammar':
        return Icons.rule_rounded;
      case 'Vocabulary':
        return Icons.menu_book_outlined;
      case 'Nuance':
        return Icons.psychology_alt_outlined;
      case 'Polite':
        return Icons.sentiment_satisfied_alt_rounded;
      case 'Formal':
        return Icons.business_center_outlined;
      case 'Context':
        return Icons.place_outlined;
      case 'Tone':
        return Icons.record_voice_over_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final containerColor = isPrimary
        ? colorScheme.primaryContainer.withValues(alpha: 0.75)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);

    final labelColor = isPrimary
        ? colorScheme.onPrimaryContainer
        : colorScheme.primary;

    final sectionIcon = _iconForLabel(label);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sectionIcon,
                  size: isPrimary ? 18 : 15,
                  color: labelColor,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: isPrimary
                      ? theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: labelColor,
                        )
                      : theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: labelColor,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            excludeSemantics: true,
            label: '$label: $text',
            child: SelectableText(
              text,
              style: isPrimary
                  ? theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    )
                  : theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

