import 'dart:convert';

import '../../domain/analysis_models.dart';
import '../../domain/provider_contracts.dart';
import 'analysis_http_transport.dart';

final class OpenAiRequestBuilder {
  const OpenAiRequestBuilder();

  AnalysisHttpRequest build({
    required OpenAiProviderConfiguration configuration,
    required String apiKey,
    required AnalysisRequest request,
    required RequestContext context,
  }) {
    final payload = <String, Object?>{
      'model': configuration.model,
      'store': false,
      'input': <Object?>[
        <String, Object?>{
          'role': 'system',
          'content': <Object?>[
            <String, Object?>{'type': 'input_text', 'text': _systemInstruction},
          ],
        },
        <String, Object?>{
          'role': 'user',
          'content': <Object?>[
            <String, Object?>{
              'type': 'input_text',
              'text': 'Requested mode: ${_modeName(request.mode)}',
            },
            <String, Object?>{'type': 'input_text', 'text': request.input},
          ],
        },
      ],
      'text': <String, Object?>{
        'format': <String, Object?>{
          'type': 'json_schema',
          'name': 'lingolens_analysis',
          'strict': true,
          'schema': _schema,
        },
      },
    };
    return AnalysisHttpRequest(
      endpoint: OpenAiProviderConfiguration.endpoint,
      headers: <String, String>{
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
      timeout: configuration.timeout,
      context: context,
    );
  }

  static const String _systemInstruction =
      'Return a complete LingoLens language analysis as JSON. '
      'Preserve the user text meaning and provide concise, useful strings. '
      'Return only the fields defined by the supplied schema.';

  static String _modeName(AnalysisMode mode) => switch (mode) {
    AnalysisMode.reading => 'reading',
    AnalysisMode.expression => 'expression',
  };

  static const Map<String, Object?> _schema = <String, Object?>{
    'type': 'object',
    'properties': <String, Object?>{
      'reading': <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'translation': <String, Object?>{'type': 'string'},
          'sentenceAnalysis': <String, Object?>{'type': 'string'},
          'grammar': <String, Object?>{'type': 'string'},
          'vocabulary': <String, Object?>{'type': 'string'},
          'nuance': <String, Object?>{'type': 'string'},
        },
        'required': <String>[
          'translation',
          'sentenceAnalysis',
          'grammar',
          'vocabulary',
          'nuance',
        ],
        'additionalProperties': false,
      },
      'expression': <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'natural': <String, Object?>{'type': 'string'},
          'polite': <String, Object?>{'type': 'string'},
          'formal': <String, Object?>{'type': 'string'},
          'context': <String, Object?>{'type': 'string'},
          'tone': <String, Object?>{'type': 'string'},
        },
        'required': <String>['natural', 'polite', 'formal', 'context', 'tone'],
        'additionalProperties': false,
      },
    },
    'required': <String>['reading', 'expression'],
    'additionalProperties': false,
  };
}
