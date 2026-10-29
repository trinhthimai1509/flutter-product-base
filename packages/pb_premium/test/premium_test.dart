import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_billing/pb_billing.dart';
import 'package:pb_premium/pb_premium.dart';

const _content = PremiumContent(
  title: 'Go Pro',
  subtitle: 'Support the app',
  benefits: ['No ads', 'All themes'],
  footnote: 'One-time purchase.',
);

void main() {
  late FakeBillingManager billing;

  setUp(() async {
    billing = FakeBillingManager(latency: Duration.zero);
    await billing.initialize();
  });

  tearDown(() => billing.dispose());

  test('purchase updates state and reports completion', () async {
    final controller = PremiumController(billing);
    addTearDown(controller.dispose);

    await controller.purchase();
    expect(controller.state.isOwned, isTrue);
    expect(controller.state.message, PremiumMessage.purchaseCompleted);

    controller.dismissMessage();
    expect(controller.state.message, isNull);
  });

  test('cancel says nothing; failure says failed', () async {
    final controller = PremiumController(billing);
    addTearDown(controller.dispose);

    billing.nextOutcome = const PurchaseCancelled();
    await controller.purchase();
    expect(controller.state.message, isNull);

    billing.nextOutcome = const PurchaseFailed(BillingError.purchaseFailed);
    await controller.purchase();
    expect(controller.state.message, PremiumMessage.failed);
    expect(controller.state.isOwned, isFalse);
  });

  test('restore maps outcomes to messages', () async {
    final controller = PremiumController(billing);
    addTearDown(controller.dispose);

    await controller.restore();
    expect(controller.state.message, PremiumMessage.nothingToRestore);

    billing.ownedInStore = true;
    await controller.restore();
    expect(controller.state.message, PremiumMessage.restored);
    expect(controller.state.isOwned, isTrue);
  });

  testWidgets('PremiumView shows price, buys, then shows owned', (
    tester,
  ) async {
    final controller = PremiumController(billing);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PremiumView(content: _content, controller: controller),
        ),
      ),
    );

    expect(find.text('Go Pro'), findsOneWidget);
    expect(find.text('No ads'), findsOneWidget);
    await tester.tap(find.text(r'Get Pro for $4.99'));
    await tester.pumpAndSettle();

    expect(find.text('You have Pro. Thank you!'), findsOneWidget);
    expect(find.text('Welcome to Pro!'), findsOneWidget);
    expect(find.text('Restore purchase'), findsNothing);
  });

  testWidgets('PremiumView disables purchase without a product', (
    tester,
  ) async {
    final empty = FakeBillingManager(product: null, latency: Duration.zero);
    addTearDown(empty.dispose);
    await empty.initialize();
    final controller = PremiumController(empty);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PremiumView(content: _content, controller: controller),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.text('Not available right now'), findsOneWidget);
  });
}
