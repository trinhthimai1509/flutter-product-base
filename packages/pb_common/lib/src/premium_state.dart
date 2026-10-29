import 'dart:async';

/// Whether the user owns the product's premium entitlement.
enum PremiumStatus {
  /// Not known yet (store not queried). Treat as "not premium" for gating
  /// decisions, but do not show "you are free" messaging.
  unknown,
  premium,
  free,
}

/// The seam between "something sells premium" (pb_billing) and "something
/// reacts to premium" (pb_ads, product features). Neither side knows the
/// other; the app wires one [PremiumState] into both.
abstract interface class PremiumState {
  PremiumStatus get current;

  /// Emits on every change. Does not replay [current]; read it first.
  Stream<PremiumStatus> get changes;

  /// For apps that sell nothing: always [PremiumStatus.free].
  static const PremiumState alwaysFree = _ConstantPremiumState(
    PremiumStatus.free,
  );
}

class _ConstantPremiumState implements PremiumState {
  const _ConstantPremiumState(this.current);

  @override
  final PremiumStatus current;

  @override
  Stream<PremiumStatus> get changes => const Stream.empty();
}

/// Mutable [PremiumState] for tests, previews and demo toggles.
class FakePremiumState implements PremiumState {
  FakePremiumState([this._current = PremiumStatus.free]);

  final _controller = StreamController<PremiumStatus>.broadcast();
  PremiumStatus _current;

  @override
  PremiumStatus get current => _current;

  @override
  Stream<PremiumStatus> get changes => _controller.stream;

  set current(PremiumStatus value) {
    if (value == _current) return;
    _current = value;
    _controller.add(value);
  }

  Future<void> dispose() => _controller.close();
}
