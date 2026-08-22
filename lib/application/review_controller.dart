import 'package:flutter/foundation.dart';

import '../domain/persistence_contracts.dart';
import 'persistence_controller.dart';

enum ReviewFamiliarity {
  needsPractice,
  gettingThere,
  mastered,
}

sealed class ReviewSessionState {
  const ReviewSessionState();
}

final class ReviewSessionLoading extends ReviewSessionState {
  const ReviewSessionLoading();
}

final class ReviewSessionEmpty extends ReviewSessionState {
  const ReviewSessionEmpty();
}

final class ReviewCardPrompt extends ReviewSessionState {
  const ReviewCardPrompt({
    required this.currentIndex,
    required this.totalCount,
    required this.currentRecord,
  });

  final int currentIndex;
  final int totalCount;
  final HistoryRecord currentRecord;
}

final class ReviewCardRevealed extends ReviewSessionState {
  const ReviewCardRevealed({
    required this.currentIndex,
    required this.totalCount,
    required this.currentRecord,
  });

  final int currentIndex;
  final int totalCount;
  final HistoryRecord currentRecord;
}

final class ReviewSessionCompleted extends ReviewSessionState {
  const ReviewSessionCompleted({
    required this.reviewedCount,
  });

  final int reviewedCount;
}

class ReviewController extends ChangeNotifier {
  ReviewController({
    required PersistenceController persistence,
    DateTime Function()? clock,
  })  : _persistence = persistence,
        _clock = clock ?? DateTime.now;

  final PersistenceController _persistence;
  final DateTime Function() _clock;

  ReviewSessionState _state = const ReviewSessionLoading();
  List<HistoryRecord> _candidates = const [];
  int _currentIndex = 0;
  int _reviewedCount = 0;

  ReviewSessionState get state => _state;
  int get currentIndex => _currentIndex;
  int get totalCount => _candidates.length;

  Future<void> loadSession() async {
    _state = const ReviewSessionLoading();
    notifyListeners();

    final candidates = await _persistence.reviewCandidates(now: _clock());
    _candidates = candidates;
    _currentIndex = 0;
    _reviewedCount = 0;

    if (_candidates.isEmpty) {
      _state = const ReviewSessionEmpty();
    } else {
      _state = ReviewCardPrompt(
        currentIndex: 0,
        totalCount: _candidates.length,
        currentRecord: _candidates[0],
      );
    }
    notifyListeners();
  }

  void reveal() {
    if (_state is! ReviewCardPrompt) return;
    final current = _state as ReviewCardPrompt;
    _state = ReviewCardRevealed(
      currentIndex: current.currentIndex,
      totalCount: current.totalCount,
      currentRecord: current.currentRecord,
    );
    notifyListeners();
  }

  void submitFeedback(ReviewFamiliarity familiarity) {
    if (_state is! ReviewCardRevealed) return;
    _reviewedCount++;
    _advanceToNext();
  }

  void skip() {
    if (_state is! ReviewCardPrompt && _state is! ReviewCardRevealed) return;
    _advanceToNext();
  }

  void finish() {
    _state = ReviewSessionCompleted(reviewedCount: _reviewedCount);
    notifyListeners();
  }

  Future<void> restart() => loadSession();

  void _advanceToNext() {
    _currentIndex++;
    if (_currentIndex >= _candidates.length) {
      _state = ReviewSessionCompleted(reviewedCount: _reviewedCount);
    } else {
      _state = ReviewCardPrompt(
        currentIndex: _currentIndex,
        totalCount: _candidates.length,
        currentRecord: _candidates[_currentIndex],
      );
    }
    notifyListeners();
  }
}
