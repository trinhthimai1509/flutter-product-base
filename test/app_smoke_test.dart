import 'package:flutter/material.dart';
import 'package:flutter_project_base/app/app.dart';
import 'package:flutter_project_base/app/router/app_router.dart';
import 'package:flutter_project_base/features/chat/application/chat_providers.dart';
import 'package:flutter_project_base/features/chat/data/providers/mock_chat_provider.dart';
import 'package:flutter_project_base/features/chat/domain/chat_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

/// End-to-end smoke tests of the real app widget with in-memory
/// infrastructure: bootstrap, routing guards, auth, chat and settings.
void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    // Phone-sized viewport.
    tester.view.physicalSize = const Size(1260, 2700);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: noRetry,
        overrides: [
          ...baseTestOverrides(),
          chatProviderProvider.overrideWith((ref) {
            final provider = MockChatProvider(
              self: ref.watch(chatSelfProvider),
              tokenDelay: Duration.zero,
              replyDelay: Duration.zero,
            );
            ref.onDispose(provider.dispose);
            return provider as ChatProvider;
          }),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('boots to sign-in and enters home as guest', (tester) async {
    await pumpApp(tester);
    expect(find.text('Welcome'), findsOneWidget);

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Guest'), findsOneWidget);
    expect(find.text('Chat demo'), findsOneWidget);
  });

  testWidgets('chat demo: open conversation, send, receive AI reply', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat demo'));
    await tester.pumpAndSettle();
    expect(find.text('Mock Assistant'), findsOneWidget);
    expect(find.text('Customer Support'), findsOneWidget);
    expect(find.text('Product Team'), findsOneWidget);

    await tester.tap(find.text('Mock Assistant'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hello bot');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Hello bot', findRichText: true),
      findsWidgets,
      reason: 'sent bubble (and quoted in the reply)',
    );
    expect(
      find.textContaining('streamed by MockChatProvider', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('settings: switch language and theme, then sign out', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();
    expect(find.text('Cài đặt'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Đăng xuất'), 200);
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    // Confirm dialog.
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng'), findsOneWidget);
  });

  testWidgets('unknown routes show the not-found page', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    ProviderScope.containerOf(context).read(routerProvider).go('/nope');
    await tester.pumpAndSettle();
    expect(find.text('Page not found'), findsOneWidget);
  });
}
