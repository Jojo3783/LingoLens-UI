import 'dart:convert';

const int analysisSchemaVersion = 3;
const int maxAnalysisInputCharacters = 2000;

enum AnalysisMode { reading, expression }

enum AnalysisErrorCode {
  emptyInput,
  inputTooLong,
  selectionUnavailable,
  accessibilityPermissionRequired,
  providerConfigurationRequired,
  providerAuthenticationFailed,
  providerRateLimited,
  providerRefused,
  providerNotFound,
  providerTimeout,
  providerFailed,
  requestCancelled,
  invalidStructuredOutput,
  persistenceFailed,
  unknownError,
}

extension AnalysisErrorCodeContract on AnalysisErrorCode {
  String get wireValue => switch (this) {
    AnalysisErrorCode.emptyInput => 'EMPTY_INPUT',
    AnalysisErrorCode.inputTooLong => 'INPUT_TOO_LONG',
    AnalysisErrorCode.selectionUnavailable => 'SELECTION_UNAVAILABLE',
    AnalysisErrorCode.accessibilityPermissionRequired =>
      'ACCESSIBILITY_PERMISSION_REQUIRED',
    AnalysisErrorCode.providerConfigurationRequired =>
      'PROVIDER_CONFIGURATION_REQUIRED',
    AnalysisErrorCode.providerAuthenticationFailed =>
      'PROVIDER_AUTHENTICATION_FAILED',
    AnalysisErrorCode.providerRateLimited => 'PROVIDER_RATE_LIMITED',
    AnalysisErrorCode.providerRefused => 'PROVIDER_REFUSED',
    AnalysisErrorCode.providerNotFound => 'PROVIDER_NOT_FOUND',
    AnalysisErrorCode.providerTimeout => 'PROVIDER_TIMEOUT',
    AnalysisErrorCode.providerFailed => 'PROVIDER_FAILED',
    AnalysisErrorCode.requestCancelled => 'REQUEST_CANCELLED',
    AnalysisErrorCode.invalidStructuredOutput => 'INVALID_STRUCTURED_OUTPUT',
    AnalysisErrorCode.persistenceFailed => 'PERSISTENCE_FAILED',
    AnalysisErrorCode.unknownError => 'UNKNOWN_ERROR',
  };

  String get userMessage => switch (this) {
    AnalysisErrorCode.emptyInput => '請輸入要分析的文字。',
    AnalysisErrorCode.inputTooLong => '輸入文字不可超過 2000 個 Unicode code points。',
    AnalysisErrorCode.selectionUnavailable => '無法取得選取的文字。',
    AnalysisErrorCode.accessibilityPermissionRequired => '需要輔助使用權限才能取得選取的文字。',
    AnalysisErrorCode.providerConfigurationRequired => '尚未完成分析服務設定。',
    AnalysisErrorCode.providerAuthenticationFailed => '分析服務驗證失敗。',
    AnalysisErrorCode.providerRateLimited => '分析服務目前忙碌，請稍後重試。',
    AnalysisErrorCode.providerRefused => '分析服務拒絕處理這項請求。',
    AnalysisErrorCode.providerNotFound => '找不到可用的分析服務。',
    AnalysisErrorCode.providerTimeout => '分析逾時，請重試。',
    AnalysisErrorCode.providerFailed => '分析服務失敗，請重試。',
    AnalysisErrorCode.requestCancelled => '分析已取消。',
    AnalysisErrorCode.invalidStructuredOutput => '分析服務回傳了無效格式。',
    AnalysisErrorCode.persistenceFailed => '無法儲存分析結果。',
    AnalysisErrorCode.unknownError => '分析失敗，請稍後重試。',
  };
}

final class AnalysisError {
  const AnalysisError(this.code);

  const AnalysisError.emptyInput() : this(AnalysisErrorCode.emptyInput);

  const AnalysisError.inputTooLong() : this(AnalysisErrorCode.inputTooLong);

  const AnalysisError.providerConfigurationRequired()
    : this(AnalysisErrorCode.providerConfigurationRequired);

  const AnalysisError.providerAuthenticationFailed()
    : this(AnalysisErrorCode.providerAuthenticationFailed);

  const AnalysisError.providerRateLimited()
    : this(AnalysisErrorCode.providerRateLimited);

  const AnalysisError.providerRefused()
    : this(AnalysisErrorCode.providerRefused);

