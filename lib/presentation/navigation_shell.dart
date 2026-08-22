import 'package:flutter/material.dart';

import '../application/analysis_controller.dart';
import '../application/persistence_controller.dart';
import '../application/provider_settings_controller.dart';
import '../application/windows_capture_controller.dart';
import '../domain/provider_contracts.dart';
import 'analysis_page.dart';
import 'favorites_page.dart';
import 'history_page.dart';
import 'review_page.dart';
import 'settings_page.dart';

class LingoLensNavigationShell extends StatefulWidget {
  const LingoLensNavigationShell({
    required this.controller,
    required this.providerDisclosure,
    required this.onFailureScenarioChanged,
    required this.selectedProvider,
    required this.onProviderChanged,
    required this.settings,
    required this.onCredentialChanged,
    this.persistence,
    this.windowsCapture,
    this.themeModeNotifier,
    this.onThemeModeChanged,
    super.key,
  });

  final AnalysisController controller;
  final ProviderDisclosure? providerDisclosure;
  final ValueChanged<bool> onFailureScenarioChanged;
  final WindowsCaptureController? windowsCapture;
  final ProviderKind selectedProvider;
  final ValueChanged<ProviderKind> onProviderChanged;
  final ProviderSettingsController settings;
  final VoidCallback onCredentialChanged;
  final PersistenceController? persistence;
  final ValueNotifier<ThemeMode>? themeModeNotifier;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<LingoLensNavigationShell> createState() =>
      _LingoLensNavigationShellState();
}

class _LingoLensNavigationShellState extends State<LingoLensNavigationShell> {
  int _destination = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final destinations = [
      const _Destination(
        icon: Icons.translate_outlined,
        selectedIcon: Icons.translate_rounded,
        label: '分析',
      ),
      const _Destination(
        icon: Icons.history_outlined,
        selectedIcon: Icons.history_rounded,
        label: '歷史',
      ),
      const _Destination(
        icon: Icons.star_outline_rounded,
        selectedIcon: Icons.star_rounded,
        label: '最愛',
      ),
      const _Destination(
        icon: Icons.psychology_outlined,
        selectedIcon: Icons.psychology_rounded,
        label: '複習',
      ),
      const _Destination(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: '設定',
      ),
    ];

    Widget content;
    String headerTitle;
    switch (_destination) {
      case 0:
        content = AnalysisPage(
          controller: widget.controller,
          windowsCapture: widget.windowsCapture,
          providerDisclosure: widget.providerDisclosure,
          onFailureScenarioChanged: widget.onFailureScenarioChanged,
        );
        headerTitle = '分析工作台';
      case 1:
        content = widget.persistence != null
            ? HistoryPage(persistence: widget.persistence!)
            : const Center(child: Text('歷史紀錄服務未提供'));
        headerTitle = '歷史紀錄';
      case 2:
        content = widget.persistence != null
            ? FavoritesPage(persistence: widget.persistence!)
            : const Center(child: Text('最愛紀錄服務未提供'));
        headerTitle = '最愛紀錄';
      case 3:
        content = widget.persistence != null
            ? ReviewPage(persistence: widget.persistence!)
            : const Center(child: Text('複習服務未提供'));
        headerTitle = '回想複習';
      case 4:
      default:
        content = SettingsPage(
          selectedProvider: widget.selectedProvider,
          onProviderChanged: widget.onProviderChanged,
          settings: widget.settings,
          onCredentialChanged: widget.onCredentialChanged,
          persistence: widget.persistence,
          themeModeNotifier: widget.themeModeNotifier,
          onThemeModeChanged: widget.onThemeModeChanged,
        );
        headerTitle = '工作階段設定';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: '開啟選單',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            titleSpacing: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.translate_rounded,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'LingoLens',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    headerTitle,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (widget.themeModeNotifier != null)
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: widget.themeModeNotifier!,
                  builder: (context, mode, _) {
                    final isDark = mode == ThemeMode.dark ||
                        (mode == ThemeMode.system &&
                            MediaQuery.platformBrightnessOf(context) ==
                                Brightness.dark);
                    return IconButton(
                      tooltip: isDark ? '切換淺色模式' : '切換深色模式',
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                      onPressed: () {
                        final next =
                            isDark ? ThemeMode.light : ThemeMode.dark;
                        widget.themeModeNotifier!.value = next;
                        widget.onThemeModeChanged?.call(next);
                      },
                    );
                  },
                ),
              const SizedBox(width: 12),
            ],
          ),
          drawer: Drawer(
            child: SafeArea(
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                    ),
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.translate_rounded,
                            size: 32,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LingoLens',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '語言工作台',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (int i = 0; i < destinations.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Icon(
                          _destination == i
                              ? destinations[i].selectedIcon
                              : destinations[i].icon,
                          color: _destination == i
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          destinations[i].label,
                          style: TextStyle(
                            fontWeight: _destination == i
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _destination == i
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                        selected: _destination == i,
                        selectedTileColor: colorScheme.primaryContainer
                            .withValues(alpha: 0.4),
                        onTap: () {
                          setState(() => _destination = i);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          body: content,
        );
      },
    );
  }
}

class _Destination {
  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
