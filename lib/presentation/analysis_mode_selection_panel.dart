import 'package:flutter/material.dart';

import '../application/analysis_controller.dart';
import 'analysis_mode_chips.dart';

final class AnalysisModeSelectionPanel extends StatelessWidget {
  const AnalysisModeSelectionPanel({required this.controller, super.key});

  final AnalysisController controller;

  @override
  Widget build(BuildContext context) {
    return AnalysisModeChips(controller: controller);
  }
}
