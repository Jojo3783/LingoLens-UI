import 'package:flutter/material.dart';

import '../application/analysis_action_controller.dart';
import '../application/analysis_action_contracts.dart';
import '../domain/analysis_models.dart';

final class AnalysisQuickActions extends StatelessWidget {
  const AnalysisQuickActions({
    required this.controller,
    required this.mode,
    super.key,
  });

  final AnalysisActionController controller;
  final AnalysisMode mode;

  @override
  Widget build(BuildContext context) {
    final isReading = mode == AnalysisMode.reading;
    return StreamBuilder<AnalysisActionState>(
      initialData: controller.state,
      stream: controller.states,
      builder: (context, snapshot) {
        final state = snapshot.data ?? controller.state;
        final isRunning = state.phase == AnalysisActionPhase.running;
        return Semantics(
          container: true,
          label: isReading
              ? 'Reading quick actions'
              : 'Expression quick actions',
          child: Wrap(
            key: ValueKey(
              isReading ? 'reading-quick-actions' : 'expression-quick-actions',
            ),
            spacing: 8,
            runSpacing: 8,
            children: [
              Semantics(
                button: true,
                label: isReading ? '複製主要翻譯' : '複製 Natural 結果',
                child: ElevatedButton(
                  key: const ValueKey('copy-result'),
                  onPressed: isRunning ? null : controller.copy,
                  child: const Text('Copy'),
                ),
              ),
              Semantics(
                button: true,
                label: isReading ? '朗讀主要翻譯（Fake）' : '朗讀 Natural 結果（Fake）',
                child: ElevatedButton(
                  key: const ValueKey('listen-fake'),
                  onPressed: isRunning ? null : controller.listen,
                  child: const Text('Listen（Fake）'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
