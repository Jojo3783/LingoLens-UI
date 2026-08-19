import 'dart:convert';

import '../../domain/analysis_models.dart';

final class OpenAiResponseDecoder {
  const OpenAiResponseDecoder();

  AnalysisResult decode(String responseBody) {
    final root = _decodeObject(responseBody);
    if (root['status'] == 'incomplete' || root['incomplete_details'] != null) {
      throw const AnalysisProviderException.invalidStructuredOutput();
    }
    if (_containsRefusal(root)) {
      throw const AnalysisProviderException.refused();
    }
    final text = _findOutputText(root);
    if (text == null || text.trim().isEmpty) {
      throw const AnalysisProviderException.invalidStructuredOutput();
    }
    final decoded = _decodeJsonObject(text);
    if (decoded.length != 2 ||
        !decoded.keys.every(const {'reading', 'expression'}.contains)) {
      throw const AnalysisProviderException.invalidStructuredOutput();
    }
    return AnalysisResult.fromJson(<String, Object?>{
      'schemaVersion': analysisSchemaVersion,
      'providerLabel': 'OpenAI Responses API',
      'reading': decoded['reading'],
      'expression': decoded['expression'],
    });
  }

  Map<String, Object?> _decodeObject(String text) {
    try {
      final value = jsonDecode(text);
      if (value is! Map) {
        throw const AnalysisProviderException.invalidStructuredOutput();
      }
      return _stringKeyedMap(value);
    } catch (exception) {
      if (exception is AnalysisProviderException) {
        rethrow;
      }
      throw const AnalysisProviderException.invalidStructuredOutput();
    }
  }

  Map<String, Object?> _decodeJsonObject(String text) {
    try {
      final value = jsonDecode(text);
      if (value is! Map) {
        throw const AnalysisProviderException.invalidStructuredOutput();
      }
      return _stringKeyedMap(value);
    } catch (exception) {
      if (exception is AnalysisProviderException) {
        rethrow;
      }
      throw const AnalysisProviderException.invalidStructuredOutput();
    }
  }

  String? _findOutputText(Map<String, Object?> root) {
    final direct = root['output_text'];
    if (direct is String) {
      return direct;
    }
    final output = root['output'];
    if (output is! List) {
      return null;
    }
    for (final item in output) {
      if (item is! Map || item['type'] != 'message') {
        continue;
      }
      final content = item['content'];
      if (content is! List) {
        continue;
      }
      for (final part in content) {
        if (part is Map &&
            part['type'] == 'output_text' &&
            part['text'] is String) {
          return part['text'] as String;
        }
      }
    }
    return null;
  }

  bool _containsRefusal(Map<String, Object?> root) {
    final output = root['output'];
    if (output is! List) {
      return root['refusal'] is String;
    }
    for (final item in output) {
      if (item is! Map) {
        continue;
      }
      final content = item['content'];
      if (content is! List) {
        continue;
      }
      if (content.any((part) => part is Map && part['type'] == 'refusal')) {
        return true;
      }
    }
    return root['refusal'] is String;
  }

  Map<String, Object?> _stringKeyedMap(Map value) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const AnalysisProviderException.invalidStructuredOutput();
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }
}
