import '../domain/analysis_models.dart';

typedef ActionToken = ({RequestId requestId, int generation});

final class AnalysisActionGuard {
  int _generation = 0;
  bool _disposed = false;

  ActionToken? begin(RequestId? requestId) {
    if (requestId == null || _disposed) {
      return null;
    }
    return (requestId: requestId, generation: ++_generation);
  }

  void invalidate() {
    if (!_disposed) {
      _generation++;
    }
  }

  void dispose() {
    _disposed = true;
    _generation++;
  }

  bool get isDisposed => _disposed;

  bool isCurrent(ActionToken token, RequestId? requestId) =>
      !_disposed &&
      requestId == token.requestId &&
      _generation == token.generation;
}
