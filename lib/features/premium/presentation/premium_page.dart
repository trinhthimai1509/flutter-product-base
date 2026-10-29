import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_premium/pb_premium.dart';

import '../../../core/capabilities/capability_providers.dart';
import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/responsive.dart';

/// Paywall for the single Pro purchase. Copy is the product's: edit the
/// benefits to match what Pro actually unlocks in your app.
class PremiumPage extends ConsumerStatefulWidget {
  const PremiumPage({super.key});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> {
  late final PremiumController _controller = PremiumController(
    ref.read(billingManagerProvider),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.premiumTitle)),
      body: ResponsiveCenter(
        child: PremiumView(
          controller: _controller,
          content: PremiumContent(
            title: l10n.premiumHeadline,
            subtitle: l10n.premiumSubtitle,
            benefits: [
              l10n.premiumBenefitNoAds,
              l10n.premiumBenefitFeatures,
              l10n.premiumBenefitSupport,
            ],
            footnote: l10n.premiumFootnote,
          ),
          labels: PremiumLabels(
            buy: l10n.premiumBuy,
            unavailable: l10n.premiumUnavailable,
            restore: l10n.premiumRestore,
            owned: l10n.premiumOwned,
            pending: l10n.premiumPending,
            message: (message) => switch (message) {
              PremiumMessage.purchaseCompleted => l10n.premiumMsgCompleted,
              PremiumMessage.purchasePending => l10n.premiumMsgPending,
              PremiumMessage.alreadyOwned => l10n.premiumMsgAlreadyOwned,
              PremiumMessage.restored => l10n.premiumMsgRestored,
              PremiumMessage.nothingToRestore =>
                l10n.premiumMsgNothingToRestore,
              PremiumMessage.couldNotCheck => l10n.premiumMsgCouldNotCheck,
              PremiumMessage.failed => l10n.premiumMsgFailed,
            },
          ),
        ),
      ),
    );
  }
}
