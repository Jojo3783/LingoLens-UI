import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/provider_settings_controller.dart';
import 'package:lingolens/application/persistence_controller.dart';
import 'package:lingolens/domain/persistence_contracts.dart';
import 'package:lingolens/domain/provider_contracts.dart';
import 'package:lingolens/infrastructure/in_memory_persistence.dart';
import 'package:lingolens/infrastructure/openai/secure_credential_store.dart';
import 'package:lingolens/presentation/settings_page.dart';

final class _RecordingSettingsRepository implements SettingsRepository {
  SettingsSnapshot _snapshot = const SettingsSnapshot();

  @override
  Future<SettingsSnapshot> read() async => _snapshot;

  @override
  Future<void> setHistoryWritesEnabled(bool enabled) async {
    _snapshot = SettingsSnapshot(historyWritesEnabled: enabled);
  }
}

final class _RecordingCacheRepository implements AnalysisCacheRepository {
  int clearCallCount = 0;

  @override
  Future<void> clear() async {
    clearCallCount++;
  }

  @override
  Future<AnalysisCacheEntry?> get(String key) async => null;

  @override
  Future<void> put(AnalysisCacheEntry entry) async {}
}

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  group('F-003 Cache-First Settings UI Tests', () {
    late _RecordingCacheRepository cacheRepo;
    late _RecordingSettingsRepository settingsRepo;
    late PersistenceController persistence;
    late ProviderSettingsController settingsController;

    setUp(() async {
      cacheRepo = _RecordingCacheRepository();
      settingsRepo = _RecordingSettingsRepository();
      persistence = PersistenceController(
        history: InMemoryHistoryRepository(),
        cache: cacheRepo,
        settings: settingsRepo,
        favorites: InMemoryFavoriteRepository(),
        feedback: InMemoryFeedbackRepository(),
      );
      settingsController = ProviderSettingsController(
        credentials: InMemorySecureCredentialStore(),
      );
      await settingsController.initialize();
    });

    testWidgets('renders analysis cache switch and clear cache controls', (
      tester,
    ) async {
      _setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsPage(
              selectedProvider: ProviderKind.fake,
              onProviderChanged: (_) {},
              settings: settingsController,
              onCredentialChanged: () {},
              persistence: persistence,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const ValueKey('analysis-cache-switch'));
      await tester.ensureVisible(switchFinder);
      expect(switchFinder, findsOneWidget);

      final clearBtnFinder = find.byKey(const ValueKey('clear-cache-btn'));
      await tester.ensureVisible(clearBtnFinder);
      expect(clearBtnFinder, findsOneWidget);

      expect(find.text('啟用分析快取 (Enable Analysis Cache)'), findsOneWidget);
      expect(find.text('快取管理 (Analysis Cache)'), findsOneWidget);
    });

    testWidgets(
      'clear cache dialog cancel button dismisses dialog without clearing cache',
      (tester) async {
        _setViewport(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsPage(
                selectedProvider: ProviderKind.fake,
                onProviderChanged: (_) {},
                settings: settingsController,
                onCredentialChanged: () {},
                persistence: persistence,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final clearBtnFinder = find.byKey(const ValueKey('clear-cache-btn'));
        await tester.ensureVisible(clearBtnFinder);
        await tester.pumpAndSettle();

        // 點擊清除快取按鈕
        await tester.tap(clearBtnFinder);
        await tester.pumpAndSettle();

        // 彈出確認對話框
        expect(find.byKey(const ValueKey('clear-cache-dialog')), findsOneWidget);
        expect(find.text('確認清除快取'), findsOneWidget);
        expect(
          find.textContaining('您的「歷史紀錄」與「最愛收藏」完全不會受到影響'),
          findsOneWidget,
        );

        // 點擊取消
        await tester.tap(find.byKey(const ValueKey('clear-cache-cancel-btn')));
        await tester.pumpAndSettle();

        // 對話框關閉且未執行清除
        expect(find.byKey(const ValueKey('clear-cache-dialog')), findsNothing);
        expect(cacheRepo.clearCallCount, 0);
      },
    );

    testWidgets(
      'clear cache dialog confirm button clears cache and displays snackbar',
      (tester) async {
        _setViewport(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsPage(
                selectedProvider: ProviderKind.fake,
                onProviderChanged: (_) {},
                settings: settingsController,
                onCredentialChanged: () {},
                persistence: persistence,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final clearBtnFinder = find.byKey(const ValueKey('clear-cache-btn'));
        await tester.ensureVisible(clearBtnFinder);
        await tester.pumpAndSettle();

        // 點擊清除快取按鈕
        await tester.tap(clearBtnFinder);
        await tester.pumpAndSettle();

        // 點擊確認清除
        await tester.tap(find.byKey(const ValueKey('clear-cache-confirm-btn')));
        await tester.pumpAndSettle();

        // 對話框關閉且調用了 clearCache
        expect(find.byKey(const ValueKey('clear-cache-dialog')), findsNothing);
        expect(cacheRepo.clearCallCount, 1);
        expect(
          find.text('已清除快取紀錄（歷史與最愛依然保留）'),
          findsOneWidget,
        );
      },
    );

    testWidgets('toggling analysis cache switch updates UI state', (
      tester,
    ) async {
      _setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsPage(
              selectedProvider: ProviderKind.fake,
              onProviderChanged: (_) {},
              settings: settingsController,
              onCredentialChanged: () {},
              persistence: persistence,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const ValueKey('analysis-cache-switch'));
      await tester.ensureVisible(switchFinder);
      expect(switchFinder, findsOneWidget);

      // 點擊切換開關
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.value, isFalse);
    });
  });
}
