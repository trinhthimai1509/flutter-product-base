import 'package:flutter/material.dart';
import 'package:flutter_project_base/features/chat/domain/entities/message.dart';
import 'package:flutter_project_base/features/chat/domain/entities/message_metadata.dart';
import 'package:flutter_project_base/features/chat/domain/entities/participant.dart';
import 'package:flutter_project_base/features/chat/domain/extensions/ai_extensions.dart';
import 'package:flutter_project_base/features/chat/presentation/widgets/chat_composer.dart';
import 'package:flutter_project_base/features/chat/presentation/widgets/message_bubble.dart';
import 'package:flutter_project_base/features/chat/presentation/widgets/typing_indicator.dart';
import 'package:flutter_project_base/features/file/domain/attachment.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

const me = Participant(id: 'me', displayName: 'Me', type: SenderType.user);
const agent = Participant(
  id: 'a',
  displayName: 'Agent Linh',
  type: SenderType.agent,
);

Message message({
  String content = 'Hello there',
  Participant sender = me,
  MessageStatus status = MessageStatus.sent,
  MessageType type = MessageType.text,
  ReplyReference? replyTo,
  MessageMetadata metadata = const MessageMetadata.empty(),
  List<Attachment> attachments = const [],
}) => Message(
  id: 'm1',
  conversationId: 'c',
  sender: sender,
  createdAt: DateTime(2026, 1, 1, 9, 30),
  content: content,
  status: status,
  type: type,
  replyTo: replyTo,
  metadata: metadata,
  attachments: attachments,
);

void main() {
  group('MessageBubble', () {
    testWidgets('renders text, sender name and status', (tester) async {
      await tester.pumpWidget(
        testApp(
          MessageBubble(
            message: message(sender: agent),
            isMine: false,
            showSenderName: true,
          ),
        ),
      );
      expect(find.text('Hello there'), findsOneWidget);
      expect(find.text('Agent Linh'), findsOneWidget);
    });

    testWidgets('failed message shows hint and retries on tap', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        testApp(
          MessageBubble(
            message: message(status: MessageStatus.failed),
            isMine: true,
            onRetry: () => retried = true,
          ),
        ),
      );
      expect(find.text('Not sent. Tap to retry.'), findsOneWidget);
      await tester.tap(find.text('Hello there'));
      expect(retried, isTrue);
    });

    testWidgets('streaming message shows a caret', (tester) async {
      await tester.pumpWidget(
        testApp(
          MessageBubble(
            message: message(
              content: 'Partial',
              status: MessageStatus.streaming,
            ),
            isMine: false,
          ),
        ),
      );
      expect(find.textContaining('Partial'), findsOneWidget);
      expect(find.textContaining('▍', findRichText: true), findsOneWidget);
    });

    testWidgets('renders reply quote, attachments and citations', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          MessageBubble(
            message: message(
              sender: const Participant(
                id: 'ai',
                displayName: 'AI',
                type: SenderType.ai,
              ),
              replyTo: const ReplyReference(
                messageId: 'x',
                senderName: 'Me',
                preview: 'Original question',
              ),
              attachments: const [
                Attachment(
                  id: 'f',
                  name: 'report.pdf',
                  mimeType: 'application/pdf',
                  kind: AttachmentKind.document,
                  source: RemoteAttachmentSource(url: 'https://x/report.pdf'),
                  sizeBytes: 2048,
                ),
              ],
              metadata: MessageMetadata.of([
                const Citations([SourceReference(id: '1', title: 'Guide')]),
              ]),
            ),
            isMine: false,
          ),
        ),
      );
      expect(find.text('Original question'), findsOneWidget);
      expect(find.text('report.pdf'), findsOneWidget);
      expect(find.text('2.0 KB'), findsOneWidget);
      expect(find.text('Sources'), findsOneWidget);
      expect(find.text('Guide'), findsOneWidget);
    });

    testWidgets('system messages are centered plain text', (tester) async {
      await tester.pumpWidget(
        testApp(
          MessageBubble(
            message: message(
              content: 'Conversation started',
              sender: Participant.system,
              type: MessageType.system,
            ),
            isMine: false,
          ),
        ),
      );
      expect(find.text('Conversation started'), findsOneWidget);
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('long press triggers reply', (tester) async {
      var replied = false;
      await tester.pumpWidget(
        testApp(
          MessageBubble(
            message: message(),
            isMine: true,
            onReply: () => replied = true,
          ),
        ),
      );
      await tester.longPress(find.text('Hello there'));
      expect(replied, isTrue);
    });
  });

  group('ChatComposer', () {
    testWidgets('send is disabled until text is entered, then clears', (
      tester,
    ) async {
      final sent = <String>[];
      await tester.pumpWidget(testApp(ChatComposer(onSend: sent.add)));

      IconButton sendButton() => tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.send),
      );
      expect(sendButton().onPressed, isNull);

      await tester.enterText(find.byType(TextField), '  hi  ');
      await tester.pump();
      expect(sendButton().onPressed, isNotNull);

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      expect(sent, ['hi']);
      expect(find.text('  hi  '), findsNothing);
    });

    testWidgets('shows stop button while generating', (tester) async {
      var stopped = false;
      await tester.pumpWidget(
        testApp(
          ChatComposer(
            onSend: (_) {},
            isGenerating: true,
            onStop: () => stopped = true,
          ),
        ),
      );
      expect(find.byIcon(Icons.send), findsNothing);
      await tester.tap(find.byIcon(Icons.stop));
      expect(stopped, isTrue);
    });

    testWidgets('reply banner can be cancelled; attach is optional', (
      tester,
    ) async {
      var cancelled = false;
      var attached = false;
      await tester.pumpWidget(
        testApp(
          ChatComposer(
            onSend: (_) {},
            onAttach: () => attached = true,
            replyTo: const ReplyReference(
              messageId: 'x',
              senderName: 'Linh',
              preview: 'Earlier',
            ),
            onCancelReply: () => cancelled = true,
          ),
        ),
      );
      expect(find.text('Replying to Linh'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.tap(find.byIcon(Icons.attach_file));
      expect(cancelled, isTrue);
      expect(attached, isTrue);
    });
  });

  testWidgets('TypingIndicator shows names and hides when empty', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(TypingIndicator(participants: {agent})));
    expect(find.text('Agent Linh is typing…'), findsOneWidget);

    await tester.pumpWidget(testApp(const TypingIndicator(participants: {})));
    expect(find.textContaining('typing'), findsNothing);
  });
}
