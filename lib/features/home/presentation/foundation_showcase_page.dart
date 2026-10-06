import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/responsive.dart';
import '../../../shared/widgets/state_views.dart';
import '../../chat/presentation/widgets/attachment_chip.dart';
import '../../file/domain/attachment.dart';
import '../../file/domain/mime_types.dart';
import '../../notification/application/notification_providers.dart';
import '../../notification/domain/app_notification.dart';

/// Visual catalogue of the design system and foundation services.
class FoundationShowcasePage extends ConsumerWidget {
  const FoundationShowcasePage({super.key});

  static final _sampleAttachments = [
    for (final name in ['photo.jpg', 'clip.mp4', 'voice.m4a', 'contract.pdf'])
      Attachment(
        id: name,
        name: name,
        mimeType: MimeTypes.fromFileName(name),
        kind: MimeTypes.kindOf(MimeTypes.fromFileName(name)),
        sizeBytes: 1024 * 1024 + name.length * 4096,
        source: RemoteAttachmentSource(url: 'https://files.example.com/$name'),
      ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.showcaseTitle)),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            section(
              l10n.showcaseButtons,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(label: l10n.showcasePrimary, onPressed: () {}),
                  AppButton(
                    label: l10n.showcaseSecondary,
                    variant: AppButtonVariant.secondary,
                    onPressed: () {},
                  ),
                  AppButton(
                    label: l10n.showcaseTextButton,
                    variant: AppButtonVariant.text,
                    onPressed: () {},
                  ),
                  AppButton(
                    label: l10n.showcasePrimary,
                    onPressed: () {},
                    isLoading: true,
                  ),
                  AppButton(label: l10n.showcasePrimary, onPressed: null),
                ],
              ),
            ),
            section(
              l10n.showcaseInputs,
              Column(
                children: [
                  AppTextField(
                    label: l10n.showcaseSampleInput,
                    prefixIcon: Icons.search,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(label: l10n.authPasswordLabel, obscure: true),
                ],
              ),
            ),
            section(
              l10n.showcaseStates,
              Column(
                children: [
                  _StateBox(child: LoadingView(label: l10n.commonLoading)),
                  const SizedBox(height: AppSpacing.md),
                  const _StateBox(child: EmptyView()),
                  const SizedBox(height: AppSpacing.md),
                  _StateBox(
                    child: ErrorView(
                      failure: const NetworkFailure(),
                      onRetry: () {},
                    ),
                  ),
                ],
              ),
            ),
            section(
              l10n.showcaseFeedback,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: l10n.showcaseShowDialog,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.showConfirmDialog(
                      title: l10n.showcaseShowDialog,
                      message: l10n.showcaseDialogMessage,
                    ),
                  ),
                  AppButton(
                    label: l10n.showcaseShowSnackbar,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.showAppSnackBar(
                      l10n.showcaseSnackbarMessage,
                      type: AppSnackType.success,
                    ),
                  ),
                  AppButton(
                    label: l10n.showcaseSendNotification,
                    variant: AppButtonVariant.secondary,
                    icon: Icons.notifications_outlined,
                    onPressed: () => ref
                        .read(inAppNotificationCenterProvider)
                        .publish(
                          AppNotification(
                            id: DateTime.now().toIso8601String(),
                            channel: NotificationChannel.inApp,
                            title: l10n.showcaseNotificationTitle,
                            body: l10n.showcaseNotificationBody,
                          ),
                        ),
                  ),
                ],
              ),
            ),
            section(
              l10n.showcaseAttachments,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final a in _sampleAttachments)
                    AttachmentChip(attachment: a),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateBox extends StatelessWidget {
  const _StateBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: AppRadius.mdAll,
      ),
      child: child,
    );
  }
}
