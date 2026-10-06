import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure_messages.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/responsive.dart';
import '../../../shared/widgets/state_views.dart';
import '../../file/application/file_providers.dart';
import '../application/chat_providers.dart';
import '../application/conversation_controller.dart';
import '../domain/chat_provider.dart';
import '../domain/entities/conversation.dart';
import '../domain/entities/message.dart';
import 'widgets/chat_composer.dart';
import 'widgets/message_bubble.dart';
import 'widgets/typing_indicator.dart';

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final _scrollController = ScrollController();

  ConversationController get _controller =>
      ref.read(conversationControllerProvider(widget.conversationId).notifier);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // The list is reversed: the "end" is the oldest message.
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  Future<void> _attach() async {
    final picked = await ref.read(attachmentPickerProvider).pick();
    if (picked.isNotEmpty) _controller.addAttachments(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = conversationControllerProvider(widget.conversationId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final info = controller.providerInfo;
    final selfId = controller.self.id;
    final conversation = ref
        .watch(conversationsProvider)
        .value
        ?.where((c) => c.id == widget.conversationId)
        .firstOrNull;

    ref.listen(provider.select((s) => s.loadFailure), (_, failure) {
      if (failure != null && state.messages.isNotEmpty) {
        context.showAppSnackBar(
          failure.localizedMessage(l10n),
          type: AppSnackType.error,
        );
      }
    });

    final lastAiIndex = state.messages.lastIndexWhere(
      (m) => m.sender.isAutomated,
    );
    final canRegenerate =
        info.supports(ChatCapability.regenerate) &&
        !state.isGenerating &&
        lastAiIndex == state.messages.length - 1 &&
        state.messages.any((m) => m.sender.id == selfId);

    return Scaffold(
      appBar: AppBar(
        title: Text(conversation?.title ?? l10n.chatTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              info.displayName,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            Expanded(
              child: _buildMessages(
                context,
                state,
                selfId,
                conversation,
                canRegenerate,
                lastAiIndex,
              ),
            ),
            TypingIndicator(participants: state.typing),
            ChatComposer(
              onSend: controller.send,
              onAttach: info.supports(ChatCapability.attachments)
                  ? _attach
                  : null,
              onStop: info.supports(ChatCapability.stopGeneration)
                  ? controller.stopGeneration
                  : null,
              isGenerating: state.isGenerating,
              replyTo: state.replyTo == null
                  ? null
                  : ReplyReference.of(state.replyTo!),
              onCancelReply: () => controller.setReplyTo(null),
              attachments: state.pendingAttachments,
              onRemoveAttachment: controller.removeAttachment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(
    BuildContext context,
    ConversationState state,
    String selfId,
    Conversation? conversation,
    bool canRegenerate,
    int lastAiIndex,
  ) {
    final l10n = context.l10n;
    if (state.messages.isEmpty) {
      if (state.isInitialLoading) return const LoadingView();
      if (state.loadFailure != null) {
        return ErrorView(
          failure: state.loadFailure,
          onRetry: _controller.loadInitial,
        );
      }
      return EmptyView(
        title: l10n.chatEmptyMessages,
        message: l10n.chatDemoHint,
        icon: Icons.chat_bubble_outline,
      );
    }

    final messages = state.messages;
    final isGroup = conversation?.kind == ConversationKind.group;
    final extra = state.isLoadingMore ? 1 : 0;

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: messages.length + extra,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final messageIndex = messages.length - 1 - index;
        final message = messages[messageIndex];
        final isMine = message.sender.id == selfId;
        return MessageBubble(
          key: ValueKey(message.id),
          message: message,
          isMine: isMine,
          showSenderName: isGroup,
          onRetry: isMine ? () => _controller.retry(message) : null,
          onReply: () => _controller.setReplyTo(message),
          onRegenerate: canRegenerate && messageIndex == lastAiIndex
              ? _controller.regenerate
              : null,
        );
      },
    );
  }
}
