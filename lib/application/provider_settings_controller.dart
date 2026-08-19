import 'package:flutter/foundation.dart';

import '../domain/provider_contracts.dart';
import '../infrastructure/openai/provider_credentials.dart';
import 'provider_composition.dart';

const String openAiProfileId = 'openai-default';
const String openAiApiKeyAlias = 'lingolens.openai.api_key.v1';
const String preferredProviderKey = 'lingolens.provider.preferred.v1';
const String openAiModelKey = 'lingolens.provider.openai.model.v1';
const String defaultOpenAiModel = 'gpt-5-mini';

enum ProviderCredentialStatus {
  loading,
  missing,
  environment,
  stored,
  invalid,
  secureStorageError,
}

final class ProviderSaveResult {
  const ProviderSaveResult._({required this.success, this.errorMessage});

  const ProviderSaveResult.success() : this._(success: true);

  const ProviderSaveResult.failure(String message)
    : this._(success: false, errorMessage: message);

  final bool success;
  final String? errorMessage;
}

final class ProviderSettingsController extends ChangeNotifier
    implements ProviderProfileStore {
  ProviderSettingsController({
    required SecureCredentialStore credentials,
    EnvironmentCredentialReader? environment,
    ProviderKind initialProvider = ProviderKind.fake,
  }) : _credentials = credentials,
       _environment =
           environment ?? const EnvironmentProviderCredentialSource(),
       _selectedProvider = initialProvider;

  final SecureCredentialStore _credentials;
  final EnvironmentCredentialReader _environment;
  ProviderCredentialSource? _resolvedCredential;
  ProviderKind _selectedProvider = ProviderKind.fake;
  ProviderCredentialStatus _credentialStatus = ProviderCredentialStatus.loading;
  String _model = defaultOpenAiModel;
  String? _errorMessage;

  ProviderKind get selectedProvider => _selectedProvider;
  ProviderCredentialStatus get credentialStatus => _credentialStatus;
  String get model => _model;
  String? get errorMessage => _errorMessage;
  bool get hasCredential =>
      _credentialStatus == ProviderCredentialStatus.stored ||
      _credentialStatus == ProviderCredentialStatus.environment;

  ProviderProfile get profile => ProviderProfile(
    id: openAiProfileId,
    kind: ProviderKind.openAiResponses,
    model: _model,
    credential: const CredentialReference(
      kind: CredentialReferenceKind.secureStorage,
      key: openAiApiKeyAlias,
    ),
  );

  Future<void> initialize() async {
    _credentialStatus = ProviderCredentialStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final storedModel = await _credentials.read(openAiModelKey);
      if (storedModel != null && storedModel.trim().isNotEmpty) {
        _model = storedModel.trim();
      }
      final preferred = await _credentials.read(preferredProviderKey);
      if (preferred == ProviderKind.openAiResponses.wireValue) {
        _selectedProvider = ProviderKind.openAiResponses;
      }
      final stored = await _credentials.read(openAiApiKeyAlias);
      if (_isValidCredential(stored)) {
        _resolvedCredential = ResolvedProviderCredentialSource(stored);
        _credentialStatus = ProviderCredentialStatus.stored;
      } else {
        final environment = _environment.readApiKey();
        if (_isValidCredential(environment)) {
          _resolvedCredential = ResolvedProviderCredentialSource(environment);
          _credentialStatus = ProviderCredentialStatus.environment;
        } else {
          _credentialStatus = ProviderCredentialStatus.missing;
        }
      }
    } catch (_) {
      _resolvedCredential = null;
      _credentialStatus = ProviderCredentialStatus.secureStorageError;
      _errorMessage = '安全設定讀取失敗，已停止套用 OpenAI credential。';
    }
    notifyListeners();
  }

  Future<bool> selectProvider(ProviderKind provider) async {
    if (provider == _selectedProvider) {
      return true;
    }
    try {
      await _credentials.write(preferredProviderKey, provider.wireValue);
      _selectedProvider = provider;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      _setStorageError('安全設定儲存失敗，Provider 偏好未變更。');
      return false;
    }
  }

  Future<ProviderSaveResult> saveAndApply({
    required String model,
    required String apiKey,
  }) async {
    final normalizedModel = model.trim();
    final normalizedKey = apiKey.trim();
    if (!_isValidModel(normalizedModel)) {
      const message = 'Model 不可為空白、含換行或超過 80 個字元。';
      _errorMessage = message;
      notifyListeners();
      return const ProviderSaveResult.failure(message);
    }
    if (normalizedKey.isNotEmpty && !_isValidCredential(normalizedKey)) {
      _credentialStatus = ProviderCredentialStatus.invalid;
      const message = 'API key 不可含換行或控制字元，且不可超過 256 個字元。';
      _errorMessage = message;
      notifyListeners();
      return const ProviderSaveResult.failure(message);
    }

    String? previousModel;
    String? previousKey;
    var modelWritten = false;
    var keyWritten = false;
    try {
      previousModel = await _credentials.read(openAiModelKey);
      previousKey = await _credentials.read(openAiApiKeyAlias);
      await _credentials.write(openAiModelKey, normalizedModel);
      modelWritten = true;
      if (normalizedKey.isNotEmpty) {
        await _credentials.write(openAiApiKeyAlias, normalizedKey);
        keyWritten = true;
      }
    } catch (_) {
      await _rollbackSave(
        previousModel: previousModel,
        previousKey: previousKey,
        modelWritten: modelWritten,
        keyWritten: keyWritten,
      );
      const message = '安全設定儲存失敗，Model 與 credential 未完整套用。';
      _setStorageError(message);
      return const ProviderSaveResult.failure(message);
    }

    _model = normalizedModel;
    if (normalizedKey.isNotEmpty) {
      _resolvedCredential = ResolvedProviderCredentialSource(normalizedKey);
      _credentialStatus = ProviderCredentialStatus.stored;
    }
    _errorMessage = null;
    notifyListeners();
    return const ProviderSaveResult.success();
  }

  Future<bool> saveApiKey(String value) async =>
      (await saveAndApply(model: _model, apiKey: value)).success;

  Future<bool> removeApiKey() async {
    try {
      await _credentials.delete(openAiApiKeyAlias);
      final environment = _environment.readApiKey();
      _resolvedCredential = _isValidCredential(environment)
          ? ResolvedProviderCredentialSource(environment)
          : null;
      _credentialStatus = _isValidCredential(environment)
          ? ProviderCredentialStatus.environment
          : ProviderCredentialStatus.missing;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      _setStorageError('安全設定刪除失敗，既有 credential 未變更。');
      return false;
    }
  }

  Future<bool> saveModel(String value) async =>
      (await saveAndApply(model: value, apiKey: '')).success;

  @override
  Future<ProviderProfile> read() async => profile;

  @override
  Future<void> write(ProviderProfile profile) async {
    if (profile.id != openAiProfileId ||
        profile.kind != ProviderKind.openAiResponses) {
      return;
    }
    await saveModel(profile.model);
  }

  void _setStorageError(String message) {
    _credentialStatus = ProviderCredentialStatus.secureStorageError;
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> _rollbackSave({
    required String? previousModel,
    required String? previousKey,
    required bool modelWritten,
    required bool keyWritten,
  }) async {
    if (modelWritten) {
      try {
        if (previousModel == null) {
          await _credentials.delete(openAiModelKey);
        } else {
          await _credentials.write(openAiModelKey, previousModel);
        }
      } catch (_) {
        // The typed storage error remains the truthful public result.
      }
    }
    if (keyWritten) {
      try {
        if (previousKey == null) {
          await _credentials.delete(openAiApiKeyAlias);
        } else {
          await _credentials.write(openAiApiKeyAlias, previousKey);
        }
      } catch (_) {
        // The typed storage error remains the truthful public result.
      }
    }
  }

  bool _isValidModel(String value) =>
      value.isNotEmpty &&
      value.length <= 80 &&
      !value.contains(RegExp(r'[\r\n]'));

  bool _isValidCredential(String? value) {
    if (value == null || value.isEmpty || value.length > 256) {
      return false;
    }
    return !value.contains(RegExp(r'[\u0000-\u001F\u007F\r\n]'));
  }
}

final class ProviderRuntimeCoordinator {
  const ProviderRuntimeCoordinator(this._settings);

  final ProviderSettingsController _settings;

  AnalysisProviderComposition compose() {
    if (_settings.selectedProvider == ProviderKind.fake) {
      return createAnalysisProviderComposition();
    }
    return createAnalysisProviderComposition(
      selection: OpenAiResponsesProviderSelection(
        configuration: OpenAiProviderConfiguration(model: _settings.model),
        credentials:
            _settings._resolvedCredential ??
            const ResolvedProviderCredentialSource(null),
      ),
    );
  }
}
