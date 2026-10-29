import 'package:flutter/foundation.dart';

import 'billing_manager.dart';
import 'billing_models.dart';

/// In-process [BillingManager] for the demo, tests and builds without a
/// store (web, unsigned debug builds). Purchases always succeed unless
/// [nextOutcome] says otherwise.
class FakeBillingManager implements BillingManager {
  FakeBillingManager({
    this.product = const ProProduct(
      id: 'pro',
      title: 'Pro',
      description: 'Remove ads and unlock everything',
      formattedPrice: r'$4.99',
    ),
    PurchaseState initialState = PurchaseState.notPurchased,
    this.latency = const Duration(milliseconds: 600),
  }) : _state = ValueNotifier(initialState);

  final ProProduct? product;
  final Duration latency;
  final ValueNotifier<PurchaseState> _state;
  final _product = ValueNotifier<ProProduct?>(null);

  /// Overrides the result of the next [purchasePro] call.
  PurchaseOutcome? nextOutcome;

  /// Whether [restorePurchases] finds a purchase.
  bool ownedInStore = false;

  @override
  ValueListenable<PurchaseState> get purchaseState => _state;

  @override
  ValueListenable<ProProduct?> get proProduct => _product;

  @override
  Future<void> initialize() async => _product.value = product;

  @override
  Future<PurchaseOutcome> purchasePro() async {
    if (_state.value == PurchaseState.purchased) {
      return const PurchaseAlreadyOwned();
    }
    await Future<void>.delayed(latency);
    final outcome = nextOutcome ?? const PurchaseSucceeded();
    nextOutcome = null;
    switch (outcome) {
      case PurchaseSucceeded():
        ownedInStore = true;
        _state.value = PurchaseState.purchased;
      case PurchasePending():
        _state.value = PurchaseState.pending;
      case PurchaseAlreadyOwned() || PurchaseCancelled() || PurchaseFailed():
        break;
    }
    return outcome;
  }

  @override
  Future<RestoreOutcome> restorePurchases() async {
    await Future<void>.delayed(latency);
    if (!ownedInStore) return RestoreOutcome.nothingToRestore;
    _state.value = PurchaseState.purchased;
    return RestoreOutcome.restored;
  }

  /// Demo helper: forget the purchase (like a refund).
  void reset() {
    ownedInStore = false;
    _state.value = PurchaseState.notPurchased;
  }

  @override
  Future<void> dispose() async {
    _state.dispose();
    _product.dispose();
  }
}
