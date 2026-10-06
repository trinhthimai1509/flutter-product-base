import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/responsive.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/chat_providers.dart';
import '../domain/entities/conversation.dart';

class ConversationListPage extends ConsumerWidget {
  const ConversationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatTitle)),
      body: conversations.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          failure: error is AppFailure ? error : null,
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (items) => items.isEmpty
            ? EmptyView(
                title: l10n.chatEmptyConversations,
                icon: Icons.forum_outlined,
              )
            : ResponsiveCenter(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _ConversationTile(conversation: items[index]),
                ),
              ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  IconData get _icon => switch (conversation.kind) {
    ConversationKind.assistant => Icons.smart_toy_outlined,
    ConversationKind.support => Icons.support_agent,
    ConversationKind.group => Icons.groups_outlined,
    ConversationKind.direct => Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) {
    final last = conversation.lastMessage;
    final preview = last == null
        ? null
        : last.content.isNotEmpty
        ? last.content
        : last.attachments.map((a) => a.name).join(', ');
    return ListTile(
      leading: CircleAvatar(child: Icon(_icon)),
      title: Text(conversation.title),
      subtitle: preview == null
          ? null
          : Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: conversation.unreadCount > 0
          ? Badge(label: Text('${conversation.unreadCount}'))
          : null,
      onTap: () => context.push(AppRoutes.conversation(conversation.id)),
    );
  }
}
