import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/application/provider_settings_controller.dart';
import 'package:lingolens/domain/provider_contracts.dart';
import 'package:lingolens/infrastructure/fake_analysis_provider.dart';
import 'package:lingolens/infrastructure/openai/secure_credential_store.dart';
import 'package:lingolens/presentation/navigation_shell.dart';

void main() {
  testWidgets('shell uses hamburger menu drawer for navigation', (
    tester,
  ) async {
    _setViewport(tester, const Size(1100, 800));
    final controller = AnalysisController(provider: FakeAnalysisProvider());
    final settings = _settings();
    addTearDown(controller.dispose);
    addTearDown(settings.dispose);

    await tester.pumpWidget(_app(controller, settings));

    expect(find.byIcon(Icons.menu), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('分析'), findsAtLeastNWidgets(1));
    expect(find.text('設定'), findsOneWidget);
  });

  testWidgets(
    'secure settings save clears the entered key and reports status',
    (tester) async {
      _setViewport(tester, const Size(600, 800));
      final controller = AnalysisController(provider: FakeAnalysisProvider());
      final store = InMemorySecureCredentialStore();
      final settings = _settings(store);
      await settings.initialize();
      addTearDown(controller.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(_app(controller, settings));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('設定'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('openai-api-key')),
        'synthetic-t12r-credential',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('save-and-apply-openai')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-and-apply-openai')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('openai-api-key')))
            .controller
            ?.text,
        isEmpty,
      );
      expect(find.text('已安全設定'), findsOneWidget);
      expect(await store.read(openAiApiKeyAlias), 'synthetic-t12r-credential');
      expect(find.text('synthetic-t12r-credential'), findsNothing);
      expect(settings.toString(), isNot(contains('synthetic-t12r-credential')));
    },
  );
}

ProviderSettingsController _settings([InMemorySecureCredentialStore? store]) =>
    ProviderSettingsController(
      credentials: store ?? InMemorySecureCredentialStore(),
      environment: const _EmptyEnvironment(),
    );

Widget _app(
  AnalysisController controller,
  ProviderSettingsController settings,
) => MaterialApp(
  theme: ThemeData(useMaterial3: true),
  home: LingoLensNavigationShell(
    controller: controller,
    providerDisclosure: const ProviderDisclosure(
      providerName: 'Deterministic Fake Provider',
      message: '目前使用本機 deterministic Fake Provider，不會傳送網路請求。',
    ),
    onFailureScenarioChanged: (_) {},
    windowsCapture: null,
    selectedProvider: ProviderKind.fake,
    onProviderChanged: (_) {},
    settings: settings,
    onCredentialChanged: () {},
  ),
);

void _setViewport(WidgetTester tester, Size logicalSize) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  addTearDown(tester.view.reset);
}

final class _EmptyEnvironment implements EnvironmentCredentialReader {
  const _EmptyEnvironment();

  @override
  String? readApiKey() => null;
}
