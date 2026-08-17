import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/wearable_providers.dart';
import '../../../../core/wearable/wearable_connection_state.dart';
import '../../../../design_system/widgets/nocturne_tag.dart';

part 'connection_activity_controller.g.dart';

class ActivityEntry {
  ActivityEntry(this.time, this.label, this.tagLabel, this.tagVariant);

  final DateTime time;
  final String label;
  final String tagLabel;
  final NocturneTagVariant tagVariant;
}

/// The Controller for screen 03's "Recent activity" log — derives a
/// bounded (8-entry) history from [wearableConnectionProvider] transitions.
/// Lives as Riverpod state (not `StatefulWidget.setState`) so the log
/// persists across rebuilds the same way every other piece of app state
/// does, and so `ConnectionScreen` can be a plain `ConsumerWidget`.
@riverpod
class ConnectionActivity extends _$ConnectionActivity {
  WearableConnectionState? _lastLogged;

  @override
  List<ActivityEntry> build() {
    ref.listen(wearableConnectionProvider, (previous, next) {
      next.whenData(_log);
    });
    return [];
  }

  void _log(WearableConnectionState connectionState) {
    if (connectionState == _lastLogged) return;
    _lastLogged = connectionState;

    final (label, tagLabel, variant) = switch (connectionState) {
      WearableConnectionState.connected => ('Connected', 'OK', NocturneTagVariant.accent),
      WearableConnectionState.disconnected => ('Bluetooth lost', 'Disconnected', NocturneTagVariant.neutral),
      WearableConnectionState.connecting => ('Connecting', 'Connecting', NocturneTagVariant.outline),
      WearableConnectionState.reconnecting => ('Auto-retry started', 'Retrying', NocturneTagVariant.outline),
      WearableConnectionState.connectionFailed => ('Attempt failed', 'Failed', NocturneTagVariant.outline),
    };

    final entry = ActivityEntry(DateTime.now(), label, tagLabel, variant);
    state = [entry, ...state].take(8).toList();
  }
}
