import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/localization/l10n.dart';
import '../shared/widgets/state_views.dart';
import 'router/app_routes.dart';

/// Shown while the session is being restored.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flutter_dash,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: EmptyView(
        icon: Icons.explore_off_outlined,
        title: l10n.notFoundTitle,
        message: l10n.notFoundMessage,
        action: FilledButton(
          onPressed: () => context.go(AppRoutes.home),
          child: Text(l10n.notFoundGoHome),
        ),
      ),
    );
  }
}