  const AnalysisError.requestCancelled()
    : this(AnalysisErrorCode.requestCancelled);

  const AnalysisError.providerFailed() : this(AnalysisErrorCode.providerFailed);

  const AnalysisError.unknownError() : this(AnalysisErrorCode.unknownError);

  final AnalysisErrorCode code;

  String get wireValue => code.wireValue;

  String get message => code.userMessage;
}

sealed class AnalysisApplicationException implements Exception {
  const AnalysisApplicationException(this.error);

  final AnalysisError error;

  @override
  String toString() => error.wireValue;
}

final class AnalysisInputException extends AnalysisApplicationException {
  const AnalysisInputException(super.error);

  const AnalysisInputException.empty()
    : super(const AnalysisError.emptyInput());

  const AnalysisInputException.tooLong()
    : super(const AnalysisError.inputTooLong());
}

final class AnalysisProviderException extends AnalysisApplicationException {
  const AnalysisProviderException(super.error);

  const AnalysisProviderException.timeout()
    : super(const AnalysisError(AnalysisErrorCode.providerTimeout));

  const AnalysisProviderException.notFound()
    : super(const AnalysisError(AnalysisErrorCode.providerNotFound));

  const AnalysisProviderException.providerFailed()
    : super(const AnalysisError.providerFailed());

  const AnalysisProviderException.invalidStructuredOutput()
    : super(const AnalysisError(AnalysisErrorCode.invalidStructuredOutput));

  const AnalysisProviderException.requestCancelled()
    : super(const AnalysisError.requestCancelled());

  const AnalysisProviderException.configurationRequired()
    : super(const AnalysisError.providerConfigurationRequired());

  const AnalysisProviderException.authenticationFailed()
    : super(const AnalysisError.providerAuthenticationFailed());

  const AnalysisProviderException.rateLimited()
    : super(const AnalysisError.providerRateLimited());

  const AnalysisProviderException.refused()
    : super(const AnalysisError.providerRefused());
}

final class AnalysisPersistenceException extends AnalysisApplicationException {
  const AnalysisPersistenceException()
    : super(const AnalysisError(AnalysisErrorCode.persistenceFailed));
}

final class AnalysisInput {
  const AnalysisInput._(this.value);

  factory AnalysisInput.fromRaw(String input) {
    final normalizedInput = input.trim();
    if (normalizedInput.isEmpty) {
      throw const AnalysisInputException.empty();
    }
    if (normalizedInput.runes.length > maxAnalysisInputCharacters) {
      throw const AnalysisInputException.tooLong();
    }
    return AnalysisInput._(normalizedInput);
  }

  final String value;
}

final class RequestId {
  RequestId._(this.value);

  static int _nextValue = 0;

  final int value;

  factory RequestId.create() => RequestId._(++_nextValue);

  @override
  bool operator ==(Object other) => other is RequestId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'request-$value';
}

final class CancellationToken {
  bool _isCancelled = false;
  final List<void Function()> _listeners = <void Function()>[];

  bool get isCancelled => _isCancelled;

  void addListener(void Function() listener) {
    if (_isCancelled) {
      listener();
      return;
    }
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void cancel() {
    if (_isCancelled) {
      return;
    }
    _isCancelled = true;
    final listeners = List<void Function()>.of(_listeners);
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const AnalysisProviderException.requestCancelled();
    }
  }
}

final class RequestContext {
  const RequestContext({required this.requestId, required this.cancellation});

  final RequestId requestId;
  final CancellationToken cancellation;

  void cancel() => cancellation.cancel();
}

final class AnalysisRequest {
  const AnalysisRequest({
    required this.requestId,
    required this.input,
    required this.mode,
  });

  final RequestId requestId;
  final String input;
  final AnalysisMode mode;
}

final class AnalysisPreview {
  const AnalysisPreview({
    required this.mode,
    required this.providerLabel,
    required this.primaryText,
  });

  final AnalysisMode mode;
  final String providerLabel;
  final String primaryText;
}

final class ReadingAnalysis {
  const ReadingAnalysis({
    required this.translation,
    required this.sentenceAnalysis,
    required this.grammar,
    required this.vocabulary,
    required this.nuance,
  });

  final String translation;
  final String sentenceAnalysis;
  final String grammar;
  final String vocabulary;
  final String nuance;

