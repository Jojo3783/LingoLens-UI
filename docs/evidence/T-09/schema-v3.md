# T-09 Schema v3 Evidence

Implementation commit: 550413505530f4c2e7bb7fa7cab05c8ea8dc02c6

Command:

    flutter test test/domain/analysis_models_test.dart

Working directory: D:\GitHub\workspace\lingolens-audit-t09

Exit code: 0

Result: PASS; 15 schema and error-contract tests passed.

Verified contract:

- analysisSchemaVersion == 3
- top-level keys remain schemaVersion, providerLabel, reading, expression
- Reading fields remain exactly translation, sentenceAnalysis, grammar, vocabulary, nuance
- Expression fields are exactly natural, polite, formal, context, tone in that JSON order
- all five Expression fields are required non-empty strings
- valid strings preserve original surrounding whitespace after trimmed-value validation
- missing, unexpected, wrong-type, empty, whitespace-only, and unsupported schema versions 1, 2, and 4 map to INVALID_STRUCTURED_OUTPUT
- Reading and Expression remain distinct typed nested models

No nullable compatibility fields were added.
