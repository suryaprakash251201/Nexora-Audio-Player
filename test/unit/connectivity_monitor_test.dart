import 'package:flutter_test/flutter_test.dart';

import 'package:nexora_flutter/core/network/connectivity_service.dart';

void main() {
  group('ConnectivityMonitor', () {
    test('starts unknown, effectively online (no cold-start flash)', () {
      final m = ConnectivityMonitor();
      expect(m.state.status, ConnectivityStatus.unknown);
      expect(m.state.isEffectivelyOnline, isTrue);
      expect(m.state.showBackOnline, isFalse);
      m.dispose();
    });

    test('needs 2 failures to go offline (debounce)', () {
      final m = ConnectivityMonitor();
      m.reportOffline();
      expect(m.state.isOffline, isFalse);
      m.reportOffline();
      expect(m.state.isOffline, isTrue);
      expect(m.state.showBackOnline, isFalse);
      m.dispose();
    });

    test('offline→online shows back-online pill then hides', () async {
      var reconnects = 0;
      final m = ConnectivityMonitor(onReconnect: () async => reconnects++);
      m.reportOffline();
      m.reportOffline();
      expect(m.state.isOffline, isTrue);
      m.reportOnline();
      expect(m.state.status, ConnectivityStatus.online);
      expect(m.state.showBackOnline, isTrue);
      // onReconnect fires async
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(reconnects, 1);
      m.dispose();
    });

    test('online report without prior offline shows no pill', () {
      final m = ConnectivityMonitor();
      m.reportOnline();
      expect(m.state.status, ConnectivityStatus.online);
      expect(m.state.showBackOnline, isFalse);
      m.dispose();
    });
  });
}
