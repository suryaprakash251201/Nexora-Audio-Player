import 'dart:async';

/// Zero-dependency connectivity signal bus.
///
/// `ApiClient` (network layer) reports raw outcomes here; the
/// [ConnectivityMonitor] (state layer, in connectivity_service.dart)
/// subscribes and debounces them into stable online/offline state.
///
/// Split into its own file so `api_client.dart` can import it without
/// creating a provider/import cycle.
class ConnectivityReporter {
  ConnectivityReporter._();
  static final ConnectivityReporter instance = ConnectivityReporter._();

  final _controller = StreamController<bool>.broadcast();

  /// Raw network outcomes. `true` = a request just succeeded,
  /// `false` = a request just failed with no-internet/timeout.
  Stream<bool> get stream => _controller.stream;

  void reportOnline() {
    if (!_controller.isClosed) _controller.add(true);
  }

  void reportOffline() {
    if (!_controller.isClosed) _controller.add(false);
  }
}
