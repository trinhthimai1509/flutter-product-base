import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_onboarding/pb_onboarding.dart';

const _pages = [
  OnboardingPage(title: 'One', description: 'First'),
  OnboardingPage(title: 'Two', description: 'Second'),
];

void main() {
  group('OnboardingController', () {
    test('starts completed when the store says so', () {
      final controller = OnboardingController(
        InMemoryOnboardingCompletionStore(isCompleted: true),
      );
      expect(controller.isCompleted, isTrue);
    });

    test(
      'next advances, then completes and persists on the last page',
      () async {
        final store = InMemoryOnboardingCompletionStore();
        final controller = OnboardingController(store);

        await controller.next(2);
        expect(controller.pageIndex, 1);
        expect(controller.isCompleted, isFalse);

        await controller.next(2);
        expect(controller.isCompleted, isTrue);
        expect(store.isCompleted, isTrue);
      },
    );

    test('skip completes; reset starts over', () async {
      final store = InMemoryOnboardingCompletionStore();
      final controller = OnboardingController(store);

      await controller.skip();
      expect(store.isCompleted, isTrue);

      await controller.reset();
      expect(controller.isCompleted, isFalse);
      expect(controller.pageIndex, 0);
      expect(store.isCompleted, isFalse);
    });
  });

  testWidgets('OnboardingView: next, then finish completes', (tester) async {
    final controller = OnboardingController(
      InMemoryOnboardingCompletionStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingView(pages: _pages, controller: controller),
        ),
      ),
    );

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(controller.isCompleted, isTrue);
  });

  testWidgets('OnboardingView: swiping updates the controller', (tester) async {
    final controller = OnboardingController(
      InMemoryOnboardingCompletionStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingView(
            pages: _pages,
            controller: controller,
            labels: const OnboardingLabels(skip: 'Bỏ qua'),
          ),
        ),
      ),
    );

    await tester.fling(find.text('One'), const Offset(-600, 0), 1500);
    await tester.pumpAndSettle();
    expect(controller.pageIndex, 1);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(controller.isCompleted, isTrue);
  });
}
