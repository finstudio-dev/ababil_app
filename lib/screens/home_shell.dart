import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/profile.dart';
import '../services/update_checker.dart';
import 'dashboard_tab.dart';
import 'history_tab.dart';
import 'profile_tab.dart';
import 'submit_deposit_screen.dart';

class HomeShell extends StatefulWidget {
  final Profile profile;
  final Future<void> Function() onProfileChanged;

  const HomeShell({super.key, required this.profile, required this.onProfileChanged});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _refreshTick = 0;

  void _bumpRefresh() => setState(() => _refreshTick++);

  @override
  void initState() {
    super.initState();
    // Runs once per app open, after the first frame so a dialog has a
    // ready context to show into. Silent by design if there's nothing new
    // or the check can't complete — see checkForUpdate().
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowUpdateDialog());
  }

  Future<void> _maybeShowUpdateDialog() async {
    final update = await checkForUpdate();
    if (!mounted || update == null) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update available: ${update.version}'),
        content: SingleChildScrollView(
          child: Text(
            (update.notes != null && update.notes!.trim().isNotEmpty)
                ? update.notes!.trim()
                : 'A new version of ${AppConfig.appName} is available.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              launchUrl(Uri.parse(update.downloadUrl), mode: LaunchMode.externalApplication);
            },
            child: const Text('Download update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(key: ValueKey('dash-$_refreshTick'), profile: widget.profile),
      HistoryTab(key: ValueKey('hist-$_refreshTick'), profile: widget.profile),
      ProfileTab(profile: widget.profile, onProfileChanged: widget.onProfileChanged),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: tabs)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final submitted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const SubmitDepositScreen()),
          );
          if (submitted == true) {
            _bumpRefresh();
            setState(() => _index = 1); // jump to history to show the new pending entry
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Submit deposit'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
