import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/responsive.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/profile_providers.dart';
import '../domain/user_profile.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(currentProfileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          failure: error is AppFailure ? error : null,
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (p) => _ProfileView(profile: p),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ResponsiveCenter(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(
                profile.initials,
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            profile.displayName ??
                (profile.isGuest ? l10n.authGuestName : profile.email ?? ''),
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (profile.isGuest)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Center(child: Chip(label: Text(l10n.profileGuestBadge))),
            ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(l10n.profileUserId),
                  subtitle: Text(profile.id),
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(l10n.profileEmail),
                  subtitle: Text(profile.email ?? l10n.profileNoEmail),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
