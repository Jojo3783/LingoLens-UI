import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/provider_settings_controller.dart';
import 'package:lingolens/domain/provider_contracts.dart';
import 'package:lingolens/infrastructure/openai/secure_credential_store.dart';

void main() {
  test(
    'fresh install defaults to Fake and does not expose a credential',
    () async {
      final controller = ProviderSettingsController(
        credentials: InMemorySecureCredentialStore(),
        environment: const _Environment(null),
      );

      await controller.initialize();

      expect(controller.selectedProvider, ProviderKind.fake);
      expect(controller.model, defaultOpenAiModel);
      expect(controller.credentialStatus, ProviderCredentialStatus.missing);
      expect(controller.profile.id, openAiProfileId);
      expect(controller.profile.credential.key, openAiApiKeyAlias);
    },
  );

  test(
    'stored credential takes precedence over environment and removal falls back',
    () async {
      final store = InMemorySecureCredentialStore();
      await store.write(openAiApiKeyAlias, 'synthetic-stored-credential');
      final controller = ProviderSettingsController(
        credentials: store,
        environment: const _Environment('synthetic-environment-credential'),
      );

      await controller.initialize();
      expect(controller.credentialStatus, ProviderCredentialStatus.stored);
      expect(
        await store.read(openAiApiKeyAlias),
        'synthetic-stored-credential',
      );

      expect(await controller.removeApiKey(), isTrue);
      expect(controller.credentialStatus, ProviderCredentialStatus.environment);
      expect(await store.read(openAiApiKeyAlias), isNull);
    },
  );

  test(
    'save rejects unsafe credential input without storage mutation',
    () async {
      final store = InMemorySecureCredentialStore();
      final controller = ProviderSettingsController(
        credentials: store,
        environment: const _Environment(null),
      );

      await controller.initialize();
      expect(await controller.saveApiKey('synthetic\ncredential'), isFalse);
      expect(await store.read(openAiApiKeyAlias), isNull);
      expect(controller.credentialStatus, ProviderCredentialStatus.invalid);
    },
  );

  test(
    'secure-storage failures are typed and Save and Apply is atomic',
    () async {
      final store = _SelectiveFailureStore();
      await store.write(openAiModelKey, 'old-model');
      await store.write(openAiApiKeyAlias, 'old-credential');
      final controller = ProviderSettingsController(
        credentials: store,
        environment: const _Environment(null),
      );
      await controller.initialize();
      store.failCredentialWrite = true;

      final result = await controller.saveAndApply(
        model: 'new-model',
        apiKey: 'new-credential',
      );

      expect(result.success, isFalse);
      expect(controller.model, 'old-model');
      expect(
        controller.credentialStatus,
        ProviderCredentialStatus.secureStorageError,
      );
      expect(await store.read(openAiModelKey), 'old-model');
      expect(await store.read(openAiApiKeyAlias), 'old-credential');
    },
  );

  test(
    'provider preference failure leaves selected runtime unchanged',
    () async {
      final store = _SelectiveFailureStore()..failPreferenceWrite = true;
      final controller = ProviderSettingsController(
        credentials: store,
        environment: const _Environment(null),
      );
      await controller.initialize();

      expect(
        await controller.selectProvider(ProviderKind.openAiResponses),
        isFalse,
      );
      expect(controller.selectedProvider, ProviderKind.fake);
      expect(
        controller.credentialStatus,
        ProviderCredentialStatus.secureStorageError,
      );
    },
  );
}

final class _Environment implements EnvironmentCredentialReader {
  const _Environment(this.value);

  final String? value;

  @override
  String? readApiKey() => value;
}

final class _SelectiveFailureStore implements SecureCredentialStore {
  final Map<String, String> values = <String, String>{};
  bool failCredentialWrite = false;
  bool failPreferenceWrite = false;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (key == openAiApiKeyAlias && failCredentialWrite ||
        key == preferredProviderKey && failPreferenceWrite) {
      throw StateError('synthetic secure write failure');
    }
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
