import 'package:flutter/material.dart';
import 'package:pb_billing/pb_billing.dart';

import 'premium_controller.dart';

/// Marketing copy for the paywall. The product owns it; none ships here.
class PremiumContent {
  const PremiumContent({
    required this.title,
    required this.subtitle,
    required this.benefits,
    this.footnote,
  });

  final String title;
  final String subtitle;
  final List<String> benefits;

  /// Small print, e.g. "One-time purchase. No subscription."
  final String? footnote;
}

/// Paywall texts. Defaults are English; pass localized values from the app.
class PremiumLabels {
  const PremiumLabels({
    this.buy = _defaultBuy,
    this.unavailable = 'Not available right now',
    this.restore = 'Restore purchase',
    this.owned = 'You have Pro. Thank you!',
    this.pending = 'Payment pending. Pro unlocks when it completes.',
    this.message = _defaultMessage,
  });

  /// Purchase button text for a store-formatted price.
  final String Function(String price) buy;
  final String unavailable;
  final String restore;
  final String owned;
  final String pending;
  final String Function(PremiumMessage message) message;

  static String _defaultBuy(String price) => 'Get Pro for $price';

  static String _defaultMessage(PremiumMessage message) => switch (message) {
    PremiumMessage.purchaseCompleted => 'Welcome to Pro!',
    PremiumMessage.purchasePending => 'Payment pending.',
    PremiumMessage.alreadyOwned => 'You already own Pro.',
    PremiumMessage.restored => 'Purchase restored.',
    PremiumMessage.nothingToRestore => 'No previous purchase found.',
    PremiumMessage.couldNotCheck => "Couldn't reach the store. Try again.",
    PremiumMessage.failed => 'Purchase failed. You were not charged.',
  };
}

/// Benefits, store price, purchase and restore. Shows [PremiumMessage]s as
/// snackbars (needs a [ScaffoldMessenger] above it).
class PremiumView extends StatefulWidget {
  const PremiumView({
    super.key,
    required this.content,
    required this.controller,
    this.labels = const PremiumLabels(),
    this.header,
  });

  final PremiumContent content;
  final PremiumController controller;
  final PremiumLabels labels;

  /// Optional artwork above the title.
  final Widget? header;

  @override
  State<PremiumView> createState() => _PremiumViewState();
}

class _PremiumViewState extends State<PremiumView> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_showMessage);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_showMessage);
    super.dispose();
  }

  void _showMessage() {
    final message = widget.controller.state.message;
    if (message == null || !mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(widget.labels.message(message))));
    widget.controller.dismissMessage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = widget.content;
    final labels = widget.labels;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        final product = state.product;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ?widget.header,
            Icon(
              Icons.workspace_premium,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              content.title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              content.subtitle,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            for (final benefit in content.benefits)
              ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
                title: Text(benefit),
                contentPadding: EdgeInsets.zero,
              ),
            const SizedBox(height: 24),
            if (state.isOwned)
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    labels.owned,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              if (state.purchaseState == PurchaseState.pending)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(labels.pending, textAlign: TextAlign.center),
                ),
              FilledButton(
                onPressed: product == null || state.isWorking
                    ? null
                    : widget.controller.purchase,
                child: state.isWorking
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        product == null
                            ? labels.unavailable
                            : labels.buy(product.formattedPrice),
                      ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: state.isWorking ? null : widget.controller.restore,
                child: Text(labels.restore),
              ),
            ],
            if (content.footnote != null) ...[
              const SizedBox(height: 16),
              Text(
                content.footnote!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }
}
