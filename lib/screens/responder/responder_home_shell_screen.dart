import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'responder_assigned_screen.dart';
import 'responder_profile_screen.dart';
import 'responder_session_provider.dart';

class ResponderHomeShellScreen extends ConsumerStatefulWidget {
  const ResponderHomeShellScreen({super.key});

  @override
  ConsumerState<ResponderHomeShellScreen> createState() => _ResponderHomeShellScreenState();
}

class _ResponderHomeShellScreenState extends ConsumerState<ResponderHomeShellScreen> {
  int _index = 0;

  final _pages = const [
    ResponderAssignedScreen(),
    ResponderProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(responderAuthProvider.notifier).restore());
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final auth = ref.watch(responderAuthProvider);

    if (auth.loading && auth.responder == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.responder == null) {
      return Scaffold(
        backgroundColor: c.surface,
        appBar: AppBar(
          backgroundColor: c.surface,
          foregroundColor: c.onSurface,
          elevation: 0,
          title: const Text('Responder Portal'),
        ),
        body: Center(
          child: FilledButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/responder-login', (r) => false),
            icon: const Icon(Icons.login),
            label: const Text('Sign in'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.surface,
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Assigned',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
