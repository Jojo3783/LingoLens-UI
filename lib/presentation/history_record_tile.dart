import 'package:flutter/material.dart';

import '../application/analysis_state.dart';
import '../domain/analysis_models.dart';
import '../domain/persistence_contracts.dart';
import 'analysis_result_card.dart';
import 'lingolens_surface.dart';

/// 支持點擊展開/收起完整詳細分析結果 (AnalysisResultCard) 的歷史/最愛卡片元件
final class HistoryRecordTile extends StatefulWidget {
  const HistoryRecordTile({
    required this.record,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onDelete,
    super.key,
  });

  final HistoryRecord record;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onDelete;

  @override
  State<HistoryRecordTile> createState() => _HistoryRecordTileState();
}

class _HistoryRecordTileState extends State<HistoryRecordTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isReading = widget.record.mode == AnalysisMode.reading;

    final summaryText = isReading
        ? widget.record.result.reading.translation
        : widget.record.result.expression.natural;

    final analysisSuccess = AnalysisSuccess(
      requestId: RequestId.create(),
      input: widget.record.input,
      mode: widget.record.mode,
      result: widget.record.result,
    );

    return LingoLensSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 頂部列：模式 Badge 膠囊與功能按鈕組
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isReading
                      ? colorScheme.primaryContainer
                      : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isReading ? Icons.menu_book_rounded : Icons.forum_rounded,
                      size: 13,
                      color: isReading
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.record.mode.name.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isReading
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: widget.isFavorite ? '取消釘選最愛' : '釘選至最愛',
                    icon: Icon(
                      widget.isFavorite ? Icons.star : Icons.star_border,
                      color: widget.isFavorite
                          ? Colors.amber.shade600
                          : colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    onPressed: widget.onToggleFavorite,
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      tooltip: '刪除紀錄',
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: colorScheme.error.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      onPressed: widget.onDelete,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 原始輸入文字
          Text(
            widget.record.input,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 10),

          // 簡要翻譯/表達預覽區
          if (!_isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                summaryText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),

          // 展開後的完整詳細 AnalysisResultCard 卡片
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            AnalysisResultCard(
              success: analysisSuccess,
            ),
          ],
          const SizedBox(height: 10),

          // 底部：時間戳記與 展開/收起 詳細回答按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isExpanded ? '收起詳細分析' : '查看完整詳細回答',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                widget.record.createdAt.toLocal().toString().split('.')[0],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
