import 'package:flutter/material.dart';
import 'package:flutter_project_base/core/error/app_failure.dart';
import 'package:flutter_project_base/shared/widgets/app_button.dart';
import 'package:flutter_project_base/shared/widgets/app_text_field.dart';
import 'package:flutter_project_base/shared/widgets/state_views.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('AppButton', () {
    testWidgets('calls onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        testApp(AppButton(label: 'Go', onPressed: () => taps++)),
      );
      await tester.tap(find.text('Go'));
      expect(taps, 1);
    });

    testWidgets('loading state shows spinner and blocks taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        testApp(
          AppButton(label: 'Go', onPressed: () => taps++, isLoading: true),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Go'), findsNothing);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
    });
  });

  testWidgets('AppTextField toggles password visibility', (tester) async {
    await tester.pumpWidget(
      testApp(const AppTextField(label: 'Pw', obscure: true)),
    );
    TextField field() => tester.widget<TextField>(find.byType(TextField));
    expect(field().obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(field().obscureText, isFalse);
  });

  group('state views', () {
    testWidgets('LoadingView shows label', (tester) async {
      await tester.pumpWidget(testApp(const LoadingView(label: 'Wait')));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Wait'), findsOneWidget);
    });

    testWidgets('EmptyView uses localized default title', (tester) async {
      await tester.pumpWidget(testApp(const EmptyView()));
      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    testWidgets('ErrorView localizes failure and retries', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        testApp(
          ErrorView(
            failure: const NetworkFailure(),
            onRetry: () => retried = true,
          ),
        ),
      );
      expect(find.textContaining('No internet connection'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('ErrorView is translated to Vietnamese', (tester) async {
      await tester.pumpWidget(
        testApp(
          const ErrorView(failure: ServerFailure()),
          locale: const Locale('vi'),
        ),
      );
      expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
    });
  });
}
