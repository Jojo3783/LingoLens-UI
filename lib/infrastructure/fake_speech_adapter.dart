import '../application/analysis_action_contracts.dart';

final class FakeSpeechAdapter implements SpeechAdapter {
  final List<String> spokenTexts = <String>[];
  int stopCount = 0;
  bool shouldFail = false;

  @override
  Future<void> speak(String text) async {
    if (shouldFail) {
      throw StateError('synthetic fake speech failure');
    }
    spokenTexts.add(text);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }
}
