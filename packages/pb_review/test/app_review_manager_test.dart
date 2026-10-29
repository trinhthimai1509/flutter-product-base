import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:pb_review/pb_review.dart';

class _UnavailableReview implements InAppReview {
  int requests = 0;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> requestReview() async => requests++;

  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async => throw StateError('no store');
}

void main() {
  test('unavailable flow never requests and never throws', () async {
    final review = _UnavailableReview();
    final manager = InAppReviewManager(inAppReview: review);

    expect(await manager.requestReview(), ReviewOutcome.unavailable);
    expect(review.requests, 0);
    expect(await manager.openStoreListing(), isFalse);
  });

  test('FakeAppReviewManager counts calls', () async {
    final fake = FakeAppReviewManager();
    expect(await fake.requestReview(), ReviewOutcome.completed);
    await fake.openStoreListing();
    expect(fake.requestCount, 1);
    expect(fake.storeOpenCount, 1);
  });
}
