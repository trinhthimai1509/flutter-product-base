import 'package:flutter/foundation.dart';

/// Where the "onboarding completed" flag lives. The app implements it on its
/// own preferences store, so this package never owns a storage key.
abstract interface class OnboardingCompletionStore {
  bool get isCompleted;
  Future<void> setCompleted(bool completed);
}

class InMemoryOnboardingCompletionStore implements OnboardingCompletionStore {
  InMemoryOnboardingCompletionStore({this.isCompleted = false});

  @override
  bool isCompleted;

  @override
  Future<void> setCompleted(bool completed) async => isCompleted = completed;
}

/// Pager state + completion. Skipping counts as completing.
///
/// Navigate away when [isCompleted] turns true (listen to this notifier),
/// not on the button press: the flag is written to the store first.
class OnboardingController extends ChangeNotifier {
  OnboardingController(this._store) : _isCompleted = _store.isCompleted;

  final OnboardingCompletionStore _store;
  int _pageIndex = 0;
  bool _isCompleted;

  int get pageIndex => _pageIndex;
  bool get isCompleted => _isCompleted;

  /// Advances, or completes when the last page is exhausted.
  Future<void> next(int pageCount) async {
    if (_pageIndex + 1 >= pageCount) return finish();
    goToPage(_pageIndex + 1);
  }

  /// Reports a swipe (or a tap on a page indicator).
  void goToPage(int index) {
    if (index == _pageIndex || index < 0) return;
    _pageIndex = index;
    notifyListeners();
  }

  Future<void> skip() => finish();

  Future<void> finish() async {
    if (_isCompleted) return;
    await _store.setCompleted(true);
    _isCompleted = true;
    notifyListeners();
  }

  /// Shows onboarding again from the first page (e.g. a "replay intro"
  /// setting, or the demo).
  Future<void> reset() async {
    await _store.setCompleted(false);
    _isCompleted = false;
    _pageIndex = 0;
    notifyListeners();
  }
}
