import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../models/profile.dart';
import 'login_screen.dart';
import 'home_shell.dart';
import 'verification_form_screen.dart';
import 'waiting_screen.dart';

/// Root widget that decides what to show based on auth + profile state:
/// no session -> LoginScreen, pending -> WaitingScreen, suspended ->
/// WaitingScreen, active -> HomeShell.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;

        if (session == null) {
          return const LoginScreen();
        }

        return _ProfileLoader(key: ValueKey(session.user.id));
      },
    );
  }
}

class _ProfileLoader extends StatefulWidget {
  const _ProfileLoader({super.key});

  @override
  State<_ProfileLoader> createState() => _ProfileLoaderState();
}

class _ProfileLoaderState extends State<_ProfileLoader> {
  late Future<Profile> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadProfile();
  }

  Future<Profile> _loadProfile() async {
    final userId = supabase.auth.currentUser!.id;
    final data =
        await supabase.from('profiles').select().eq('id', userId).single();
    return Profile.fromMap(data);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load your profile.'),
                    const SizedBox(height: 12),
                    Text('${snapshot.error}',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => supabase.auth.signOut(),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final profile = snapshot.data!;

        if (profile.isActive) {
          return HomeShell(profile: profile, onProfileChanged: _refresh);
        }

        // A brand-new (or resubmitting) member who hasn't filled out the
        // verification form yet goes straight there instead of the waiting
        // screen, since there's nothing for them to wait on yet.
        if (profile.isPending && !profile.hasSubmittedVerification) {
          return VerificationFormScreen(profile: profile, onSubmitted: _refresh);
        }

        return WaitingScreen(profile: profile, onRefresh: _refresh);
      },
    );
  }
}
