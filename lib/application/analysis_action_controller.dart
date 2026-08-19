import 'dart:async';

import '../domain/analysis_models.dart';
import '../domain/persistence_contracts.dart';
import 'analysis_action_contracts.dart';
import 'analysis_action_guard.dart';
import 'analysis_state.dart';

final class AnalysisActionController {
  AnalysisActionController({required AnalysisActionPorts ports})
    : _ports = ports;

  final AnalysisActionPorts _ports;
  final StreamController<AnalysisActionState> _states =
      StreamController<AnalysisActionState>.broadcast();

  AnalysisActionState _state = const AnalysisActionState();
  AnalysisSuccess? _success;
  bool _saved = false;
  bool _favorite = false;
  bool _feedbackSubmitted = false;
  bool _feedbackInFlight = false;
  ActionToken? _feedbackOperation;
  final AnalysisActionGuard _actionGuard = AnalysisActionGuard();
  final Set<RequestId> _completedFeedback = <RequestId>{};

  AnalysisActionState get state => _state;
  Stream<AnalysisActionState> get states => _states.stream;

  void reset() {
    _actionGuard.invalidate();
    _success = null;
    _saved = false;
    _favorite = false;
    _feedbackSubmitted = false;
    _feedbackInFlight = false;
    _feedbackOperation = null;
    _emit(const AnalysisActionState());
    unawaited(_stopSpeech());
  }

  void setSuccess(AnalysisSuccess success) {
    _actionGuard.invalidate();
    _success = success;
    _saved = false;
    _favorite = false;
    _feedbackSubmitted = false;
    _feedbackInFlight = false;
    _feedbackOperation = null;
    _emit(
      AnalysisActionState(
        requestId: success.requestId,
        isSaved: _saved,
        isFavorite: _favorite,
        feedbackSubmitted: _feedbackSubmitted,
      ),
    );
  }

  Future<void> copy() => _runTextAction(
    kind: AnalysisActionKind.copy,
    operation: _ports.clipboard.writeText,
  );

  Future<void> listen() => _runTextAction(
    kind: AnalysisActionKind.listen,
    operation: _ports.speech.speak,
  );

  Future<void> save() async {
    final success = _success;
    if (success == null) return;
    final token = _begin(AnalysisActionKind.save);
    if (token == null) return;
    try {
      final didSave = await _ports.persistence.saveHistory(
        HistoryRecord(
          id: _ports.historyIds.idFor(success.requestId),
          input: success.input,
          mode: success.mode,
          result: success.result,
          createdAt: _ports.clock.now(),
        ),
      );
      if (!_isCurrent(token)) {
        return;
      }
      _saved = didSave;
      _emit(
        _stateFor(
          phase: didSave
              ? AnalysisActionPhase.success
              : AnalysisActionPhase.failure,
          kind: AnalysisActionKind.save,
          message: didSave ? '結果已儲存於本次工作階段。' : 'History 寫入已停用，結果未儲存。',
        ),
      );
    } catch (_) {
      _emitFailure(token, AnalysisActionKind.save, '無法儲存分析結果。');
    }
  }

  Future<void> setFavorite(bool isFavorite) async {
    final success = _success;
    if (success == null || !_saved) return;
    final token = _begin(AnalysisActionKind.favorite);
    if (token == null) return;
    try {
      await _ports.persistence.setFavorite(
        historyRecordId: _ports.historyIds.idFor(success.requestId),
        createdAt: _ports.clock.now(),
        isFavorite: isFavorite,
      );
      if (!_isCurrent(token)) {
        return;
      }
      _favorite = isFavorite;
      _emit(
        _stateFor(
          phase: AnalysisActionPhase.success,
          kind: AnalysisActionKind.favorite,
          message: isFavorite ? 'Favorite 已標記。' : 'Favorite 已取消。',
        ),
      );
    } catch (_) {
      _emitFailure(token, AnalysisActionKind.favorite, 'Favorite 更新失敗。');
    }
  }

