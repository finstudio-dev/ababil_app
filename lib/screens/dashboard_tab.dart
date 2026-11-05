import 'package:flutter/material.dart';

import '../main.dart';
import '../models/profile.dart';
import '../utils/format.dart';

class DashboardTab extends StatefulWidget {
  final Profile profile;

  const DashboardTab({super.key, required this.profile});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardSummary {
  final double approvedTotal;
  final double pendingTotal;
  final bool paidThisMonth;

  _DashboardSummary({
    required this.approvedTotal,
    required this.pendingTotal,
    required this.paidThisMonth,
  });
}

class _DashboardTabState extends State<DashboardTab> {
  late Future<_DashboardSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardSummary> _load() async {
    final userId = widget.profile.id;

    final balanceRow = await supabase
        .from('member_balances')
        .select()
        .eq('member_id', userId)
        .maybeSingle();

    final now = DateTime.now();
    final periodMonth = DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);

    final monthRow = await supabase
        .from('monthly_contributions')
        .select()
        .eq('member_id', userId)
        .eq('period_month', periodMonth)
        .maybeSingle();

    return _DashboardSummary(
      approvedTotal: (balanceRow?['total_approved'] as num?)?.toDouble() ?? 0,
      pendingTotal: (balanceRow?['total_pending'] as num?)?.toDouble() ?? 0,
      paidThisMonth: monthRow != null,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<_DashboardSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Hi, ${widget.profile.fullName.split(' ').first}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(formatMonth(DateTime.now()), style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              _BalanceCard(
                label: 'Your total (approved)',
                value: formatMoney(s.approvedTotal),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              if (s.pendingTotal > 0) ...[
                const SizedBox(height: 12),
                _BalanceCard(
                  label: 'Awaiting admin review',
                  value: formatMoney(s.pendingTotal),
                  color: Colors.amber.shade50,
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: s.paidThisMonth ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      s.paidThisMonth ? Icons.check_circle : Icons.error_outline,
                      color: s.paidThisMonth ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.paidThisMonth
                            ? "You've contributed this month."
                            : "You haven't contributed this month yet.",
                        style: TextStyle(
                          color: s.paidThisMonth ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BalanceCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
