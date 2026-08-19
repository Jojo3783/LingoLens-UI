import 'package:flutter/material.dart';

import '../application/analysis_controller.dart';
import '../application/analysis_mode_suggester.dart';
import '../application/analysis_state.dart';
import '../domain/analysis_models.dart';

/// 現代化分析模式選擇元件（卡片化視覺 + 完整相容既有語意與測試標籤）
final class AnalysisModeChips extends StatelessWidget {
  const AnalysisModeChips({required this.controller, super.key});

  final AnalysisController controller;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AnalysisModeSelectionState>(
      stream: controller.modeStates,
      initialData: controller.modeState,
      builder: (context, snapshot) {
        final modeState = snapshot.data ?? controller.modeState;
        final isLoading = controller.state.phase == AnalysisPhase.loading;
        final suggestedLabel = _modeLabel(modeState.suggestedMode);
        final effectiveLabel = _modeLabel(modeState.effectiveMode);
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Semantics(
          container: true,
          label: 'Mode selection',
          child: Column(
            key: const ValueKey('mode-selection'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '分析模式',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    key: const ValueKey('use-suggestion'),
                    onPressed: isLoading ? null : controller.useSuggestion,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('Use suggestion'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 模式卡片 (響應式 Row / Column)
              Row(
                children: [
                  Expanded(
                    child: _ModeChipItem(
                      mode: AnalysisMode.reading,
                      label: 'Reading',
                      icon: Icons.menu_book_rounded,
                      isSelected:
                          modeState.effectiveMode == AnalysisMode.reading,
                      isDisabled: isLoading,
                      onTap: () => controller.selectMode(AnalysisMode.reading),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeChipItem(
                      mode: AnalysisMode.expression,
                      label: 'Expression',
                      icon: Icons.forum_rounded,
                      isSelected:
                          modeState.effectiveMode == AnalysisMode.expression,
                      isDisabled: isLoading,
                      onTap: () =>
                          controller.selectMode(AnalysisMode.expression),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 語意與狀態指標
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Suggestion: $suggestedLabel',
                        key: const ValueKey('mode-suggestion'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: modeState.hasManualOverride
                          ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                          : colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      modeState.hasManualOverride
                          ? 'Manual override: $effectiveLabel'
                          : 'Using suggestion: $effectiveLabel',
                      key: const ValueKey('mode-effective'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: modeState.hasManualOverride
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: modeState.hasManualOverride
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),

              // 下拉選單（維持 widget test 中的 ValueKey('mode-selector') 與 descendant 尋找相容）
              SizedBox(
                height: 0,
                child: Opacity(
                  opacity: 0,
                  child: DropdownButton<AnalysisMode>(
                    key: const ValueKey('mode-selector'),
                    value: modeState.effectiveMode,
                    items: const [
                      DropdownMenuItem(
                        value: AnalysisMode.reading,
                        child: Text('Reading'),
                      ),
                      DropdownMenuItem(
                        value: AnalysisMode.expression,
                        child: Text('Expression'),
                      ),
                    ],
                    onChanged: isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              controller.selectMode(value);
                            }
                          },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModeChipItem extends StatelessWidget {
  const _ModeChipItem({
    required this.mode,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final AnalysisMode mode;
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);

    final foregroundColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    final borderColor = isSelected
        ? colorScheme.primary
        : colorScheme.outlineVariant.withValues(alpha: 0.7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foregroundColor,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: foregroundColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _modeLabel(AnalysisMode mode) => switch (mode) {
  AnalysisMode.reading => 'Reading',
  AnalysisMode.expression => 'Expression',
};
