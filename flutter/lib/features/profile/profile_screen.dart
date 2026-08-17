import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/providers/wearable_providers.dart';
import '../../design_system/nocturne.dart';
import '../auth/auth_provider.dart';
import '../connection/connection_screen.dart';

/// Screen 11 · Settings / Profile.
///
/// The backend's `users` table has no display-name column — see
/// docs/API_GAPS.md — so the avatar initials and name are derived from
/// the email locally ([AppUser.displayName]/[AppUser.initials]).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final deviceId = ref.watch(wearableServiceProvider).deviceId;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Profile', style: NocturneType.h4),
          const SizedBox(height: 16),
          NocturneCard(
            child: Row(
              spacing: 12,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: NocturneColors.accent800,
                  child: Text(
                    user?.initials ?? '?',
                    style: const TextStyle(
                      color: NocturneColors.accent300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? '',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: NocturneColors.text),
                    ),
                    Text(user?.email ?? '', style: NocturneType.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _ProfileRow(
            label: 'Connected device',
            trailing: deviceId,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConnectionScreen()),
            ),
          ),
          const _ProfileRow(label: 'Notifications'),
          const _ProfileRow(label: 'Account'),
          const _ProfileRow(label: 'Privacy', showDivider: false),
          const SizedBox(height: 16),
          NocturneButton(
            label: 'Log out',
            variant: NocturneButtonVariant.secondary,
            block: true,
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: NocturneColors.neutral800)),
              )
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: NocturneType.bodySmall),
            Row(
              spacing: 6,
              children: [
                if (trailing != null) Text(trailing!, style: NocturneType.caption),
                const Icon(PhosphorIconsRegular.caretRight, size: 14, color: NocturneColors.text),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
