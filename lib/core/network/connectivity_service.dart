import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_reporter.dart';

/// Network reachability.
///
/// `unknown` only before the first probe/report — UI treats it as online
/// (no banner) so cold start never flashes offline.
enum ConnectivityStatus { online, offline, unknown }

/// Kept for backwards compat — the monitor keeps it in sync so any
/// existing `ref.watch(connectivityProvider)` keeps working.
final connectivityProvider = StateProvider<ConnectivityStatus>(
  (ref) => ConnectivityStatus.unknown,
);

/// Simple connectivity abstraction (legacy, kept for compat).
class ConnectivityService {
  ConnectivityStatus _last = ConnectivityStatus.unknown;

  ConnectivityStatus get last => _last;

  void setOnline(bool online) {
    _last = online ? ConnectivityStatus.online : ConnectivityStatus.offline;
  }

  bool get isOffline => _last == ConnectivityStatus.offline;
  bool get isOnline => _last == ConnectivityStatus.online;
}

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

// ── Monitor (new source of truth) ────────────────────────────────────────────

/// State owned by [ConnectivityMonitor].
class ConnectivityState {
  /// Stable, debounced reachability.
  final ConnectivityStatus status;

  /// Transient "Back online — syncing…" pill. Set on offline→online,
  /// auto-cleared after [backOnlineVisibleFor] by the monitor.
  final bool showBackOnline;

  /// When the last transition happened (for UI + tests).
  final DateTime? lastChangedAt;

  const ConnectivityState({
    this.status = ConnectivityStatus.unknown,
    this.showBackOnline = false,
    this.lastChangedAt,
  });

  bool get isOffline => status == ConnectivityStatus.offline;

  /// Unknown counts as online for UI (never block cold start).
  bool get isEffectivelyOnline => status != ConnectivityStatus.offline;

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    bool? showBackOnline,
    DateTime? lastChangedAt,
  }) => ConnectivityState(
    status: status ?? this.status,
    showBackOnline: showBackOnline ?? this.showBackOnline,
    lastChangedAt: lastChangedAt ?? this.lastChangedAt,
  );
}

/// Debounced online/offline state machine.
///
/// Sources (no native plugin needed):
///  1. [ConnectivityReporter] — instant reports from ApiClient
///     successes/failures (first failed call ⇒ fast offline signal).
///  2. Periodic light ping (`onProbe`, wired by the app shell to
///     `ApiClient.ping`) every [probeInterval] as a backstop when the
///     app is idle (no requests flowing).
///
/// Debounce: 2 consecutive offline reports ⇒ offline; a single online
/// report ⇒ online immediately (snappy recovery). Offline→online sets
/// [ConnectivityState.showBackOnline] and fires [onReconnect] (sync +
/// refresh); the pill auto-hides after [backOnlineVisibleFor].
class ConnectivityMonitor extends StateNotifier<ConnectivityState> {
  static const probeInterval = Duration(seconds: 20);
  static const backOnlineVisibleFor = Duration(seconds: 4);
  static const failuresToGoOffline = 2;

  /// Returns true when the server is reachable. Wired to ApiClient.ping.
  Future<bool> Function()? onProbe;

  /// Fired once per offline→online transition (sync queue + refresh).
  Future<void> Function()? onReconnect;

  StreamSubscription<bool>? _sub;
  Timer? _probeTimer;
  Timer? _hideTimer;
  int _failures = 0;
  bool _disposed = false;

  ConnectivityMonitor({this.onProbe, this.onReconnect})
    : super(const ConnectivityState()) {
    _sub = ConnectivityReporter.instance.stream.listen(_onReport);
    _probeTimer = Timer.periodic(probeInterval, (_) => _probe());
    // First probe soon after start so `unknown` resolves fast.
    Future.microtask(_probe);
  }

  void _onReport(bool online) {
    if (_disposed) return;
    if (online) {
      _failures = 0;
      _setOnline();
    } else {
      _failures++;
      if (_failures >= failuresToGoOffline) _setOffline();
    }
  }

  Future<void> _probe() async {
    if (_disposed || onProbe == null) return;
    try {
      final ok = await onProbe!().timeout(const Duration(seconds: 8));
      _onReport(ok);
    } catch (_) {
      _onReport(false);
    }
  }

  /// Manual override (tests, pull-to-refresh errors, app resume).
  void reportOnline() => _onReport(true);
  void reportOffline() => _onReport(false);

  /// Attached once by the app shell (avoids provider creation cycles).
  void attach({
    Future<bool> Function()? onProbe,
    Future<void> Function()? onReconnect,
  }) {
    if (onProbe != null) this.onProbe = onProbe;
    if (onReconnect != null) this.onReconnect = onReconnect;
  }

  void _setOnline() {
    final wasOffline = state.isOffline;
    if (!wasOffline && state.status == ConnectivityStatus.online) {
      // Already online — just make sure the pill isn't stuck.
      if (state.showBackOnline) state = state.copyWith(showBackOnline: false);
      return;
    }
    _hideTimer?.cancel();
    state = state.copyWith(
      status: ConnectivityStatus.online,
      showBackOnline: wasOffline, // pill only when recovering
      lastChangedAt: DateTime.now(),
    );
    if (wasOffline) {
      // Fire-and-forget: sync queued mutations + refresh caches.
      Future(() async {
        try {
          await onReconnect?.call();
        } catch (_) {}
      });
      _hideTimer = Timer(backOnlineVisibleFor, () {
        if (!_disposed) state = state.copyWith(showBackOnline: false);
      });
    }
  }

  void _setOffline() {
    if (state.isOffline) return;
    _hideTimer?.cancel();
    state = state.copyWith(
      status: ConnectivityStatus.offline,
      showBackOnline: false,
      lastChangedAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _probeTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }
}

/// App-wide singleton. `onProbe`/`onReconnect` are attached once by the
/// app shell (router.dart) to avoid provider cycles at creation time.
final connectivityMonitorProvider =
    StateNotifierProvider<ConnectivityMonitor, ConnectivityState>(
      (ref) => ConnectivityMonitor(),
    );
