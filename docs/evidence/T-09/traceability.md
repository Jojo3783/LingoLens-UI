# T-09 Traceability

| Requirement | Implementation | Verification |
|---|---|---|
| exact schema v3 | lib/domain/analysis_models.dart | test/domain/analysis_models_test.dart |
| five Expression fields | ExpressionAnalysis and toJson / fromJson | schema focused tests |
| deterministic Fake Provider | lib/infrastructure/fake_analysis_provider.dart | test/infrastructure/fake_analysis_provider_test.dart |
| Expression hierarchy | lib/presentation/analysis_result_panel.dart | test/widget_reading_mode_test.dart |
| Natural Copy / Listen / Feedback | existing Application action ownership | widget and action tests |
| mode-aware stable keys and semantics | existing reusable action/result components | widget accessibility assertions |
| manual override and retry mode | existing Application controller | test/application/mode_selection_test.dart |
| stale-result and action guards | existing Application guards | controller and action tests |
| long / narrow layout | reusable result sections | Expression widget tests |
| visual evidence | docs/evidence/T-09/expression-mode.png | golden generation command |
| governance and delivery | Root docs and this evidence set | final metadata verification |

No T-10 or later implementation is included.
