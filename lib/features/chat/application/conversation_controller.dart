import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../file/domain/attachment.dart';
import '../domain/chat_provider.dart';
import '../domain/entities/message.dart';
import '../domain/entities/participant.dart';
import 'chat_providers.dart';

class ConversationState extends Equatable {
  const ConversationState({
    this.messages = const [],
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.loadFailure,
    this.typing = const {},
    this.replyTo,
    this.pendingAttachments = const [],
  });

  final List<Message> messages;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final AppFailure? loadFailure;
  final Set<Participant> typing;
  final Message? replyTo;
  final List<Attachment> pendingAttachments;

  bool get isGenerating => messages.any((m) => m.isStreaming);

  ConversationState copyWith({
    List<Message>? messages,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    AppFailure? Function()? loadFailure,
    Set<Participant>? typing,
    Message? Function()? replyTo,
    List<Attachment>? pendingAttachments,
  }) => ConversationState(
    messages: messages ?? this.messages,
    isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    loadFailure: loadFailure == null ? this.loadFailure : loadFailure(),
    typing: typing ?? this.typing,
    replyTo: replyTo == null ? this.replyTo : replyTo(),
    pendingAttachments: pendingAttachments ?? this.pendingAttachments,
  );

  @override
  List<Object?> get props => [
    messages,
    isInitialLoading,
    isLoadingMore,
    hasMore,
    loadFailure,
    typing,
    replyTo,
    pendingAttachments,
  ];
}

final conversationControllerProvider = NotifierProvider.autoDispose
    .family<ConversationController, ConversationState, String>(
      ConversationController.new,
    );

/// State holder for one conversation screen.
class ConversationController extends Notifier<ConversationState> {
  ConversationController(this.conversationId);

  final String conversationId;

  @override
  ConversationState build() {
    final repository = ref.watch(chatRepositoryProvider);
    final messagesSub = repository
        .watchMessages(conversationId)
        .listen((messages) => state = state.copyWith(messages: messages));
    final typingSub = repository
        .watchTyping(conversationId)
        .listen((typing) => state = state.copyWith(typing: typing));
    ref.onDispose(() {
      messagesSub.cancel();
      typingSub.cancel();
    });
    unawaited(Future.microtask(loadInitial));
    return const ConversationState();
  }

  ChatProviderInfo get providerInfo =>
      ref.read(chatRepositoryProvider).providerInfo;

  Participant get self => ref.read(chatRepositoryProvider).self;

  Future<void> loadInitial() async {
    final repository = ref.read(chatRepositoryProvider);
    state = state.copyWith(isInitialLoading: true, loadFailure: () => null);
    final result = await repository.loadInitial(conversationId);
    if (!ref.mounted) return;
    state = state.copyWith(
      isInitialLoading: false,
      hasMore: repository.hasMore(conversationId),
      loadFailure: () => result.failureOrNull,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    final result = await ref
        .read(chatRepositoryProvider)
        .loadOlder(conversationId);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(isLoadingMore: false, hasMore: value),
      Err(:final failure) => state.copyWith(
        isLoadingMore: false,
        loadFailure: () => failure,
      ),
    };
  }

  Future<void> send(String text) async {
    final attachments = state.pendingAttachments;
    final reply = state.replyTo;
    if (text.trim().isEmpty && attachments.isEmpty) return;
    state = state.copyWith(replyTo: () => null, pendingAttachments: const []);
    await ref
        .read(chatRepositoryProvider)
        .sendMessage(
          conversationId,
          text: text,
          attachments: attachments,
          replyTo: reply == null ? null : ReplyReference.of(reply),
        );
  }

  Future<void> retry(Message message) =>
      ref.read(chatRepositoryProvider).retry(conversationId, message.id);

  Future<void> stopGeneration() =>
      ref.read(chatRepositoryProvider).stopGeneration(conversationId);

  Future<void> regenerate() =>
      ref.read(chatRepositoryProvider).regenerate(conversationId);

  void setReplyTo(Message? message) =>
      state = state.copyWith(replyTo: () => message);

  void addAttachments(List<Attachment> attachments) => state = state.copyWith(
    pendingAttachments: [...state.pendingAttachments, ...attachments],
  );

  void removeAttachment(String id) => state = state.copyWith(
    pendingAttachments: [
      for (final a in state.pendingAttachments)
        if (a.id != id) a,
    ],
  );
}