  Map<String, Object?> toJson() => <String, Object?>{
    'translation': translation,
    'sentenceAnalysis': sentenceAnalysis,
    'grammar': grammar,
    'vocabulary': vocabulary,
    'nuance': nuance,
  };

  factory ReadingAnalysis.fromJson(Object? json) {
    try {
      final object = _requireObject(json, const {
        'translation',
        'sentenceAnalysis',
        'grammar',
        'vocabulary',
        'nuance',
      });
      return ReadingAnalysis(
        translation: _requireNonEmptyString(object, 'translation'),
        sentenceAnalysis: _requireNonEmptyString(object, 'sentenceAnalysis'),
        grammar: _requireNonEmptyString(object, 'grammar'),
        vocabulary: _requireNonEmptyString(object, 'vocabulary'),
        nuance: _requireNonEmptyString(object, 'nuance'),
      );
    } catch (_) {
      throw const AnalysisProviderException.invalidStructuredOutput();
    }
  }
}

final class ExpressionAnalysis {
  const ExpressionAnalysis({
    required this.natural,
    required this.polite,
    required this.formal,
    required this.context,
    required this.tone,
  });

  final String natural;
  final String polite;
  final String formal;
  final String context;
  final String tone;

  Map<String, Object?> toJson() => <String, Object?>{
    'natural': natural,
    'polite': polite,
    'formal': formal,
    'context': context,
    'tone': tone,
  };

  factory ExpressionAnalysis.fromJson(Object? json) {
    try {
      final object = _requireObject(json, const {
        'natural',
        'polite',
        'formal',
        'context',
        'tone',
      });
      return ExpressionAnalysis(
        natural: _requireNonEmptyString(object, 'natural'),
        polite: _requireNonEmptyString(object, 'polite'),
        formal: _requireNonEmptyString(object, 'formal'),
        context: _requireNonEmptyString(object, 'context'),
        tone: _requireNonEmptyString(object, 'tone'),
      );
    } catch (_) {
      throw const AnalysisProviderException.invalidStructuredOutput();
    }
  }
}

final class AnalysisResult {
  const AnalysisResult({
    required this.reading,
    required this.expression,
    required this.providerLabel,
  });

  final ReadingAnalysis reading;
  final ExpressionAnalysis expression;
  final String providerLabel;

  int get schemaVersion => analysisSchemaVersion;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'providerLabel': providerLabel,
    'reading': reading.toJson(),
    'expression': expression.toJson(),
  };

  String toJsonText() => jsonEncode(toJson());

  factory AnalysisResult.fromJson(Object? json) {
    try {
      final object = _requireObject(json, const {
        'schemaVersion',
        'providerLabel',
        'reading',
        'expression',
      });
      final schemaVersion = object['schemaVersion'];
      if (schemaVersion is! int || schemaVersion != analysisSchemaVersion) {
        throw const _InvalidStructuredOutput();
      }
      return AnalysisResult(
        providerLabel: _requireNonEmptyString(object, 'providerLabel'),
        reading: ReadingAnalysis.fromJson(object['reading']),
        expression: ExpressionAnalysis.fromJson(object['expression']),
      );
    } catch (_) {
      throw const AnalysisProviderException.invalidStructuredOutput();
    }
  }

  factory AnalysisResult.fromJsonText(String text) {
    try {
      return AnalysisResult.fromJson(jsonDecode(text));
    } catch (_) {
      throw const AnalysisProviderException.invalidStructuredOutput();
    }
  }
}

Map<String, Object?> _requireObject(Object? value, Set<String> keys) {
  if (value is! Map) {
    throw const _InvalidStructuredOutput();
  }

  final object = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const _InvalidStructuredOutput();
    }
    object[entry.key as String] = entry.value;
  }
  if (object.length != keys.length || !object.keys.every(keys.contains)) {
    throw const _InvalidStructuredOutput();
  }
  return object;
}

String _requireNonEmptyString(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! String || value.trim().isEmpty) {
    throw const _InvalidStructuredOutput();
  }
  return value;
}

final class _InvalidStructuredOutput implements Exception {
  const _InvalidStructuredOutput();
}

abstract interface class AnalysisProvider {
  Future<AnalysisResult> analyzeFull(
    AnalysisRequest request,
    RequestContext context,
  );
}

abstract interface class ProgressiveAnalysisProviderCapability {
  Future<AnalysisPreview> analyzePreview(
    AnalysisRequest request,
    RequestContext context,
  );
}
