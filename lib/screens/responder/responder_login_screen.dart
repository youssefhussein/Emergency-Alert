import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'responder_session_provider.dart';

class ResponderLoginScreen extends ConsumerStatefulWidget {
  const ResponderLoginScreen({super.key});

  @override
  ConsumerState<ResponderLoginScreen> createState() => _ResponderLoginScreenState();
}

class _ResponderLoginScreenState extends ConsumerState<ResponderLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(responderAuthProvider.notifier).loginWithUuid(_codeController.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/responder-home', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final s = ref.watch(responderAuthProvider);

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: const Text('Responder Portal'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Sign in with your responder UUID',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'For your demo: responders are pre-created in Supabase (no email/password).',
                style: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Responder UUID',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid UUID' : null,
                ),
              ),
              const SizedBox(height: 16),
              if (s.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(s.error!, style: TextStyle(color: c.error)),
                ),
              FilledButton.icon(
                onPressed: s.loading ? null : _login,
                icon: s.loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.login),
                label: Text(s.loading ? 'Signing in...' : 'Sign in'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/signup', (r) => false),
                icon: const Icon(Icons.person_outline),
                label: const Text('Back to Citizen App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
