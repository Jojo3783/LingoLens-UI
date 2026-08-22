import 'package:flutter/material.dart';

import '../application/persistence_controller.dart';
import '../application/provider_settings_controller.dart';
import '../domain/provider_contracts.dart';
import 'lingolens_surface.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.selectedProvider,
    required this.onProviderChanged,
    required this.settings,
    required this.onCredentialChanged,
    this.persistence,
    this.themeModeNotifier,
    this.onThemeModeChanged,
    super.key,
  });

  final ProviderKind selectedProvider;
  final ValueChanged<ProviderKind> onProviderChanged;
  final ProviderSettingsController settings;
  final VoidCallback onCredentialChanged;
  final PersistenceController? persistence;
  final ValueNotifier<ThemeMode>? themeModeNotifier;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _modelController;
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _historyWritesEnabled = true;
  bool _cacheEnabled = true;

  Future<void> _confirmClearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('clear-cache-dialog'),
        title: const Text('確認清除快取'),
        content: const Text(
          '確定要清除分析快取嗎？\n\n此操作僅會釋放本機暫存空間以重新發起查詢，您的「歷史紀錄」與「最愛收藏」完全不會受到影響。',
        ),
        actions: [
          TextButton(
            key: const ValueKey('clear-cache-cancel-btn'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const ValueKey('clear-cache-confirm-btn'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('確認清除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await widget.persistence?.clearCache();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: ValueKey('clear-cache-snackbar'),
        content: Text('已清除快取紀錄（歷史與最愛依然保留）'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _modelController = TextEditingController(text: widget.settings.model);
  }

  @override
  void dispose() {
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth >= 900
            ? 760.0
            : double.infinity;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              children: [
                const LingoLensSectionHeader(
                  title: '設定',
                  description: '管理目前分析服務、本機安全與歷史快取設定。',
                ),
                const SizedBox(height: 20),
                LingoLensSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LingoLensSectionHeader(
                        title: '主題外觀',
                        description: '切換淺色模式 (Light) 或深色模式 (Dark)。',
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable:
                            widget.themeModeNotifier ?? ValueNotifier(ThemeMode.light),
                        builder: (context, currentMode, _) {
                          final effectiveMode = currentMode == ThemeMode.dark
                              ? ThemeMode.dark
                              : ThemeMode.light;
                          return SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.light,
                                label: Text('淺色模式'),
                                icon: Icon(Icons.light_mode_outlined),
                              ),
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.dark,
                                label: Text('深色模式'),
                                icon: Icon(Icons.dark_mode_outlined),
                              ),
                            ],
                            selected: {effectiveMode},
                            onSelectionChanged: (newSelection) {
                              widget.themeModeNotifier?.value = newSelection.first;
                              widget.onThemeModeChanged?.call(newSelection.first);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LingoLensSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LingoLensSectionHeader(
                        title: '分析服務',
                        description: '選擇本次工作階段使用的 Provider。',
                      ),
                      const SizedBox(height: 16),
                      RadioGroup<ProviderKind>(
                        groupValue: widget.selectedProvider,
                        onChanged: (value) {
                          if (value != null) {
                            widget.onProviderChanged(value);
                          }
                        },
                        child: Column(
                          children: [
                            RadioListTile<ProviderKind>(
                              value: ProviderKind.fake,
                              title: const Text('Deterministic Fake Provider'),
                              subtitle: const Text(
                                '本機 deterministic data，不會傳送 network request。',
                              ),
                              secondary: const Icon(Icons.science_outlined),
                            ),
                            RadioListTile<ProviderKind>(
                              value: ProviderKind.openAiResponses,
                              title: const Text('OpenAI Responses API'),
                              subtitle: const Text(
                                '需要明確設定 credential；輸入內容會送至遠端服務。',
                              ),
                              secondary: const Icon(Icons.cloud_outlined),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LingoLensSurface(
                  child: AnimatedBuilder(
                    animation: widget.settings,
                    builder: (context, _) => _buildOpenAiSettings(context),
                  ),
                ),
                const SizedBox(height: 16),
                LingoLensSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LingoLensSectionHeader(
                        title: '歷史與快取設定',
                        description: '控制分析紀錄寫入、獨立快取與清除歷史。',
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        key: const ValueKey('history-writes-switch'),
                        title: const Text('紀錄寫入歷史 (History Writes)'),
                        subtitle: const Text('關閉後新的分析結果將不會寫入歷史紀錄。'),
                        value: _historyWritesEnabled,
                        onChanged: (enabled) async {
                          setState(() => _historyWritesEnabled = enabled);
                          await widget.persistence?.setHistoryWritesEnabled(enabled);
                        },
                      ),
                      SwitchListTile(
                        key: const ValueKey('analysis-cache-switch'),
                        title: const Text('啟用分析快取 (Enable Analysis Cache)'),
                        subtitle: const Text(
                          '安全重用相同輸入的分析結果；關閉後每次皆重新發起 AI 查詢。',
                        ),
                        value: _cacheEnabled,
                        onChanged: (enabled) {
                          setState(() => _cacheEnabled = enabled);
                        },
                      ),
                      const Divider(height: 24),
                      Text(
                        '快取管理 (Analysis Cache)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '快取用於加速相同條件下的查詢（容量上限 100 筆，採 FIFO 自動淘汰）。清除快取只會釋放暫存，完全不會影響您的歷史紀錄與最愛收藏。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const ValueKey('clear-cache-btn'),
                              icon: const Icon(Icons.cleaning_services_outlined),
                              label: const Text('清除快取 (Clear Cache)'),
                              onPressed: _confirmClearCache,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LingoLensSurface(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: LingoLensSectionHeader(
                          title: '安全與隱私',
                          description:
                              'API key 只會寫入 OS secure storage；畫面、Log 與 evidence 不會顯示完整內容。',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOpenAiSettings(BuildContext context) {
    final status = switch (widget.settings.credentialStatus) {
      ProviderCredentialStatus.loading => '正在讀取安全設定…',
      ProviderCredentialStatus.missing => '尚未設定 credential',
      ProviderCredentialStatus.environment => '使用環境設定',
      ProviderCredentialStatus.stored => '已安全設定',
      ProviderCredentialStatus.invalid => '設定無效',
      ProviderCredentialStatus.secureStorageError => '安全設定讀取／儲存失敗，未完整套用變更',
    };
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LingoLensSectionHeader(
          title: 'OpenAI Provider Profile',
          description: '目前只提供一個 openai-default profile；資料結構保留未來擴充空間。',
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('openai-model'),
          controller: _modelController,
          decoration: const InputDecoration(
            labelText: 'Model',
            helperText: '預設為 gpt-5-mini；只儲存 model identifier。',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('openai-api-key'),
          controller: _apiKeyController,
          obscureText: _obscureApiKey,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'API key',
            helperText: '不會回填既有 key；只在目前輸入控制項中暫存。',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: _obscureApiKey ? '顯示目前輸入值' : '隱藏目前輸入值',
              onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
              icon: Icon(
                _obscureApiKey
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                key: const ValueKey('save-and-apply-openai'),
                onPressed: () async {
                  final result = await widget.settings.saveAndApply(
                    model: _modelController.text,
                    apiKey: _apiKeyController.text,
                  );
                  if (result.success) {
                    _apiKeyController.clear();
                    widget.onCredentialChanged();
                  }
                },
                child: const Text('儲存並套用'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('remove-openai-api-key'),
                onPressed: () async {
                  if (await widget.settings.removeApiKey()) {
                    widget.onCredentialChanged();
                  }
                },
                child: const Text('移除已儲存 key'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.settings.credentialStatus == ProviderCredentialStatus.stored ||
                        widget.settings.credentialStatus == ProviderCredentialStatus.environment
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: widget.settings.credentialStatus == ProviderCredentialStatus.stored ||
                        widget.settings.credentialStatus == ProviderCredentialStatus.environment
                    ? Colors.green.shade600
                    : colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Semantics(
                liveRegion: true,
                label: 'Credential 狀態：$status',
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.settings.errorMessage case final message?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
