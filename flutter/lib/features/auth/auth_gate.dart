import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/nocturne_colors.dart';
import '../shell/root_shell.dart';
import 'auth_provider.dart';
import 'auth_state.dart';
import 'login_screen.dart';

/// Splash → Login → RootShell, driven entirely by [authProvider].
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).restoreSession());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          backgroundColor: NocturneColors.bg,
          body: Center(
            child: CircularProgressIndicator(color: NocturneColors.accent),
          ),
        );
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        return RootShell(userId: auth.user!.id);
    }
  }
}
