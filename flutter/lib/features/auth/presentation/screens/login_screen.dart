import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../design_system/nocturne.dart';
import '../controllers/auth_controller.dart';

/// Screen 01 · Login.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email and password')),
      );
      return;
    }

    // The backend auto-creates the user on first login (see
    // api/auth.routes.js), so "Create account" and "Log in" are the same
    // call — there's no separate signup endpoint.
    await ref.read(authProvider.notifier).login(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: NocturneColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: NocturneColors.accent300, width: 2),
                    ),
                    child: const Icon(
                      PhosphorIconsFill.heartbeat,
                      color: NocturneColors.accent300,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('FitRing', style: NocturneType.h4),
                  const SizedBox(height: 2),
                  Text('Sign in to see your vitals', style: NocturneType.caption),
                  const SizedBox(height: 24),
                  NocturneTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 14),
                  NocturneTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Forgot password?',
                        style: NocturneType.caption.copyWith(
                          color: NocturneColors.accent300,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  NocturneButton(
                    label: 'Log in',
                    block: true,
                    loading: auth.isSubmitting,
                    onPressed: auth.isSubmitting ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  NocturneButton(
                    label: 'Create account',
                    variant: NocturneButtonVariant.ghost,
                    block: true,
                    onPressed: auth.isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
