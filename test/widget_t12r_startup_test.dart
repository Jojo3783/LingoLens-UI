import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/app/app.dart';
import 'package:lingolens/application/provider_settings_controller.dart';
import 'package:lingolens/domain/provider_contracts.dart';
import 'package:lingolens/infrastructure/openai/secure_credential_store.dart';

void main() {
  testWidgets(
    'startup hydrates persisted OpenAI before analysis becomes ready',
    (tester) async {
      final store = InMemorySecureCredentialStore();
      await store.write(
        preferredProviderKey,
        ProviderKind.openAiResponses.wireValue,
      );
      await store.write(openAiModelKey, 'gpt-5-mini');
      await store.write(openAiApiKeyAlias, 'synthetic-startup-credential');
      final settings = ProviderSettingsController(
        credentials: store,
        environment: const _EmptyEnvironment(),
      );

      await tester.pumpWidget(LingoLensApp(providerSettings: settings));
      expect(find.text('正在準備分析服務…'), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('OpenAI Responses API'), findsOneWidget);
      expect(find.text('Deterministic Fake Provider'), findsNothing);
      expect(find.text('synthetic-startup-credential'), findsNothing);
      expect(settings.selectedProvider, ProviderKind.openAiResponses);
      expect(settings.credentialStatus, ProviderCredentialStatus.stored);
    },
  );

  testWidgets(
    'persisted OpenAI without credential stays selected and does not use Fake',
    (tester) async {
      final store = InMemorySecureCredentialStore();
      await store.write(
        preferredProviderKey,
        ProviderKind.openAiResponses.wireValue,
      );
      final settings = ProviderSettingsController(
        credentials: store,
        environment: const _EmptyEnvironment(),
      );

      await tester.pumpWidget(LingoLensApp(providerSettings: settings));
      await tester.pumpAndSettle();

      expect(find.text('OpenAI Responses API'), findsOneWidget);
      expect(find.text('Deterministic Fake Provider'), findsNothing);
      expect(settings.selectedProvider, ProviderKind.openAiResponses);
      expect(settings.credentialStatus, ProviderCredentialStatus.missing);
    },
  );

  testWidgets('secure storage startup failure leaves Fake usable', (
    tester,
  ) async {
    final settings = ProviderSettingsController(
      credentials: const _ThrowingStore(),
      environment: const _EmptyEnvironment(),
    );

    await tester.pumpWidget(LingoLensApp(providerSettings: settings));
    await tester.pumpAndSettle();

    expect(find.text('Deterministic Fake Provider'), findsOneWidget);
    expect(settings.selectedProvider, ProviderKind.fake);
    expect(
      settings.credentialStatus,
      ProviderCredentialStatus.secureStorageError,
    );
  });
}

final class _EmptyEnvironment implements EnvironmentCredentialReader {
  const _EmptyEnvironment();

  @override
  String? readApiKey() => null;
}

final class _ThrowingStore implements SecureCredentialStore {
  const _ThrowingStore();

  @override
  Future<String?> read(String key) =>
      Future<String?>.error(StateError('synthetic secure read failure'));

  @override
  Future<void> write(String key, String value) =>
      Future<void>.error(StateError('synthetic secure write failure'));

  @override
  Future<void> delete(String key) =>
      Future<void>.error(StateError('synthetic secure delete failure'));
}
