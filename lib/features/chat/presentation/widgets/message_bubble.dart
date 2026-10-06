import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/participant.dart';
import '../../domain/extensions/ai_extensions.dart';
import 'attachment_chip.dart';

/// Renders one message. Pure widget: all actions are callbacks so it works
/// with any state management and is easy to test.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showSenderName = false,
    this.onRetry,
    this.onReply,
    this.onRegenerate,
  });

  final Message message;
  final bool isMine;
  final bool showSenderName;
  final VoidCallback? onRetry;
  final VoidCallback? onReply;

  /// Shown under the message when non-null (e.g. last AI answer).
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    if (message.sender.type == SenderType.system ||
        message.type == MessageType.system) {
      return _SystemMessage(text: message.content);
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final background = isMine ? scheme.primary : scheme.surfaceContainerHigh;
    final foreground = isMine ? scheme.onPrimary : scheme.onSurface;
    final citations = message.metadata.get<Citations>();

    final bubble = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: message.isFailed ? scheme.errorContainer : background,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppRadius.lg),
          topRight: const Radius.circular(AppRadius.lg),
          bottomLeft: Radius.circular(isMine ? AppRadius.lg : AppRadius.xs),
          bottomRight: Radius.circular(isMine ? AppRadius.xs : AppRadius.lg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyTo != null)
            _ReplyQuote(reply: message.replyTo!, color: foreground),
          if (message.attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final a in message.attachments)
                    AttachmentChip(attachment: a),
                ],
              ),
            ),
          if (message.content.isNotEmpty || message.isStreaming)
            Text.rich(
              TextSpan(
                text: message.content,
                children: [if (message.isStreaming) const TextSpan(text: ' ▍')],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: message.isFailed ? scheme.onErrorContainer : foreground,
              ),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs + 1,
      ),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (showSenderName && !isMine)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                bottom: AppSpacing.xxs,
              ),
              child: Text(
                message.sender.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            child: GestureDetector(
              onTap: message.isFailed ? onRetry : null,
              onLongPress: onReply,
              child: bubble,
            ),
          ),
          if (citations != null && citations.sources.isNotEmpty)
            _Citations(citations: citations),
          _Footer(
            message: message,
            isMine: isMine,
            failedLabel: l10n.chatFailed,
            onRegenerate: onRegenerate,
            regenerateLabel: l10n.chatRegenerate,
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.message,
    required this.isMine,
    required this.failedLabel,
    required this.regenerateLabel,
    this.onRegenerate,
  });

  final Message message;
  final bool isMine;
  final String failedLabel;
  final String regenerateLabel;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final time = TimeOfDay.fromDateTime(message.createdAt).format(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.isFailed)
            Text(
              failedLabel,
              style: style?.copyWith(color: theme.colorScheme.error),
            )
          else
            Text(time, style: style),
          if (isMine && !message.isFailed) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(
              _statusIcon(message.status),
              size: 14,
              color: message.status == MessageStatus.read
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              semanticLabel: message.status.name,
            ),
          ],
          if (onRegenerate != null && !message.isStreaming) ...[
            const SizedBox(width: AppSpacing.sm),
            InkWell(
              onTap: onRegenerate,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 14, color: style?.color),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(regenerateLabel, style: style),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _statusIcon(MessageStatus status) => switch (status) {
    MessageStatus.sending => Icons.schedule,
    MessageStatus.sent || MessageStatus.streaming => Icons.check,
    MessageStatus.delivered || MessageStatus.read => Icons.done_all,
    MessageStatus.failed => Icons.error_outline,
  };
}

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({required this.reply, required this.color});

  final ReplyReference reply;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.6), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.senderName,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            reply.preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _Citations extends StatelessWidget {
  const _Citations({required this.citations});

  final Citations citations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(context.l10n.chatSources, style: theme.textTheme.labelSmall),
          for (final source in citations.sources)
            Chip(
              visualDensity: VisualDensity.compact,
              avatar: const Icon(Icons.link, size: 14),
              label: Text(source.title, style: theme.textTheme.labelSmall),
            ),
        ],
      ),
    );
  }
}

class _SystemMessage extends StatelessWidget {
  const _SystemMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
