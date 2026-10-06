import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/participant.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key, required this.participants});

  final Set<Participant> participants;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final names = participants.map((p) => p.displayName).join(', ');
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              context.l10n.chatTyping(names),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
