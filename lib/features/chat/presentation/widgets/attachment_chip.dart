import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../file/domain/attachment.dart';
import '../../../file/domain/mime_types.dart';

/// Compact attachment preview with upload state.
class AttachmentChip extends StatelessWidget {
  const AttachmentChip({super.key, required this.attachment, this.onRemove});

  final Attachment attachment;
  final VoidCallback? onRemove;

  static IconData iconFor(AttachmentKind kind) => switch (kind) {
    AttachmentKind.image => Icons.image_outlined,
    AttachmentKind.video => Icons.movie_outlined,
    AttachmentKind.audio => Icons.audiotrack_outlined,
    AttachmentKind.document => Icons.description_outlined,
    AttachmentKind.other => Icons.insert_drive_file_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uploading = attachment.uploadStatus == UploadStatus.uploading;
    final failed = attachment.uploadStatus == UploadStatus.failed;
    final subtitle = uploading
        ? context.l10n.chatUploading
        : attachment.sizeBytes == null
        ? attachment.mimeType
        : MimeTypes.formatBytes(attachment.sizeBytes!);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.smAll,
        border: failed ? Border.all(color: theme.colorScheme.error) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconFor(attachment.kind), size: 20),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(subtitle, style: theme.textTheme.labelSmall),
                if (uploading)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: SizedBox(
                      width: 96,
                      child: LinearProgressIndicator(
                        value: attachment.uploadProgress,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
