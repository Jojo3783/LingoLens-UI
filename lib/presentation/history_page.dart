import 'package:flutter/material.dart';

import '../application/persistence_controller.dart';
import '../domain/analysis_models.dart';
import '../domain/persistence_contracts.dart';
import 'history_record_tile.dart';
import 'lingolens_surface.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    required this.persistence,
    super.key,
  });

  final PersistenceController persistence;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<HistoryRecord>> _historyFuture;
  late Future<List<FavoriteRecord>> _favoritesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _historyFuture = widget.persistence.visibleHistory();
      _favoritesFuture = widget.persistence.favorites();
    });
  }

  Future<void> _confirmDelete({
    required HistoryRecord record,
    required bool isFavorite,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('delete-confirm-dialog'),
        title: const Text('確認刪除'),
        content: Text(
          isFavorite
              ? '確定要刪除這筆紀錄嗎？\n\n此項目已加入最愛，刪除後將同步從最愛清單中移除，且無法復原。'
              : '確定要刪除這筆紀錄嗎？此操作無法復原。',
        ),
        actions: [
          TextButton(
            key: const ValueKey('delete-cancel-btn'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const ValueKey('delete-confirm-btn'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('確認刪除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.persistence.deleteHistory(record.id);
      _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('刪除失敗，請稍後再試。'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth =
            constraints.maxWidth >= 900 ? 760.0 : double.infinity;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: LingoLensSectionHeader(
                        title: '歷史紀錄',
                        description:
                            '顯示最近的查詢分析紀錄（自動保存最近 20 筆，跨 App 重新開啟依然保留）。',
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: '重新整理',
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: _refresh,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜尋歷史查詢紀錄…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: '清除搜尋',
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Object>>(
                  future: Future.wait([_historyFuture, _favoritesFuture]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return LingoLensSurface(
                        child: Text(
                          '讀取歷史紀錄時發生錯誤：${snapshot.error}',
                          style: TextStyle(
                            color: colorScheme.error,
                          ),
                        ),
                      );
                    }
                    final results = snapshot.data!;
                    final history = results[0] as List<HistoryRecord>;
                    final favorites = results[1] as List<FavoriteRecord>;
                    final favoriteSet =
                        favorites.map((f) => f.historyRecordId).toSet();

                    if (history.isEmpty) {
                      return LingoLensSurface(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.history_rounded,
                                    size: 36,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '目前沒有歷史紀錄',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '在分析工作台進行文字分析後，查詢結果將會自動記錄於此。',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final filteredHistory = _searchQuery.isEmpty
                        ? history
                        : history.where((r) {
                            final inputMatch =
                                r.input.toLowerCase().contains(_searchQuery);
                            final resultMatch = r.mode == AnalysisMode.reading
                                ? r.result.reading.translation
                                    .toLowerCase()
                                    .contains(_searchQuery)
                                : r.result.expression.natural
                                    .toLowerCase()
                                    .contains(_searchQuery);
                            return inputMatch || resultMatch;
                          }).toList();

                    if (filteredHistory.isEmpty) {
                      return LingoLensSurface(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 36,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '找不到符合「$_searchQuery」的歷史紀錄',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (final record in filteredHistory)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: HistoryRecordTile(
                              record: record,
                              isFavorite: favoriteSet.contains(record.id),
                               onToggleFavorite: () async {
                                final nextState =
                                    !favoriteSet.contains(record.id);
                                await widget.persistence.setFavorite(
                                  historyRecordId: record.id,
                                  createdAt: DateTime.now(),
                                  isFavorite: nextState,
                                );
                                _refresh();
                              },
                              onDelete: () => _confirmDelete(
                                record: record,
                                isFavorite: favoriteSet.contains(record.id),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
