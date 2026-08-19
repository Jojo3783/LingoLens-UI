import 'package:flutter/material.dart';

import '../application/analysis_action_controller.dart';
import '../application/analysis_state.dart';
import 'analysis_result_card.dart';

final class AnalysisResultPanel extends StatelessWidget {
  const AnalysisResultPanel({required this.success, this.actions, super.key});

  final AnalysisSuccess success;
  final AnalysisActionController? actions;

  @override
  Widget build(BuildContext context) {
    return AnalysisResultCard(success: success, actions: actions);
  }
}
