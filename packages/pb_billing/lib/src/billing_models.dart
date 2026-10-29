/// Ownership of the Pro product, as far as the store has told us.
enum PurchaseState {
  /// Not checked yet (or the store is unreachable and nothing is cached).
  unknown,
  notPurchased,

  /// Paid with a slow method (cash, bank transfer); not owned yet.
  pending,
  purchased,
}

/// The single lifetime "Pro / remove ads" product, as the store describes it.
class ProProduct {
  const ProProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.formattedPrice,
  });

  final String id;
  final String title;
  final String description;

  /// Localized by the store (currency, format). Never format or hardcode a
  /// price yourself.
  final String formattedPrice;
}

enum BillingError {
  /// Store app missing, signed out, or billing disabled on this device.
  storeUnavailable,

  /// The product id is not configured/active in the store console (or this
  /// build is not signed/installed the way the store requires).
  productUnavailable,

  /// The store reported an error for this purchase.
  purchaseFailed,

  /// The store did not answer in time.
  timeout,
}

sealed class PurchaseOutcome {
  const PurchaseOutcome();
}

final class PurchaseSucceeded extends PurchaseOutcome {
  const PurchaseSucceeded();
}

final class PurchasePending extends PurchaseOutcome {
  const PurchasePending();
}

final class PurchaseAlreadyOwned extends PurchaseOutcome {
  const PurchaseAlreadyOwned();
}

final class PurchaseCancelled extends PurchaseOutcome {
  const PurchaseCancelled();
}

final class PurchaseFailed extends PurchaseOutcome {
  const PurchaseFailed(this.error, [this.message]);

  final BillingError error;

  /// Store-provided detail, for logs only (not localized).
  final String? message;
}

enum RestoreOutcome {
  /// Ownership was found and applied.
  restored,

  /// The store answered and has no Pro purchase for this account.
  nothingToRestore,

  /// The store could not be reached.
  failed,
}

/// Configuration for one non-consumable Pro product.
class BillingConfig {
  const BillingConfig({
    required this.proProductId,
    this.restoreTimeout = const Duration(seconds: 8),
    this.purchaseTimeout = const Duration(minutes: 10),
    this.restoreOnStart,
  });

  /// Same id in Play Console and App Store Connect keeps code simple.
  final String proProductId;

  /// How long [BillingManager.restorePurchases] waits for the store.
  final Duration restoreTimeout;

  /// Upper bound for a purchase flow (the user may sit on the sheet).
  final Duration purchaseTimeout;

  /// Query ownership silently at start-up. Defaults to Android only: on iOS
  /// a restore can prompt for the Apple ID password, so it must be a user
  /// action ("Restore purchase"). Use an [OwnershipCache] to remember a
  /// purchase across launches on iOS.
  final bool? restoreOnStart;
}

/// Remembers the last known ownership so the app does not flash ads or a
/// paywall before the store answers (and on iOS, across launches).
///
/// This is a UX cache, not an entitlement check: anyone with root access can
/// flip it. Verify receipts on a server if that matters to your product.
abstract interface class OwnershipCache {
  bool? get owned;
  Future<void> save(bool owned);
}

class InMemoryOwnershipCache implements OwnershipCache {
  InMemoryOwnershipCache([this.owned]);

  @override
  bool? owned;

  @override
  Future<void> save(bool owned) async => this.owned = owned;
}
