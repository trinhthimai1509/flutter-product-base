import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pb_common/pb_common.dart';

import 'billing_models.dart';
import 'store_gateway.dart';

/// One lifetime Pro purchase, behind a product-facing API. No plugin type
/// leaves this package.
///
/// Not included, deliberately: subscriptions, tiers, consumables and server
/// receipt verification.
abstract interface class BillingManager {
  ValueListenable<PurchaseState> get purchaseState;

  /// Null while loading, or when the product is not available.
  ValueListenable<ProProduct?> get proProduct;

  /// Subscribes to the store and loads the product. Call once at start-up.
  Future<void> initialize();

  Future<PurchaseOutcome> purchasePro();

  /// "Restore purchase". Also how a reinstall regains Pro.
  Future<RestoreOutcome> restorePurchases();

  Future<void> dispose();
}

/// [BillingManager] over a [StoreGateway] (in_app_purchase by default).
class StoreBillingManager implements BillingManager {
  StoreBillingManager({
    required this.config,
    StoreGateway? gateway,
    OwnershipCache? cache,
    this._logger = const NoOpPbLogger(),
  }) : _gateway = gateway ?? InAppPurchaseGateway(),
       _cache = cache ?? InMemoryOwnershipCache();

  final BillingConfig config;
  final StoreGateway _gateway;
  final OwnershipCache _cache;
  final PbLogger _logger;

  final _state = ValueNotifier(PurchaseState.unknown);
  final _product = ValueNotifier<ProProduct?>(null);
  StreamSubscription<List<StoreTransaction>>? _subscription;
  Completer<PurchaseOutcome>? _purchase;
  Completer<RestoreOutcome>? _restore;
  bool _available = false;

  @override
  ValueListenable<PurchaseState> get purchaseState => _state;

  @override
  ValueListenable<ProProduct?> get proProduct => _product;

  String get _productId => config.proProductId;

  @override
  Future<void> initialize() async {
    if (_cache.owned ?? false) _state.value = PurchaseState.purchased;
    _subscription ??= _gateway.transactions.listen(
      _onTransactions,
      onError: (Object error) => _logger.warning(
        'Purchase stream error',
        tag: 'billing',
        error: error,
      ),
    );
    try {
      _available = await _gateway.isAvailable();
      if (!_available) {
        _logger.info('Store unavailable', tag: 'billing');
        return;
      }
      _product.value = await _gateway.queryProduct(_productId);
      if (_product.value == null) {
        _logger.warning('Product $_productId not found', tag: 'billing');
      }
      final restoreOnStart =
          config.restoreOnStart ??
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
      if (restoreOnStart) await restorePurchases();
    } on Object catch (error) {
      _logger.warning('Billing init failed', tag: 'billing', error: error);
    }
  }

  Future<void> _onTransactions(List<StoreTransaction> transactions) async {
    for (final t in transactions) {
      if (t.productId != _productId) continue;
      switch (t.status) {
        case StoreTransactionStatus.purchased:
        case StoreTransactionStatus.restored:
          await _setOwned(true);
          _finishPurchase(const PurchaseSucceeded());
          _finishRestore(RestoreOutcome.restored);
        case StoreTransactionStatus.pending:
          if (_state.value != PurchaseState.purchased) {
            _state.value = PurchaseState.pending;
          }
          _finishPurchase(const PurchasePending());
        case StoreTransactionStatus.canceled:
          if (_state.value == PurchaseState.pending) {
            _state.value = PurchaseState.notPurchased;
          }
          _finishPurchase(const PurchaseCancelled());
        case StoreTransactionStatus.error:
          _logger.warning('Purchase error: ${t.errorMessage}', tag: 'billing');
          _finishPurchase(
            PurchaseFailed(BillingError.purchaseFailed, t.errorMessage),
          );
      }
      if (t.needsCompletion) {
        try {
          await _gateway.complete(t);
        } on Object catch (error) {
          _logger.error(
            'Could not complete purchase',
            tag: 'billing',
            error: error,
          );
        }
      }
    }
  }