  Future<void> submitFeedback({
    required RequestId requestId,
    required FeedbackReason reason,
    String? comment,
    bool consentToAttachContent = false,
  }) async {
    final success = _success;
    if (success == null ||
        success.requestId != requestId ||
        _completedFeedback.contains(requestId) ||
        _feedbackSubmitted ||
        _feedbackInFlight) {
      return;
    }
    final token = _begin(AnalysisActionKind.feedback);
    if (token == null) {
      return;
    }
    _feedbackInFlight = true;
    _feedbackOperation = token;
    try {
      await _ports.persistence.submitFeedback(
        id: 'feedback-${success.requestId.value}',
        reason: reason,
        consentToAttachContent: consentToAttachContent,
        comment: comment,
        input: success.input,
        output: _primaryText(success),
        createdAt: _ports.clock.now(),
      );
      _completedFeedback.add(requestId);
      if (_feedbackOperation != token) {
        return;
      }
      _feedbackInFlight = false;
      _feedbackOperation = null;
      if (!_isCurrent(token)) {
        return;
      }
      _feedbackSubmitted = true;
      _emit(
        _stateFor(
          phase: AnalysisActionPhase.success,
          kind: AnalysisActionKind.feedback,
          message: '回饋已儲存於本次工作階段。',
        ),
      );
    } catch (_) {
      if (_feedbackOperation != token) {
        return;
      }
      _feedbackInFlight = false;
      _feedbackOperation = null;
      _emitFailure(token, AnalysisActionKind.feedback, '回饋儲存失敗。');
    }
  }

  Future<void> dispose() async {
    _actionGuard.dispose();
    _success = null;
    _feedbackOperation = null;
    await _stopSpeech();
    await _states.close();
  }

  Future<void> _runTextAction({
    required AnalysisActionKind kind,
    required Future<void> Function(String text) operation,
  }) async {
    final success = _success;
    if (success == null) return;
    final token = _begin(kind);
    if (token == null) return;
    try {
      await operation(_primaryText(success));
      if (_isCurrent(token)) {
        _emit(
          _stateFor(
            phase: AnalysisActionPhase.success,
            kind: kind,
            message: kind == AnalysisActionKind.copy
                ? '已複製結果。'
                : 'Fake Listen 已記錄結果文字。',
          ),
        );
      }
    } catch (_) {
      _emitFailure(
        token,
        kind,
        kind == AnalysisActionKind.copy ? '複製失敗。' : 'Listen 失敗。',
      );
    }
  }

  ActionToken? _begin(AnalysisActionKind kind) {
    final token = _actionGuard.begin(_success?.requestId);
    if (token == null) {
      return null;
    }
    _emit(_stateFor(phase: AnalysisActionPhase.running, kind: kind));
    return token;
  }

  void _emitFailure(
    ActionToken token,
    AnalysisActionKind kind,
    String message,
  ) {
    if (_isCurrent(token)) {
      _emit(
        _stateFor(
          phase: AnalysisActionPhase.failure,
          kind: kind,
          message: message,
        ),
      );
    }
  }

  AnalysisActionState _stateFor({
    required AnalysisActionPhase phase,
    required AnalysisActionKind kind,
    String? message,
  }) => AnalysisActionState(
    phase: phase,
    requestId: _success?.requestId,
    kind: kind,
    message: message,
    isSaved: _saved,
    isFavorite: _favorite,
    feedbackSubmitted: _feedbackSubmitted,
  );

  void _emit(AnalysisActionState nextState) {
    _state = nextState;
    if (!_actionGuard.isDisposed && !_states.isClosed) {
      _states.add(nextState);
    }
  }

  bool _isCurrent(ActionToken token) =>
      _actionGuard.isCurrent(token, _success?.requestId);

  String _primaryText(AnalysisSuccess success) => switch (success.mode) {
    AnalysisMode.reading => success.result.reading.translation,
    AnalysisMode.expression => success.result.expression.natural,
  };

  Future<void> _stopSpeech() async {
    try {
      await _ports.speech.stop();
    } catch (_) {
      // Fake Listen cleanup must not replace the visible analysis result.
    }
  }
}
