import 'package:flutter/material.dart';

import '../main.dart';
import '../models/profile.dart';
import 'verification_form_screen.dart';

/// Shown when the signed-in user's account isn't active yet:
/// - pending + already submitted verification -> waiting for admin review
/// - suspended -> blocked by an admin
/// - rejected -> shows the admin's note with a way to resubmit
class WaitingScreen extends StatelessWidget {
  final Profile profile;
  final Future<void> Function() onRefresh;

  const WaitingScreen({super.key, required this.profile, required this.onRefresh});

  IconData get _icon {
    if (profile.isRejected) return Icons.error_outline_rounded;
    if (profile.isSuspended) return Icons.block_rounded;
    return Icons.hourglass_top_rounded;
  }

  Color _iconColor(BuildContext context) {
    if (profile.isRejected || profile.isSuspended) return Colors.red.shade700;
    return Colors.amber.shade700;
  }

  String get _title {
    if (profile.isRejected) return 'Verification rejected';
    if (profile.isSuspended) return 'Account suspended';
    return 'Waiting for approval';
  }

  String get _message {
    if (profile.isRejected) {
      return 'An admin reviewed your submission and it needs some changes. '
          'See the note below, then resubmit.';
    }
    if (profile.isSuspended) {
      return 'Your account has been suspended by an admin. Contact them if you think this is a mistake.';
    }
    return 'Hi ${profile.fullName}, your verification info has been submitted. '
        'An admin needs to review and approve it before you can submit deposits.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon, size: 56, color: _iconColor(context)),
                const SizedBox(height: 16),
                Text(_title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(_message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                if (profile.isRejected && profile.reviewNote != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '"${profile.reviewNote}"',
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (profile.isRejected)
                  FilledButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VerificationFormScreen(
                            profile: profile,
                            onSubmitted: () async {
                              await onRefresh();
                              if (context.mounted) Navigator.of(context).pop();
                            },
                          ),
                        ),
                      );
                      await onRefresh();
                    },
                    child: const Text('Resubmit verification'),
                  )
                else
                  OutlinedButton(
                    onPressed: onRefresh,
                    child: const Text('Check again'),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => supabase.auth.signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
