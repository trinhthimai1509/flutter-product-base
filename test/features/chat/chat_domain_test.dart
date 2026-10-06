import 'package:flutter_project_base/features/chat/domain/entities/message.dart';
import 'package:flutter_project_base/features/chat/domain/entities/message_metadata.dart';
import 'package:flutter_project_base/features/chat/domain/entities/participant.dart';
import 'package:flutter_project_base/features/chat/domain/extensions/ai_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Example of an app-defined extension (e.g. a booking app).
class BookingRef extends MessageExtension {
  const BookingRef(this.bookingId);
  final String bookingId;

  @override
  String get key => 'app.booking';

  @override
  Map<String, Object?> toJson() => {'bookingId': bookingId};

  @override
  List<Object?> get props => [bookingId];
}

void main() {
  const user = Participant(id: 'u', displayName: 'Me', type: SenderType.user);
  const ai = Participant(id: 'ai', displayName: 'AI', type: SenderType.ai);

  Message msg(String id, DateTime at, {String content = 'hi'}) => Message(
    id: id,
    conversationId: 'c',
    sender: user,
    createdAt: at,
    content: content,
  );

  group('MessageMetadata', () {
    test('stores typed extensions and returns them by type', () {
      const info = AiGenerationInfo(
        model: ModelInfo(id: 'm', displayName: 'M'),
        finishReason: FinishReasons.stop,
      );
      final metadata = MessageMetadata.of([info, const BookingRef('b-1')]);
      expect(metadata.get<AiGenerationInfo>(), info);
      expect(metadata.get<BookingRef>()?.bookingId, 'b-1');
      expect(metadata.get<Citations>(), isNull);
      expect(metadata.has<BookingRef>(), isTrue);
    });

    test('put replaces and remove deletes, immutably', () {
      final a = MessageMetadata.of([const BookingRef('1')]);
      final b = a.put(const BookingRef('2'));
      expect(a.get<BookingRef>()?.bookingId, '1');
      expect(b.get<BookingRef>()?.bookingId, '2');
      expect(b.remove<BookingRef>().isEmpty, isTrue);
    });

    test('serializes by extension key', () {
      final json = MessageMetadata.of([const BookingRef('9')]).toJson();
      expect(json, {
        'app.booking': {'bookingId': '9'},
      });
    });
  });

  group('Message', () {
    test('compareByTime orders chronologically with id tie-break', () {
      final t = DateTime(2026);
      final list = [
        msg('b', t),
        msg('c', t.subtract(const Duration(seconds: 1))),
        msg('a', t),
      ]..sort(Message.compareByTime);
      expect(list.map((m) => m.id), ['c', 'a', 'b']);
    });

    test('ReplyReference builds a truncated preview', () {
      final long = msg('x', DateTime(2026), content: 'a' * 200);
      final ref = ReplyReference.of(long, maxLength: 10);
      expect(ref.messageId, 'x');
      expect(ref.senderName, 'Me');
      expect(ref.preview, '${'a' * 10}…');
    });

    test('status helpers', () {
      final m = msg('1', DateTime(2026));
      expect(m.copyWith(status: MessageStatus.failed).isFailed, isTrue);
      expect(m.copyWith(status: MessageStatus.streaming).isStreaming, isTrue);
    });
  });

  test('participant classification', () {
    expect(user.isHuman, isTrue);
    expect(ai.isAutomated, isTrue);
    expect(Participant.system.type, SenderType.system);
  });
}
