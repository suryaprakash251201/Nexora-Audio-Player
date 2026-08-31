import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline, unknown }

final connectivityProvider = StateProvider<ConnectivityStatus>((ref) => ConnectivityStatus.unknown);

/// Simple connectivity abstraction.
/// Without adding new native deps, we probe via lightweight HEAD request
/// or rely on Dio errors. For richer checks, add connectivity_plus later.
class ConnectivityService {
  ConnectivityStatus _last = ConnectivityStatus.unknown;

  ConnectivityStatus get last => _last;

  void setOnline(bool online) {
    _last = online ? ConnectivityStatus.online : ConnectivityStatus.offline;
  }

  bool get isOffline => _last == ConnectivityStatus.offline;
  bool get isOnline => _last == ConnectivityStatus.online;
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) => ConnectivityService());
