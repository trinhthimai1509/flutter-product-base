import 'package:in_app_review/in_app_review.dart';
import 'package:pb_common/pb_common.dart';

/// Result of [AppReviewManager.requestReview].
enum ReviewOutcome {
  /// The flow ran. It does NOT mean a dialog appeared or a review was
  /// written: the stores never say. Do not thank, reward or re-prompt
  /// based on it.
  completed,

  /// The in-app flow is not available here (no store, quota, platform).
  unavailable,
}

/// Asks for a store rating at a moment the product chooses.
///
/// There is deliberately no counter, engagement score or automatic prompt:
/// when to ask is a product decision. Nothing here throws.
abstract interface class AppReviewManager {
  Future<ReviewOutcome> requestReview();

  /// Opens the store page (Play Store / App Store) as a fallback, e.g. a
  /// "Rate this app" settings row. Returns false if it could not open.
  Future<bool> openStoreListing();
}

/// [AppReviewManager] backed by `in_app_review`.
class InAppReviewManager implements AppReviewManager {
  InAppReviewManager({
    InAppReview? inAppReview,
    this.appStoreId,
    this._logger = const NoOpPbLogger(),
  }) : _review = inAppReview ?? InAppReview.instance;

  final InAppReview _review;
  final PbLogger _logger;

  /// Numeric App Store id; required for [openStoreListing] on iOS.
  final String? appStoreId;

  @override
  Future<ReviewOutcome> requestReview() async {
    try {
      if (!await _review.isAvailable()) return ReviewOutcome.unavailable;
      await _review.requestReview();
      return ReviewOutcome.completed;
    } on Object catch (error) {
      _logger.warning('In-app review failed', tag: 'review', error: error);
      return ReviewOutcome.unavailable;
    }
  }

  @override
  Future<bool> openStoreListing() async {
    try {
      await _review.openStoreListing(appStoreId: appStoreId);
      return true;
    } on Object catch (error) {
      _logger.warning('Store listing failed', tag: 'review', error: error);
      return false;
    }
  }
}

/// Records calls; for tests and the demo.
class FakeAppReviewManager implements AppReviewManager {
  FakeAppReviewManager({this.outcome = ReviewOutcome.completed});

  ReviewOutcome outcome;
  int requestCount = 0;
  int storeOpenCount = 0;

  @override
  Future<ReviewOutcome> requestReview() async {
    requestCount++;
    return outcome;
  }

  @override
  Future<bool> openStoreListing() async {
    storeOpenCount++;
    return true;
  }
}
