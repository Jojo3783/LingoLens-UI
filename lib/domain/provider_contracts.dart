import 'analysis_models.dart';

enum ProviderKind { fake, openAiResponses }

extension ProviderKindContract on ProviderKind {
  String get wireValue => switch (this) {
    ProviderKind.fake => 'fake',
    ProviderKind.openAiResponses => 'openai_responses',
  };

  String get displayName => switch (this) {
    ProviderKind.fake => 'Deterministic Fake Provider',
    ProviderKind.openAiResponses => 'OpenAI Responses API',
  };
}

final class OpenAiProviderConfiguration {
  const OpenAiProviderConfiguration({
    required this.model,
    this.timeout = const Duration(seconds: 60),
  });

  static final Uri endpoint = Uri.parse('https://api.openai.com/v1/responses');
  static const Duration minimumTimeout = Duration(seconds: 1);
  static const Duration maximumTimeout = Duration(seconds: 120);

  final String model;
  final Duration timeout;

  void validate() {
    if (model.trim().isEmpty ||
        timeout < minimumTimeout ||
        timeout > maximumTimeout ||
        endpoint.scheme != 'https' ||
        endpoint.host != 'api.openai.com') {
      throw const AnalysisProviderException.configurationRequired();
    }
  }
}

abstract interface class ProviderCredentialSource {
  String? readApiKey();
}

enum CredentialReferenceKind { secureStorage, environment }

final class CredentialReference {
  const CredentialReference({required this.kind, required this.key});

  final CredentialReferenceKind kind;
  final String key;
}

final class ProviderProfile {
  const ProviderProfile({
    required this.id,
    required this.kind,
    required this.model,
    required this.credential,
  });

  final String id;
  final ProviderKind kind;
  final String model;
  final CredentialReference credential;
}

abstract interface class ProviderProfileStore {
  Future<ProviderProfile> read();

  Future<void> write(ProviderProfile profile);
}

abstract interface class SecureCredentialStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

abstract interface class EnvironmentCredentialReader {
  String? readApiKey();
}

final class ProviderDisclosure {
  const ProviderDisclosure({required this.providerName, required this.message});

  final String providerName;
  final String message;
}
