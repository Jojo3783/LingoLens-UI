import 'package:flutter/material.dart';

import '../application/analysis_action_controller.dart';
import '../application/analysis_state.dart';
import '../domain/analysis_models.dart';
import 'analysis_quick_actions.dart';

/// 借鑒 Design Course 的 CourseInfoScreen/細節卡片樣式封裝的獨立結果 UI 切片元件
final class AnalysisResultCard extends StatefulWidget {
  const AnalysisResultCard({
    required this.success,
    this.actions,
    this.isCollapsible = false,
    super.key,
  });

  final AnalysisSuccess success;
  final AnalysisActionController? actions;
  final bool isCollapsible;

  @override
  State<AnalysisResultCard> createState() => _AnalysisResultCardState();
}

class _AnalysisResultCardState extends State<AnalysisResultCard> {
  bool _expandAll = false;
  int _toggleToken = 0;

  @override
  Widget build(BuildContext context) {
    final isReading = widget.success.mode == AnalysisMode.reading;
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
                // Header: Mode 標籤與 Provider 說明 (以及可選的 Accordion 全部展開/收起按鈕)
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
                      label: 'Provider: ${widget.success.result.providerLabel}',
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
                          widget.success.result.providerLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    if (widget.isCollapsible)
                      TextButton.icon(
                        key: const ValueKey('accordion-toggle-all-btn'),
                        icon: Icon(
                          _expandAll
                              ? Icons.unfold_less_rounded
                              : Icons.unfold_more_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _expandAll ? '全部收起' : '全部展開',
                          style: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () {
                          setState(() {
                            _expandAll = !_expandAll;
                            _toggleToken++;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ==================== LAYER 1: 即時直接答案 ====================
                if (isReading) ...[
                  _ResultSection(
                    key: const ValueKey('reading-translation'),
                    label: 'Translation',
                    text: widget.success.result.reading.translation,
                    isPrimary: true,
                    isCollapsible: widget.isCollapsible,
                    forceExpanded: widget.isCollapsible ? _expandAll : null,
                    toggleToken: _toggleToken,
                  ),
                  if (widget.actions != null) ...[
                    const SizedBox(height: 12),
                    AnalysisQuickActions(
                      controller: widget.actions!,
                      mode: widget.success.mode,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // ==================== LAYER 2: 核心學習重點 ====================
                  _ResultSection(
                    key: const ValueKey('reading-sentence-analysis'),
                    label: 'Sentence analysis',
                    text: widget.success.result.reading.sentenceAnalysis,
                    isCollapsible: widget.isCollapsible,
                    forceExpanded: widget.isCollapsible ? _expandAll : null,
                    toggleToken: _toggleToken,
                  ),
                  const SizedBox(height: 12),
                  _ResultSection(
                    key: const ValueKey('reading-grammar'),
                    label: 'Grammar',
                    text: widget.success.result.reading.grammar,
                    isCollapsible: widget.isCollapsible,
                    forceExpanded: widget.isCollapsible ? _expandAll : null,
                    toggleToken: _toggleToken,
                  ),
                  const SizedBox(height: 12),
                  _ResultSection(
                    key: const ValueKey('reading-vocabulary'),
                    label: 'Vocabulary',
                    text: widget.success.result.reading.vocabulary,
                    isCollapsible: widget.isCollapsible,
                    forceExpanded: widget.isCollapsible ? _expandAll : null,
                    toggleToken: _toggleToken,
                  ),
                  const SizedBox(height: 12),
                  // ==================== LAYER 3: 深入細微解析 ====================
                  _ResultSection(
                    key: const ValueKey('reading-nuance'),
                    label: 'Nuance',
                    text: widget.success.result.reading.nuance,
                    isCollapsible: widget.isCollapsible,
                    forceExpanded: widget.isCollapsible ? _expandAll : null,
                    toggleToken: _toggleToken,
                  ),
                ] else ...[
                  _ResultSection(
                    key: const ValueKey('expression-natural'),
                    label: 'Natural',
                    text: widget.success.result.expression.natural,
                    isPrimary: true,
                    isCollapsible: widget.isCollapsible,
                    forceExpanded: widget.isCollapsible ? _expandAll : null,
                    toggleToken: _toggleToken,
                  ),
                  if (widget.actions != null) ...[
                    const SizedBox(height: 12),
                    AnalysisQuickActions(
                      controller: widget.actions!,
                      mode: widget.success.mode,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _ResultSection(
                    key: const ValueKey('expression-polite'),
                    label: 'Polite',
                    text: widget.success.result.expression.polite,
                    isCollapsible: widget.isCollapsible,
                    forceExpanded: widget.isCollapsible ? _expandAll : null,
                    toggleToken: _toggleToken,
                  ),
                  const SizedBox(height: 12),
                  _ResultSection(
                    key: const ValueKey('expression-formal'),
                    label: 'Formal',
                    text: widget.success.result.expression.formal,
                    isCollapsible: widget.isCollapsible,
                    forceExpanded: widget.isCollapsible ? _expandAll : null,
                    toggleToken: _toggleToken,
                  ),
                  const SizedBox(height: 12),
                  _ResultSection(
                    key: const ValueKey('expression-context'),
                    label: 'Context',
                    text: widget.success.result.expression.context,
                    isCollapsible: widget.isCollapsible,
                    forceExpanded: widget.isCollapsible ? _expandAll : null,
                    toggleToken: _toggleToken,
                  ),
                  const SizedBox(height: 12),
                  _ResultSection(
                    key: const ValueKey('expression-tone'),
                    label: 'Tone',
                    text: widget.success.result.expression.tone,
                    isCollapsible: widget.isCollapsible,
                    forceExpanded: widget.isCollapsible ? _expandAll : null,
                    toggleToken: _toggleToken,
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

final class _ResultSection extends StatefulWidget {
  const _ResultSection({
    required this.label,
    required this.text,
    this.isPrimary = false,
    this.isCollapsible = false,
    this.forceExpanded,
    this.toggleToken = 0,
    super.key,
  });

  final String label;
  final String text;
  final bool isPrimary;
  final bool isCollapsible;
  final bool? forceExpanded;
  final int toggleToken;

  @override
  State<_ResultSection> createState() => _ResultSectionState();
}

class _ResultSectionState extends State<_ResultSection> {
  late bool _isExpanded;
  int _lastToken = 0;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isPrimary || !widget.isCollapsible;
    _lastToken = widget.toggleToken;
  }

  @override
  void didUpdateWidget(covariant _ResultSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceExpanded != null && widget.toggleToken != _lastToken) {
      _isExpanded = widget.forceExpanded!;
      _lastToken = widget.toggleToken;
    }
  }

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

    final containerColor = widget.isPrimary
        ? colorScheme.primaryContainer.withValues(alpha: 0.75)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);

    final labelColor = widget.isPrimary
        ? colorScheme.onPrimaryContainer
        : colorScheme.primary;

    final sectionIcon = _iconForLabel(widget.label);

    if (!widget.isCollapsible) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isPrimary
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
                    size: widget.isPrimary ? 18 : 15,
                    color: labelColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: widget.isPrimary
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
              label: '${widget.label}: ${widget.text}',
              child: SelectableText(
                widget.text,
                style: widget.isPrimary
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isPrimary
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Semantics(
                    header: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          sectionIcon,
                          size: widget.isPrimary ? 18 : 15,
                          color: labelColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.label,
                          style: widget.isPrimary
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
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Semantics(
                container: true,
                excludeSemantics: true,
                label: '${widget.label}: ${widget.text}',
                child: SelectableText(
                  widget.text,
                  style: widget.isPrimary
                      ? theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        )
                      : theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

