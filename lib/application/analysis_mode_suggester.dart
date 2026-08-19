import '../domain/analysis_models.dart';

abstract interface class AnalysisModeSuggester {
  AnalysisMode suggest(String normalizedInput);
}

final class DeterministicAnalysisModeSuggester
    implements AnalysisModeSuggester {
  const DeterministicAnalysisModeSuggester();

  @override
  AnalysisMode suggest(String normalizedInput) {
    final hasCjk = normalizedInput.runes.any(
      (rune) =>
          (rune >= 0x3400 && rune <= 0x4DBF) ||
          (rune >= 0x4E00 && rune <= 0x9FFF) ||
          (rune >= 0xF900 && rune <= 0xFAFF),
    );
    return hasCjk ? AnalysisMode.expression : AnalysisMode.reading;
  }
}

final class AnalysisModeSelectionState {
  const AnalysisModeSelectionState({
    required this.suggestedMode,
    required this.effectiveMode,
    required this.hasManualOverride,
  });

  final AnalysisMode suggestedMode;
  final AnalysisMode effectiveMode;
  final bool hasManualOverride;
}