  Future<void> _setOwned(bool owned) async {
    _state.value = owned ? PurchaseState.purchased : PurchaseState.notPurchased;
    await _cache.save(owned);
  }

  void _finishPurchase(PurchaseOutcome outcome) {
    final completer = _purchase;
    if (completer != null && !completer.isCompleted) {
      completer.complete(outcome);
    }
  }

  void _finishRestore(RestoreOutcome outcome) {
    final completer = _restore;
    if (completer != null && !completer.isCompleted) {
      completer.complete(outcome);
    }
  }

  @override
  Future<PurchaseOutcome> purchasePro() async {
    if (_state.value == PurchaseState.purchased) {
      return const PurchaseAlreadyOwned();
    }
    final running = _purchase;
    if (running != null && !running.isCompleted) return running.future;
    try {
      if (!_available && !(_available = await _gateway.isAvailable())) {
        return const PurchaseFailed(BillingError.storeUnavailable);
      }
      _product.value ??= await _gateway.queryProduct(_productId);
      if (_product.value == null) {
        return const PurchaseFailed(BillingError.productUnavailable);
      }
      final completer = _purchase = Completer<PurchaseOutcome>();
      if (!await _gateway.buyNonConsumable(_productId)) {
        _finishPurchase(const PurchaseFailed(BillingError.purchaseFailed));
      }
      return await completer.future.timeout(
        config.purchaseTimeout,
        onTimeout: () => const PurchaseFailed(BillingError.timeout),
      );
    } on Object catch (error) {
      _logger.warning('Purchase failed', tag: 'billing', error: error);
      return PurchaseFailed(BillingError.purchaseFailed, '$error');
    }
  }

  @override
  Future<RestoreOutcome> restorePurchases() async {
    final running = _restore;
    if (running != null && !running.isCompleted) return running.future;
    final completer = _restore = Completer<RestoreOutcome>();
    try {
      if (!_available && !(_available = await _gateway.isAvailable())) {
        _finishRestore(RestoreOutcome.failed);
        return RestoreOutcome.failed;
      }
      await _gateway.restore();
    } on Object catch (error) {
      _logger.warning('Restore failed', tag: 'billing', error: error);
      _finishRestore(RestoreOutcome.failed);
      return RestoreOutcome.failed;
    }
    // Stores send nothing when there is nothing to restore, so silence for
    // [restoreTimeout] means "not owned". A cached purchase is kept: a slow
    // network must not take Pro away from a paying user.
    final outcome = await completer.future.timeout(
      config.restoreTimeout,
      onTimeout: () => RestoreOutcome.nothingToRestore,
    );
    if (outcome == RestoreOutcome.nothingToRestore &&
        _state.value == PurchaseState.unknown) {
      _state.value = PurchaseState.notPurchased;
    }
    _finishRestore(outcome);
    return outcome;
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _state.dispose();
    _product.dispose();
  }
}

/// [PremiumState] driven by a [BillingManager]: premium means "owns Pro".
class BillingPremiumState implements PremiumState {
  BillingPremiumState(this._billing) {
    _last = current;
    _billing.purchaseState.addListener(_onChanged);
  }

  final BillingManager _billing;
  final _changes = StreamController<PremiumStatus>.broadcast();
  late PremiumStatus _last;

  @override
  PremiumStatus get current => switch (_billing.purchaseState.value) {
    PurchaseState.purchased => PremiumStatus.premium,
    PurchaseState.unknown => PremiumStatus.unknown,
    PurchaseState.notPurchased || PurchaseState.pending => PremiumStatus.free,
  };

  @override
  Stream<PremiumStatus> get changes => _changes.stream;

  void _onChanged() {
    final next = current;
    if (next == _last) return;
    _last = next;
    _changes.add(next);
  }

  Future<void> dispose() async {
    _billing.purchaseState.removeListener(_onChanged);
    await _changes.close();
  }
}
