import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../design_system/nocturne.dart';

/// Screen 05 · Offline sync.
///
/// UI shell only — the local sync queue (SQLite-backed offline storage,
/// connectivity-triggered flush to `POST /health/readings`) is paused
/// pending a separate build pass, so this renders an honest empty state
/// rather than fabricated queue data. Once that engine lands, wire this to
/// its queue stream the same way [ConnectionScreen] wires to
/// [wearableConnectionProvider].
class SyncStatusScreen extends StatelessWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NocturneColors.bg,
      appBar: AppBar(
        backgroundColor: NocturneColors.bg,
        title: Text('Sync Status', style: NocturneType.h4),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            NocturneCard(
              borderColor: NocturneColors.accent700,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  const Icon(
                    PhosphorIconsRegular.cloudSlash,
                    color: NocturneColors.accent300,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Offline queue not wired up yet', style: NocturneType.bodyMedium),
                        Text(
                          'Local storage + sync queue is a separate, pending build pass.',
                          style: NocturneType.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const NocturneCardKicker('Sync queue'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Queued readings will appear here once offline storage '
                  'is implemented.',
                  style: NocturneType.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            NocturneButton(
              label: 'Retry failed',
              variant: NocturneButtonVariant.secondary,
              block: true,
              icon: const Icon(PhosphorIconsRegular.arrowClockwise),
              onPressed: null,
            ),
            const SizedBox(height: 8),
            Text(
              'Each reading carries a client-generated id locally; the '
              'backend itself dedupes on (deviceId, timestamp) — see '
              'docs/API_GAPS.md.',
              style: NocturneType.micro,
            ),
          ],
        ),
      ),
    );
  }
}
