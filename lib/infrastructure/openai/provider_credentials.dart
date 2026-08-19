import 'dart:io';

import '../../domain/provider_contracts.dart';

final class EnvironmentProviderCredentialSource
    implements ProviderCredentialSource, EnvironmentCredentialReader {
  const EnvironmentProviderCredentialSource();

  // 僅供明確 opt-in 的 development wiring 使用，不將 Credential 寫入設定或檔案。
  @override
  String? readApiKey() {
    final value = Platform.environment['OPENAI_API_KEY'];
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value;
  }
}

final class ResolvedProviderCredentialSource
    implements ProviderCredentialSource {
  const ResolvedProviderCredentialSource(String? value) : _value = value;

  final String? _value;

  @override
  String? readApiKey() => _value;
}
