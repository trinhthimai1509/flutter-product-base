import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/responsive.dart';
import '../../auth/application/auth_providers.dart';

/// Demo landing page linking to each foundation module.
/// Replace with the real home screen in a product app.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final name = user == null || user.isAnonymous
        ? l10n.authGuestName
        : user.displayName ?? user.email ?? l10n.authGuestName;

    final items = [
      _HomeItem(
        Icons.forum_outlined,
        l10n.homeChatTitle,
        l10n.homeChatSubtitle,
        AppRoutes.chat,
      ),
      _HomeItem(
        Icons.widgets_outlined,
        l10n.homeShowcaseTitle,
        l10n.homeShowcaseSubtitle,
        AppRoutes.showcase,
      ),
      _HomeItem(
        Icons.person_outline,
        l10n.homeProfileTitle,
        l10n.homeProfileSubtitle,
        AppRoutes.profile,
      ),
      _HomeItem(
        Icons.settings_outlined,
        l10n.homeSettingsTitle,
        l10n.homeSettingsSubtitle,
        AppRoutes.settings,
      ),
    ];

    final columns = switch (context.windowSize) {
      WindowSize.compact => 1,
      WindowSize.medium => 2,
      WindowSize.expanded => 3,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: ResponsiveCenter(
        maxWidth: 1100,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeGreeting(name),
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(l10n.homeSubtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                // Wrap instead of a fixed-height grid so tiles grow with
                // text scale and translations.
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = AppSpacing.md;
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final item in items)
                          SizedBox(
                            width: width,
                            child: _HomeCard(item: item),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeItem {
  const _HomeItem(this.icon, this.title, this.subtitle, this.route);

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.item});

  final _HomeItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(item.route),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Icon(item.icon),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: theme.textTheme.titleMedium),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
