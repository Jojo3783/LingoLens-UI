import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/domain/analysis_models.dart';

void main() {
  group('AnalysisResult JSON contract', () {
    test('deserializes a valid version-3 object', () {
      final result = AnalysisResult.fromJsonText(_validJson());

      expect(analysisSchemaVersion, 3);
      expect(result.schemaVersion, analysisSchemaVersion);
      expect(result.providerLabel, 'Test Provider');
      expect(result.reading.translation, 'Translation');
      expect(result.reading.sentenceAnalysis, 'Sentence analysis');
      expect(result.reading.grammar, 'Grammar');
      expect(result.reading.vocabulary, 'Vocabulary');
      expect(result.reading.nuance, 'Nuance');
      expect(result.expression.natural, 'Natural');
      expect(result.expression.polite, 'Polite');
      expect(result.expression.formal, 'Formal');
      expect(result.expression.context, 'Context');
      expect(result.expression.tone, 'Tone');
    });

    test('round trips object through deterministic JSON text', () {
      const result = AnalysisResult(
        providerLabel: 'Test Provider',
        reading: ReadingAnalysis(
          translation: 'Translation',
          sentenceAnalysis: 'Sentence analysis',
          grammar: 'Grammar',
          vocabulary: 'Vocabulary',
          nuance: 'Nuance',
        ),
        expression: ExpressionAnalysis(
          natural: 'Natural',
          polite: 'Polite',
          formal: 'Formal',
          context: 'Context',
          tone: 'Tone',
        ),
      );

      final json = result.toJsonText();
      expect(
        json,
        '{"schemaVersion":3,"providerLabel":"Test Provider",'
        '"reading":{"translation":"Translation",'
        '"sentenceAnalysis":"Sentence analysis","grammar":"Grammar",'
        '"vocabulary":"Vocabulary","nuance":"Nuance"},'
        '"expression":{"natural":"Natural","polite":"Polite",'
        '"formal":"Formal","context":"Context","tone":"Tone"}}',
      );
      final decoded = AnalysisResult.fromJsonText(json);

      expect(decoded.providerLabel, result.providerLabel);
      expect(decoded.reading, isA<ReadingAnalysis>());
      expect(decoded.expression, isA<ExpressionAnalysis>());
      expect(decoded.reading.translation, result.reading.translation);
      expect(decoded.expression.natural, result.expression.natural);
    });

    test('preserves distinct typed Reading and Expression values', () {
      final result = AnalysisResult.fromJsonText(_validJson());

      expect(result.reading, isA<ReadingAnalysis>());
      expect(result.expression, isA<ExpressionAnalysis>());
      expect(result.reading.translation, isNot(result.expression.natural));
      expect(result.reading.sentenceAnalysis, isNot(result.expression.polite));
      expect(result.reading.grammar, isNot(result.expression.polite));
      expect(result.reading.vocabulary, isNot(result.expression.polite));
      expect(result.reading.nuance, isNot(result.expression.polite));
    });

    test('preserves valid strings after trimmed-value validation', () {
      final json = _validJsonWith('reading.translation', '  Translation  ');

      final result = AnalysisResult.fromJsonText(json);

      expect(result.reading.translation, '  Translation  ');
    });

    test('rejects invalid JSON syntax as invalid structured output', () {
      _expectInvalid('{"schemaVersion":3,');
    });

    test('rejects a missing required top-level field', () {
      _expectInvalid(_validJsonWithout('providerLabel'));
    });

    test('rejects a missing required nested field', () {
      _expectInvalid(
        '{"schemaVersion":3,"providerLabel":"Provider",'
        '"reading":{"translation":"Translation"},'
        '"expression":{"natural":"Natural","polite":"Polite",'
        '"formal":"Formal","context":"Context","tone":"Tone"}}',
      );
    });

    test('rejects a missing Expression field', () {
      final value = jsonDecode(_validJson()) as Map<String, dynamic>;
      (value['expression'] as Map<String, dynamic>).remove('tone');
      _expectInvalid(jsonEncode(value));
    });

    test('rejects null and incorrectly typed fields', () {
      _expectInvalid(_validJsonWith('providerLabel', null));
      _expectInvalid(_validJsonWith('schemaVersion', '1'));
      _expectInvalid(_validJsonWith('reading', 'not an object'));
      _expectInvalid(_validJsonWith('reading.translation', 1));
      for (final field in [
        'expression.natural',
        'expression.polite',
        'expression.formal',
        'expression.context',
        'expression.tone',
      ]) {
        _expectInvalid(_validJsonWith(field, 1));
      }
    });

    test('rejects unexpected top-level and nested fields', () {
      _expectInvalid(_validJsonWith('unexpected', 'value'));
      _expectInvalid(
        '{"schemaVersion":3,"providerLabel":"Provider",'
        '"reading":{"translation":"Translation",'
        '"sentenceAnalysis":"Sentence analysis","grammar":"Grammar",'
        '"vocabulary":"Vocabulary","nuance":"Nuance",'
        '"unexpected":"value"},'
        '"expression":{"natural":"Natural","polite":"Polite",'
        '"formal":"Formal","context":"Context","tone":"Tone"}}',
      );
      _expectInvalid(_validJsonWith('expression.unexpected', 'value'));
    });

    test('rejects unsupported schema versions', () {
      _expectInvalid(_validJsonWith('schemaVersion', 1));
      _expectInvalid(_validJsonWith('schemaVersion', 2));
      _expectInvalid(_validJsonWith('schemaVersion', 4));
    });

    test('rejects empty and whitespace-only required output', () {
      for (final field in [
        'providerLabel',
        'reading.translation',
        'reading.sentenceAnalysis',
        'reading.grammar',
        'reading.vocabulary',
        'reading.nuance',
        'expression.natural',
        'expression.polite',
        'expression.formal',
        'expression.context',
        'expression.tone',
      ]) {
        _expectInvalid(_validJsonWith(field, '   '));
      }
    });

    test('does not expose parser details or raw payload', () {
      const payload = 'provider-secret-payload';

      try {
        AnalysisResult.fromJsonText('{"providerLabel":"$payload"');
        fail('expected invalid structured output');
      } on AnalysisProviderException catch (error) {
        expect(error.error.code, AnalysisErrorCode.invalidStructuredOutput);
        expect(error.toString(), isNot(contains(payload)));
        expect(error.toString(), isNot(contains('FormatException')));
      }
    });
  });

  group('Analysis error contract', () {
    const expected = <AnalysisErrorCode, (String, String)>{
      AnalysisErrorCode.emptyInput: ('EMPTY_INPUT', '請輸入要分析的文字。'),
      AnalysisErrorCode.inputTooLong: (
        'INPUT_TOO_LONG',
        '輸入文字不可超過 2000 個 Unicode code points。',
      ),
      AnalysisErrorCode.selectionUnavailable: (
        'SELECTION_UNAVAILABLE',
        '無法取得選取的文字。',
      ),
      AnalysisErrorCode.accessibilityPermissionRequired: (
        'ACCESSIBILITY_PERMISSION_REQUIRED',
        '需要輔助使用權限才能取得選取的文字。',
      ),
      AnalysisErrorCode.providerConfigurationRequired: (
        'PROVIDER_CONFIGURATION_REQUIRED',
        '尚未完成分析服務設定。',
      ),
      AnalysisErrorCode.providerAuthenticationFailed: (
        'PROVIDER_AUTHENTICATION_FAILED',
        '分析服務驗證失敗。',
      ),
      AnalysisErrorCode.providerRateLimited: (
        'PROVIDER_RATE_LIMITED',
        '分析服務目前忙碌，請稍後重試。',
      ),
      AnalysisErrorCode.providerRefused: ('PROVIDER_REFUSED', '分析服務拒絕處理這項請求。'),
      AnalysisErrorCode.providerNotFound: ('PROVIDER_NOT_FOUND', '找不到可用的分析服務。'),
      AnalysisErrorCode.providerTimeout: ('PROVIDER_TIMEOUT', '分析逾時，請重試。'),
      AnalysisErrorCode.providerFailed: ('PROVIDER_FAILED', '分析服務失敗，請重試。'),
      AnalysisErrorCode.requestCancelled: ('REQUEST_CANCELLED', '分析已取消。'),
      AnalysisErrorCode.invalidStructuredOutput: (
        'INVALID_STRUCTURED_OUTPUT',
        '分析服務回傳了無效格式。',
      ),
      AnalysisErrorCode.persistenceFailed: ('PERSISTENCE_FAILED', '無法儲存分析結果。'),
      AnalysisErrorCode.unknownError: ('UNKNOWN_ERROR', '分析失敗，請稍後重試。'),
    };

    test('every required error has an explicit wire value and message', () {
      for (final entry in expected.entries) {
        final error = AnalysisError(entry.key);
        expect(error.wireValue, entry.value.$1);
        expect(error.message, entry.value.$2);
      }
    });

    test('all required wire values are unique', () {
      final values = AnalysisErrorCode.values
          .map((code) => AnalysisError(code).wireValue)
          .toList();

      expect(values.toSet(), hasLength(values.length));
      expect(values, hasLength(expected.length));
    });
  });
}

