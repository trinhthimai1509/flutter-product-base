import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../file/domain/attachment.dart';
import '../../domain/entities/message.dart';
import 'attachment_chip.dart';

/// Message input with send / stop / attach and reply preview.
/// State-management agnostic: everything goes through callbacks.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.onSend,
    this.onAttach,
    this.onStop,
    this.isGenerating = false,
    this.replyTo,
    this.onCancelReply,
    this.attachments = const [],
    this.onRemoveAttachment,
  });

  final ValueChanged<String> onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onStop;
  final bool isGenerating;
  final ReplyReference? replyTo;
  final VoidCallback? onCancelReply;
  final List<Attachment> attachments;
  final ValueChanged<String>? onRemoveAttachment;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend => _hasText || widget.attachments.isNotEmpty;

  void _submit() {
    if (!_canSend) return;
    widget.onSend(_controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.replyTo != null)
                _ReplyBanner(
                  reply: widget.replyTo!,
                  onCancel: widget.onCancelReply,
                ),
              if (widget.attachments.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final a in widget.attachments)
                          AttachmentChip(
                            attachment: a,
                            onRemove: widget.onRemoveAttachment == null
                                ? null
                                : () => widget.onRemoveAttachment!(a.id),
                          ),
                      ],
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.onAttach != null)
                    IconButton(
                      tooltip: l10n.chatAttach,
                      icon: const Icon(Icons.attach_file),
                      onPressed: widget.onAttach,
                    ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: l10n.chatComposerHint,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (widget.isGenerating && widget.onStop != null)
                    IconButton.filledTonal(
                      tooltip: l10n.chatStop,
                      icon: const Icon(Icons.stop),
                      onPressed: widget.onStop,
                    )
                  else
                    IconButton.filled(
                      tooltip: l10n.chatSend,
                      icon: const Icon(Icons.send),
                      onPressed: _canSend ? _submit : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyBanner extends StatelessWidget {
  const _ReplyBanner({required this.reply, this.onCancel});

  final ReplyReference reply;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.only(left: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chatReplyingTo(reply.senderName),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  reply.preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.chatCancelReply,
            icon: const Icon(Icons.close),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
