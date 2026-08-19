import 'package:flutter/services.dart';

import '../application/analysis_action_contracts.dart';

final class FlutterClipboardWriter implements ClipboardWriter {
  const FlutterClipboardWriter();

  @override
  Future<void> writeText(String text) {
    return Clipboard.setData(ClipboardData(text: text));
  }
}