void _expectInvalid(String json) {
  expect(
    () => AnalysisResult.fromJsonText(json),
    throwsA(
      isA<AnalysisProviderException>().having(
        (error) => error.error.code,
        'error code',
        AnalysisErrorCode.invalidStructuredOutput,
      ),
    ),
  );
}

String _validJson() => jsonEncode(<String, Object?>{
  'schemaVersion': analysisSchemaVersion,
  'providerLabel': 'Test Provider',
  'reading': <String, String>{
    'translation': 'Translation',
    'sentenceAnalysis': 'Sentence analysis',
    'grammar': 'Grammar',
    'vocabulary': 'Vocabulary',
    'nuance': 'Nuance',
  },
  'expression': <String, String>{
    'natural': 'Natural',
    'polite': 'Polite',
    'formal': 'Formal',
    'context': 'Context',
    'tone': 'Tone',
  },
});

String _validJsonWithout(String field) {
  final value = jsonDecode(_validJson()) as Map<String, dynamic>;
  value.remove(field);
  return jsonEncode(value);
}

String _validJsonWith(String path, Object? replacement) {
  final value = jsonDecode(_validJson()) as Map<String, dynamic>;
  final pathParts = path.split('.');
  if (pathParts.length == 1) {
    value[path] = replacement;
  } else {
    final parent = value[pathParts.first] as Map<String, dynamic>;
    parent[pathParts.last] = replacement;
  }
  return jsonEncode(value);
}
