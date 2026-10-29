import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'billing_models.dart';

/// Store transaction status, mirrored from the plugin so the billing logic
/// can be tested without it.
enum StoreTransactionStatus { pending, purchased, restored, error, canceled }

class StoreTransaction {
  const StoreTransaction({
    required this.productId,
    required this.status,
    this.needsCompletion = false,
    this.errorMessage,
    this.raw,
  });

  final String productId;
  final StoreTransactionStatus status;

  /// Must be acknowledged with [StoreGateway.complete], or the store refunds
  /// it (Play, after 3 days) / redelivers it (App Store).
  final bool needsCompletion;
  final String? errorMessage;

  /// The plugin object, passed back to [StoreGateway.complete].
  final Object? raw;
}

/// The handful of store calls billing needs. [InAppPurchaseGateway] is the
/// real one; tests use a fake.
abstract interface class StoreGateway {
  Stream<List<StoreTransaction>> get transactions;
  Future<bool> isAvailable();
  Future<ProProduct?> queryProduct(String productId);

  /// Starts the purchase sheet. Returns false if it could not start; the
  /// result arrives on [transactions].
  Future<bool> buyNonConsumable(String productId);
  Future<void> restore();
  Future<void> complete(StoreTransaction transaction);
}

/// [StoreGateway] over `in_app_purchase` (Play Billing / StoreKit).
class InAppPurchaseGateway implements StoreGateway {
  InAppPurchaseGateway([InAppPurchase? iap])
    : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  final Map<String, ProductDetails> _products = {};

  @override
  Stream<List<StoreTransaction>> get transactions =>
      _iap.purchaseStream.map((list) => [for (final p in list) _map(p)]);

  static StoreTransaction _map(PurchaseDetails p) => StoreTransaction(
    productId: p.productID,
    status: switch (p.status) {
      PurchaseStatus.pending => StoreTransactionStatus.pending,
      PurchaseStatus.purchased => StoreTransactionStatus.purchased,
      PurchaseStatus.restored => StoreTransactionStatus.restored,
      PurchaseStatus.error => StoreTransactionStatus.error,
      PurchaseStatus.canceled => StoreTransactionStatus.canceled,
    },
    needsCompletion: p.pendingCompletePurchase,
    errorMessage: p.error?.message,
    raw: p,
  );

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<ProProduct?> queryProduct(String productId) async {
    final response = await _iap.queryProductDetails({productId});
    final details = response.productDetails
        .where((d) => d.id == productId)
        .firstOrNull;
    if (details == null) return null;
    _products[productId] = details;
    return ProProduct(
      id: details.id,
      title: details.title,
      description: details.description,
      formattedPrice: details.price,
    );
  }

  @override
  Future<bool> buyNonConsumable(String productId) async {
    final details = _products[productId];
    if (details == null) return false;
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Future<void> complete(StoreTransaction transaction) async {
    final raw = transaction.raw;
    if (raw is PurchaseDetails) await _iap.completePurchase(raw);
  }
}
