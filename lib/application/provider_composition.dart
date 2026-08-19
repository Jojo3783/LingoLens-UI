import 'analysis_execution_strategy.dart';
import 'analysis_telemetry.dart';
import '../domain/analysis_models.dart';
import '../domain/provider_contracts.dart';
import '../infrastructure/fake_analysis_provider.dart';
import '../infrastructure/openai/analysis_http_transport.dart';
import '../infrastructure/openai/http_client_analysis_transport.dart';
import '../infrastructure/openai/openai_responses_analysis_provider.dart';
import '../infrastructure/openai/provider_credentials.dart';

sealed class AnalysisProviderSelection {
  const AnalysisProviderSelection();
}

final class FakeProviderSelection extends AnalysisProviderSelection {
  const FakeProviderSelection();
}

final class OpenAiResponsesProviderSelection extends AnalysisProviderSelection {
  OpenAiResponsesProviderSelection({
    required this.configuration,
    required this.credentials,
    this.transport,
    this.telemetry,
    this.clock,
  });

  final OpenAiProviderConfiguration configuration;
  final ProviderCredentialSource credentials;
  final AnalysisHttpTransport? transport;
  final AnalysisTelemetrySink? telemetry;
  final MonotonicClock? clock;
}

final class AnalysisProviderComposition {
  const AnalysisProviderComposition({
    required this.provider,
    required this.strategy,
    required this.disclosure,
    this.fakeProvider,
  });

  final AnalysisProvider provider;
  final AnalysisExecutionStrategy strategy;
  final ProviderDisclosure? disclosure;
  final FakeAnalysisProvider? fakeProvider;
}

AnalysisProviderComposition createAnalysisProviderComposition({
  AnalysisProviderSelection selection = const FakeProviderSelection(),
}) {
  return switch (selection) {
    FakeProviderSelection() => _createFakeComposition(),
    OpenAiResponsesProviderSelection() => _createOpenAiComposition(selection),
  };
}

AnalysisProviderComposition _createFakeComposition() {
  final provider = FakeAnalysisProvider();
  return AnalysisProviderComposition(
    provider: provider,
    strategy: const TwoStageStrategy(),
    fakeProvider: provider,
    disclosure: const ProviderDisclosure(
      providerName: 'Deterministic Fake Provider',
      message: '目前使用本機 deterministic Fake Provider，不會傳送網路請求。',
    ),
  );
}

AnalysisProviderComposition _createOpenAiComposition(
  OpenAiResponsesProviderSelection selection,
) {
  final provider = OpenAiResponsesAnalysisProvider(
    configuration: selection.configuration,
    credentials: selection.credentials,
    transport: selection.transport ?? HttpClientAnalysisHttpTransport(),
    telemetry: selection.telemetry,
    clock: selection.clock,
  );
  return AnalysisProviderComposition(
    provider: provider,
    strategy: const FullOnlyStrategy(),
    disclosure: const ProviderDisclosure(
      providerName: 'OpenAI Responses API',
      message:
          '目前使用 OpenAI Responses API；輸入內容會傳送至已設定的遠端 Provider。'
          '本次請求設定 store=false，但不代表絕對 Zero Data Retention。',
    ),
  );
}

ProviderCredentialSource defaultOpenAiCredentialSource() =>
    const EnvironmentProviderCredentialSource();

AnalysisProviderSelection explicitOpenAiSelection({
  required String model,
  ProviderCredentialSource? credentials,
  AnalysisHttpTransport? transport,
  AnalysisTelemetrySink? telemetry,
  MonotonicClock? clock,
}) => OpenAiResponsesProviderSelection(
  configuration: OpenAiProviderConfiguration(model: model),
  credentials: credentials ?? defaultOpenAiCredentialSource(),
  transport: transport,
  telemetry: telemetry,
  clock: clock,
);
