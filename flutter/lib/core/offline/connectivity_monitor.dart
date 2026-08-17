import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper over `connectivity_plus`: a current snapshot plus a stream
/// of online/offline transitions. "Online" here means "has a network
/// interface up," not "can reach our API" — good enough to gate the sync
/// drain without adding a reachability ping.
class ConnectivityMonitor {
  ConnectivityMonitor() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = _isOnline(results);
      if (online == _lastKnown) return;
      _lastKnown = online;
      _controller.add(online);
    });
  }

  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool? _lastKnown;

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  Future<bool> isOnlineNow() async {
    final results = await Connectivity().checkConnectivity();
    return _isOnline(results);
  }

  /// Emits only on offline<->online transitions, not on every connectivity
  /// event (e.g. wifi -> cellular while already online is not a
  /// transition worth triggering a sync drain for).
  Stream<bool> get onTransition => _controller.stream;

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
