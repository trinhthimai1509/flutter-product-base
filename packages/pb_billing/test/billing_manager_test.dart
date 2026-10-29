import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pb_billing/pb_billing.dart';
import 'package:pb_common/pb_common.dart';

const _product = ProProduct(
  id: 'pro',
  title: 'Pro',
  description: 'All features',
  formattedPrice: '49.000 ₫',
);

class _FakeGateway implements StoreGateway {
  final controller = StreamController<List<StoreTransaction>>.broadcast();
  bool available = true;
  ProProduct? product = _product;
  bool startPurchase = true;
  List<StoreTransaction>? onBuy;
  List<StoreTransaction>? onRestore;
  final completed = <StoreTransaction>[];
  int restoreCalls = 0;

  @override
  Stream<List<StoreTransaction>> get transactions => controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProProduct?> queryProduct(String productId) async => product;

  @override
  Future<bool> buyNonConsumable(String productId) async {
    if (!startPurchase) return false;
    final events = onBuy;
    if (events != null) scheduleMicrotask(() => controller.add(events));
    return true;
  }

  @override
  Future<void> restore() async {
    restoreCalls++;
    final events = onRestore;
    if (events != null) scheduleMicrotask(() => controller.add(events));
  }

  @override
  Future<void> complete(StoreTransaction transaction) async =>
      completed.add(transaction);
}

StoreTransaction _tx(StoreTransactionStatus status, {bool complete = false}) =>
    StoreTransaction(
      productId: 'pro',
      status: status,
      needsCompletion: complete,
    );

void main() {
  late _FakeGateway gateway;
  late InMemoryOwnershipCache cache;

  StoreBillingManager manager({bool restoreOnStart = false}) {
    final m = StoreBillingManager(
      config: BillingConfig(
        proProductId: 'pro',
        restoreOnStart: restoreOnStart,
        restoreTimeout: const Duration(milliseconds: 50),
      ),
      gateway: gateway,
      cache: cache,
    );
    addTearDown(m.dispose);
    return m;
  }

  setUp(() {
    gateway = _FakeGateway();
    cache = InMemoryOwnershipCache();
  });

  test('initialize loads the product; state stays unknown', () async {
    final m = manager();
    await m.initialize();
    expect(m.proProduct.value?.formattedPrice, '49.000 ₫');
    expect(m.purchaseState.value, PurchaseState.unknown);
  });

  test('a cached purchase is applied before the store answers', () async {
    cache.owned = true;
    gateway.available = false;
    final m = manager();
    await m.initialize();
    expect(m.purchaseState.value, PurchaseState.purchased);
  });

  test('successful purchase owns Pro, caches it and completes it', () async {
    gateway.onBuy = [_tx(StoreTransactionStatus.purchased, complete: true)];
    final m = manager();
    await m.initialize();

    final outcome = await m.purchasePro();
    expect(outcome, isA<PurchaseSucceeded>());
    expect(m.purchaseState.value, PurchaseState.purchased);
    expect(cache.owned, isTrue);
    expect(gateway.completed, hasLength(1));

    expect(await m.purchasePro(), isA<PurchaseAlreadyOwned>());
  });

  test('cancel and error map to outcomes', () async {
    final m = manager();
    await m.initialize();

    gateway.onBuy = [_tx(StoreTransactionStatus.canceled)];
    expect(await m.purchasePro(), isA<PurchaseCancelled>());

    gateway.onBuy = [_tx(StoreTransactionStatus.error)];
    final failed = await m.purchasePro();
    expect((failed as PurchaseFailed).error, BillingError.purchaseFailed);
  });

  test('pending purchase marks the state pending', () async {
    gateway.onBuy = [_tx(StoreTransactionStatus.pending)];
    final m = manager();
    await m.initialize();
    expect(await m.purchasePro(), isA<PurchasePending>());
    expect(m.purchaseState.value, PurchaseState.pending);
  });

  test('missing product and missing store fail without a sheet', () async {
    gateway.product = null;
    final m = manager();
    await m.initialize();
    final noProduct = await m.purchasePro() as PurchaseFailed;
    expect(noProduct.error, BillingError.productUnavailable);

    gateway.available = false;
    final m2 = manager();
    await m2.initialize();
    final noStore = await m2.purchasePro() as PurchaseFailed;
    expect(noStore.error, BillingError.storeUnavailable);
  });

  test('restore: found, nothing, and store unavailable', () async {
    gateway.onRestore = [_tx(StoreTransactionStatus.restored)];
    final m = manager();
    await m.initialize();
    expect(await m.restorePurchases(), RestoreOutcome.restored);
    expect(m.purchaseState.value, PurchaseState.purchased);

    gateway.onRestore = null;
    cache = InMemoryOwnershipCache();
    final m2 = manager();
    await m2.initialize();
    expect(await m2.restorePurchases(), RestoreOutcome.nothingToRestore);
    expect(m2.purchaseState.value, PurchaseState.notPurchased);

    gateway.available = false;
    final m3 = manager();
    await m3.initialize();
    expect(await m3.restorePurchases(), RestoreOutcome.failed);
  });

  test('restoreOnStart queries ownership during initialize', () async {
    final m = manager(restoreOnStart: true);
    await m.initialize();
    expect(gateway.restoreCalls, 1);
    expect(m.purchaseState.value, PurchaseState.notPurchased);
  });

  test('BillingPremiumState follows the purchase state', () async {
    final billing = FakeBillingManager(latency: Duration.zero);
    addTearDown(billing.dispose);
    final premium = BillingPremiumState(billing);
    addTearDown(premium.dispose);
    final emitted = <PremiumStatus>[];
    final sub = premium.changes.listen(emitted.add);
    addTearDown(sub.cancel);

    expect(premium.current, PremiumStatus.free);
    await billing.purchasePro();
    await pumpEventQueue();
    expect(premium.current, PremiumStatus.premium);
    expect(emitted, [PremiumStatus.premium]);
  });
}
