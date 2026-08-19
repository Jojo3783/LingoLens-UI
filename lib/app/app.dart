import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../application/analysis_controller.dart';
import '../application/analysis_action_contracts.dart';
import '../application/persistence_controller.dart';
import '../application/provider_composition.dart';
import '../application/provider_settings_controller.dart';
import '../application/windows_capture_controller.dart';
import '../domain/provider_contracts.dart';
import '../infrastructure/fake_speech_adapter.dart';
import '../infrastructure/flutter_clipboard_writer.dart';
import '../infrastructure/in_memory_persistence.dart';
import '../infrastructure/local_file_persistence.dart';
import '../infrastructure/openai/secure_credential_store.dart';
import '../infrastructure/windows/windows_platform_services.dart';
import '../presentation/navigation_shell.dart';

final class LingoLensApp extends StatefulWidget {
  const LingoLensApp({
    this.providerSelection,
    this.providerSettings,
    this.persistence,
    super.key,
  });

  final AnalysisProviderSelection? providerSelection;
  final ProviderSettingsController? providerSettings;
  final PersistenceController? persistence;

  @override
  State<LingoLensApp> createState() => _LingoLensAppState();
}

final class _LingoLensAppState extends State<LingoLensApp> {
  late AnalysisProviderComposition _composition;
  late final AnalysisController _controller;
  late final FakeSpeechAdapter _speech;
  late final PersistenceController _persistence;
  WindowsCaptureController? _windowsCapture;
  late final ProviderSettingsController _providerSettings;
  late final ProviderRuntimeCoordinator _runtime;
  late final Future<void> _providerHydration;

  @override
  void initState() {
    super.initState();
    final initialSelection =
        widget.providerSelection ?? const FakeProviderSelection();
    _composition = createAnalysisProviderComposition(
      selection: initialSelection,
    );
    final initialProvider = switch (initialSelection) {
      OpenAiResponsesProviderSelection() => ProviderKind.openAiResponses,
      _ => ProviderKind.fake,
    };
    _providerSettings =
        widget.providerSettings ??
        ProviderSettingsController(
          credentials: FlutterSecureCredentialStore(),
          initialProvider: initialProvider,
        );
    _runtime = ProviderRuntimeCoordinator(_providerSettings);
    _speech = FakeSpeechAdapter();
    final persistenceBundle = LocalFilePersistenceBundle();
    _persistence =
        widget.persistence ??
        PersistenceController(
          history: persistenceBundle.history,
          cache: persistenceBundle.cache,
          settings: persistenceBundle.settings,
          favorites: persistenceBundle.favorites,
          feedback: persistenceBundle.feedback,
        );
    _controller = AnalysisController(
      provider: _composition.provider,
      strategy: _composition.strategy,
      actionPorts: AnalysisActionPorts(
        persistence: _persistence,
        clipboard: const FlutterClipboardWriter(),
        speech: _speech,
        clock: const SystemClock(),
        historyIds: const DeterministicHistoryIdGenerator(),
      ),
    );
    _providerHydration = _hydrateProvider();
    if (Platform.isWindows) {
      _windowsCapture = WindowsCaptureController(
        hotkey: WindowsGlobalHotkeyService(),
        selectedText: WindowsSelectedTextService(),
        floatingWindow: WindowsFloatingWindowService(),
        activation: WindowsWindowActivationService(),
      );
      unawaited(_windowsCapture!.initialize());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    final windowsCapture = _windowsCapture;
    if (windowsCapture != null) {
      unawaited(windowsCapture.dispose());
    }
    _providerSettings.dispose();
    super.dispose();
  }

  final ValueNotifier<ThemeMode> _themeModeNotifier =
      ValueNotifier(ThemeMode.system);

  @override
  Widget build(BuildContext context) {
    ThemeData buildTheme(Brightness brightness) {
      final colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: brightness,
      );
      return ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          color: colorScheme.surfaceContainer,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            minimumSize: const Size(48, 44),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: colorScheme.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            minimumSize: const Size(48, 44),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.primary,
        ),
      );
    }

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'LingoLens',
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          home: FutureBuilder<void>(
            future: _providerHydration,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Scaffold(body: Center(child: Text('正在準備分析服務…')));
              }
              return AnimatedBuilder(
                animation: _providerSettings,
                builder: (context, _) => LingoLensNavigationShell(
                  controller: _controller,
                  windowsCapture: _windowsCapture,
                  providerDisclosure: _composition.disclosure,
                  settings: _providerSettings,
                  selectedProvider: _providerSettings.selectedProvider,
                  persistence: _persistence,
                  themeModeNotifier: _themeModeNotifier,
                  onThemeModeChanged: (mode) {
                    _themeModeNotifier.value = mode;
                  },
                  onProviderChanged: (provider) {
                    unawaited(_switchProvider(provider));
                  },
                  onCredentialChanged: () {
                    unawaited(_refreshSelectedProvider());
                  },
                  onFailureScenarioChanged: (value) {
                    _composition.fakeProvider?.shouldFail = value;
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _switchProvider(ProviderKind provider) async {
    if (!await _providerSettings.selectProvider(provider)) {
      return;
    }
    await _refreshSelectedProvider();
  }

  Future<void> _refreshSelectedProvider() async {
    final nextComposition = _runtime.compose();
    _controller.replaceRuntime(
      provider: nextComposition.provider,
      strategy: nextComposition.strategy,
    );
    if (!mounted) {
      return;
    }
    setState(() => _composition = nextComposition);
  }

  Future<void> _hydrateProvider() async {
    await _providerSettings.initialize();
    if (widget.providerSelection != null) {
      return;
    }
    final nextComposition = _runtime.compose();
    _controller.replaceRuntime(
      provider: nextComposition.provider,
      strategy: nextComposition.strategy,
    );
    _composition = nextComposition;
  }
}
