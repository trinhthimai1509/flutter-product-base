import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Whether the device has a usable network interface.
///
/// This is a *hint* for the UI ("you're offline"), not a guarantee that a
/// request will succeed: a captive portal or a dead backend still looks
/// online. Requests must handle network failures on their own.
abstract interface class NetworkMonitor {
  Future<bool> isOnline();

  /// Emits on every change (distinct). Does not replay the current value;
  /// call [isOnline] first.
  Stream<bool> get onStatusChange;
}

/// [NetworkMonitor] backed by `connectivity_plus`.
class ConnectivityPlusNetworkMonitor implements NetworkMonitor {
  ConnectivityPlusNetworkMonitor([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _online(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async {
    try {
      return _online(await _connectivity.checkConnectivity());
    } on Object {
      // Unsupported platform or plugin failure: do not block the UI.
      return true;
    }
  }

  @override
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_online).distinct();
}

/// Manually driven [NetworkMonitor] for tests and previews.
class FakeNetworkMonitor implements NetworkMonitor {
  // ignore: prefer_initializing_formals
  FakeNetworkMonitor({bool online = true}) : _online = online;

  final _controller = StreamController<bool>.broadcast();
  bool _online;

  bool get online => _online;

  set online(bool value) {
    if (value == _online) return;
    _online = value;
    _controller.add(value);
  }

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<bool> get onStatusChange => _controller.stream;

  Future<void> dispose() => _controller.close();
}
