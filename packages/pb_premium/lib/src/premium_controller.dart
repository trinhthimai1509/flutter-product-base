import 'package:flutter/foundation.dart';
import 'package:pb_billing/pb_billing.dart';

/// A one-shot result to show to the user, then dismiss.
enum PremiumMessage {
  purchaseCompleted,
  purchasePending,
  alreadyOwned,
  restored,
  nothingToRestore,
  couldNotCheck,
  failed,
}

@immutable
class PremiumUiState {
  const PremiumUiState({
    this.purchaseState = PurchaseState.unknown,
    this.product,
    this.isWorking = false,
    this.message,
  });

  final PurchaseState purchaseState;
  final ProProduct? product;
  final bool isWorking;
  final PremiumMessage? message;

  bool get isOwned => purchaseState == PurchaseState.purchased;

  PremiumUiState copyWith({
    PurchaseState? purchaseState,
    ProProduct? Function()? product,
    bool? isWorking,
    PremiumMessage? Function()? message,
  }) => PremiumUiState(
    purchaseState: purchaseState ?? this.purchaseState,
    product: product == null ? this.product : product(),
    isWorking: isWorking ?? this.isWorking,
    message: message == null ? this.message : message(),
  );
}

/// Paywall state over a [BillingManager]: purchase, restore, messages.
class PremiumController extends ChangeNotifier {
  PremiumController(this._billing)
    : _state = PremiumUiState(
        purchaseState: _billing.purchaseState.value,
        product: _billing.proProduct.value,
      ) {
    _billing.purchaseState.addListener(_onBilling);
    _billing.proProduct.addListener(_onBilling);
  }

  final BillingManager _billing;
  PremiumUiState _state;

  PremiumUiState get state => _state;

  void _set(PremiumUiState next) {
    _state = next;
    notifyListeners();
  }

  void _onBilling() => _set(
    _state.copyWith(
      purchaseState: _billing.purchaseState.value,
      product: () => _billing.proProduct.value,
    ),
  );

  Future<void> purchase() async {
    if (_state.isWorking) return;
    _set(_state.copyWith(isWorking: true));
    final outcome = await _billing.purchasePro();
    final message = switch (outcome) {
      PurchaseSucceeded() => PremiumMessage.purchaseCompleted,
      PurchasePending() => PremiumMessage.purchasePending,
      PurchaseAlreadyOwned() => PremiumMessage.alreadyOwned,
      // The user backed out on purpose; saying anything is noise.
      PurchaseCancelled() => null,
      PurchaseFailed() => PremiumMessage.failed,
    };
    _set(_state.copyWith(isWorking: false, message: () => message));
  }

  Future<void> restore() async {
    if (_state.isWorking) return;
    _set(_state.copyWith(isWorking: true));
    final outcome = await _billing.restorePurchases();
    final message = switch (outcome) {
      RestoreOutcome.restored => PremiumMessage.restored,
      RestoreOutcome.nothingToRestore => PremiumMessage.nothingToRestore,
      RestoreOutcome.failed => PremiumMessage.couldNotCheck,
    };
    _set(_state.copyWith(isWorking: false, message: () => message));
  }

  void dismissMessage() {
    if (_state.message == null) return;
    _set(_state.copyWith(message: () => null));
  }

  @override
  void dispose() {
    _billing.purchaseState.removeListener(_onBilling);
    _billing.proProduct.removeListener(_onBilling);
    super.dispose();
  }
}
