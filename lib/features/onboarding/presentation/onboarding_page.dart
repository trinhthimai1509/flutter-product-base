import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_onboarding/pb_onboarding.dart' as pb;

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/responsive.dart';
import '../application/onboarding_providers.dart';

/// First-launch introduction. The router leaves this page by itself once
/// the controller reports completion; replace the pages with your product's.
class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    Widget art(IconData icon) => CircleAvatar(
      radius: 64,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: Icon(icon, size: 64),
    );

    return Scaffold(
      body: ResponsiveCenter(
        child: pb.OnboardingView(
          controller: ref.watch(onboardingControllerProvider),
          labels: pb.OnboardingLabels(
            skip: l10n.onboardingSkip,
            next: l10n.onboardingNext,
            finish: l10n.onboardingFinish,
            pageIndicator: l10n.onboardingPageIndicator,
          ),
          pages: [
            pb.OnboardingPage(
              title: l10n.onboardingPage1Title,
              description: l10n.onboardingPage1Body,
              illustration: art(Icons.foundation),
            ),
            pb.OnboardingPage(
              title: l10n.onboardingPage2Title,
              description: l10n.onboardingPage2Body,
              illustration: art(Icons.extension_outlined),
            ),
            pb.OnboardingPage(
              title: l10n.onboardingPage3Title,
              description: l10n.onboardingPage3Body,
              illustration: art(Icons.cloud_off_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
