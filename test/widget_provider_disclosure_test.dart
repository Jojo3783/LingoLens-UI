import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingolens/application/analysis_controller.dart';
import 'package:lingolens/domain/provider_contracts.dart';
import 'package:lingolens/infrastructure/fake_analysis_provider.dart';
import 'package:lingolens/presentation/analysis_page.dart';

void main() {
  testWidgets('remote provider disclosure is visible without a picker', (
    tester,
  ) async {
    final controller = AnalysisController(provider: FakeAnalysisProvider());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisPage(
          controller: controller,
          onFailureScenarioChanged: (_) {},
          providerDisclosure: const ProviderDisclosure(
            providerName: 'OpenAI Responses API',
            message: '輸入內容會傳送至已設定的遠端 Provider。',
          ),
        ),
      ),
    );

    expect(find.textContaining('OpenAI Responses API'), findsOneWidget);
    expect(find.textContaining('輸入內容會傳送至已設定的遠端 Provider。'), findsOneWidget);
    expect(find.text('手動輸入 → 模式選擇 → 分析結果'), findsOneWidget);
    expect(find.textContaining('Progressive Fake Provider'), findsNothing);
  });
}
