import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/providers/wearable_providers.dart';
import '../../core/wearable/reconnect_status.dart';
import '../../core/wearable/wearable_connection_state.dart';
import '../../design_system/nocturne.dart';

class _ActivityEntry {
  _ActivityEntry(this.time, this.label, this.tagLabel, this.tagVariant);
  final DateTime time;
  final String label;
  final String tagLabel;
  final NocturneTagVariant tagVariant;
}

/// Screen 03 · Connection states.
class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final List<_ActivityEntry> _activity = [];
  WearableConnectionState? _lastLogged;

  void _log(WearableConnectionState state) {
    if (state == _lastLogged) return;
    _lastLogged = state;

    final (label, tagLabel, variant) = switch (state) {
      WearableConnectionState.connected => ('Connected', 'OK', NocturneTagVariant.accent),
      WearableConnectionState.disconnected => ('Bluetooth lost', 'Disconnected', NocturneTagVariant.neutral),
      WearableConnectionState.connecting => ('Connecting', 'Connecting', NocturneTagVariant.outline),
      WearableConnectionState.reconnecting => ('Auto-retry started', 'Retrying', NocturneTagVariant.outline),
      WearableConnectionState.connectionFailed => ('Attempt failed', 'Failed', NocturneTagVariant.outline),
    };

    setState(() {
      _activity.insert(0, _ActivityEntry(DateTime.now(), label, tagLabel, variant));
      if (_activity.length > 8) _activity.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionAsync = ref.watch(wearableConnectionProvider);
    final reconnectAsync = ref.watch(wearableReconnectStatusProvider);

    ref.listen(wearableConnectionProvider, (previous, next) {
      next.whenData(_log);
    });

    final state = connectionAsync.valueOrNull ?? WearableConnectionState.disconnected;
    final reconnectStatus = reconnectAsync.valueOrNull;

    return Scaffold(
      backgroundColor: NocturneColors.bg,
      appBar: AppBar(
        backgroundColor: NocturneColors.bg,
        title: Text('Device Connection', style: NocturneType.h4),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            NocturneCard(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  _StatusIndicator(state: state),
                  const SizedBox(height: 10),
                  Text(_statusTitle(state), style: NocturneType.h5),
                  const SizedBox(height: 4),
                  Text(
                    _statusSubtitle(state, reconnectStatus),
                    style: NocturneType.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  NocturneButton(
                    label: 'Reconnect now',
                    variant: NocturneButtonVariant.secondary,
                    icon: const Icon(PhosphorIconsRegular.arrowClockwise),
                    onPressed: () => ref.read(wearableServiceProvider).reconnect(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const NocturneCardKicker('Recent activity'),
            const SizedBox(height: 4),
            if (_activity.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No activity yet', style: NocturneType.caption),
              )
            else
              for (final entry in _activity) _ActivityRow(entry: entry),
            const SizedBox(height: 8),
            Text(
              'Exponential backoff: 2s, 4s, 8s, 16s, then manual reconnect only.',
              style: NocturneType.micro,
            ),
          ],
        ),
      ),
    );
  }

  static String _statusTitle(WearableConnectionState state) {
    return switch (state) {
      WearableConnectionState.connected => 'Connected',
      WearableConnectionState.disconnected => 'Disconnected',
      WearableConnectionState.connecting => 'Connecting…',
      WearableConnectionState.reconnecting => 'Reconnecting…',
      WearableConnectionState.connectionFailed => 'Connection failed',
    };
  }

  static String _statusSubtitle(
    WearableConnectionState state,
    ReconnectStatus? reconnectStatus,
  ) {
    if (state == WearableConnectionState.reconnecting && reconnectStatus != null) {
      return 'Attempt ${reconnectStatus.attempt} of ${reconnectStatus.maxAttempts} · retrying in ${reconnectStatus.retryInSeconds}s';
    }
    return switch (state) {
      WearableConnectionState.connected => 'Streaming live vitals',
      WearableConnectionState.disconnected => 'Tap reconnect to pair the device',
      WearableConnectionState.connecting => 'Pairing with FITRING-001',
      WearableConnectionState.connectionFailed => 'Auto-retry gave up — reconnect manually',
      WearableConnectionState.reconnecting => '',
    };
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.state});

  final WearableConnectionState state;

  @override
  Widget build(BuildContext context) {
    final busy = state == WearableConnectionState.connecting ||
        state == WearableConnectionState.reconnecting;

    if (busy) {
      return const SizedBox(
        width: 52,
        height: 52,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: NocturneColors.accent300,
        ),
      );
    }

    final connected = state == WearableConnectionState.connected;
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: connected ? NocturneColors.accent300 : NocturneColors.neutral600,
          width: 3,
        ),
      ),
      child: Icon(
        connected ? PhosphorIconsFill.bluetoothConnected : PhosphorIconsRegular.bluetoothSlash,
        color: connected ? NocturneColors.accent300 : NocturneColors.neutral400,
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final _ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = entry.time;
    final timeLabel =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NocturneColors.neutral800)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$timeLabel — ${entry.label}', style: NocturneType.bodySmall),
          NocturneTag(label: entry.tagLabel, variant: entry.tagVariant),
        ],
      ),
    );
  }
}
