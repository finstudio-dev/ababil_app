import 'package:flutter/material.dart';

import '../main.dart';
import '../models/deposit.dart';
import '../models/profile.dart';
import '../utils/format.dart';
import '../widgets/status_badge.dart';

class HistoryTab extends StatefulWidget {
  final Profile profile;

  const HistoryTab({super.key, required this.profile});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  late Future<List<Deposit>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Deposit>> _load() async {
    final rows = await supabase
        .from('deposits')
        .select()
        .eq('member_id', widget.profile.id)
        .order('submitted_at', ascending: false);
    return (rows as List).map((r) => Deposit.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _showDetails(Deposit d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatMoney(d.amount),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: d.amount < 0 ? Colors.red.shade700 : null,
                  ),
                ),
                StatusBadge(status: d.status),
              ],
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Type', value: depositEntryTypeLabels[d.entryType] ?? d.entryType),
            _DetailRow(label: 'Method', value: depositMethodLabels[d.method] ?? d.method),
            if (d.transactionRef != null && d.transactionRef!.isNotEmpty)
              _DetailRow(label: 'Reference', value: d.transactionRef!),
            _DetailRow(label: 'Submitted', value: formatDate(d.submittedAt)),
            if (d.reviewedAt != null)
              _DetailRow(label: 'Reviewed', value: formatDate(d.reviewedAt!)),
            if (d.note != null && d.note!.isNotEmpty) _DetailRow(label: 'Your note', value: d.note!),
            if (d.adminNote != null && d.adminNote!.isNotEmpty)
              _DetailRow(label: 'Admin note', value: d.adminNote!),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Deposit>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final deposits = snapshot.data!;

          if (deposits.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 80),
                Center(child: Text('No deposits yet.', style: TextStyle(color: Colors.grey))),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            itemCount: deposits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = deposits[i];
              return Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  onTap: () => _showDetails(d),
                  title: Text(
                    formatMoney(d.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: d.amount < 0 ? Colors.red.shade700 : null,
                    ),
                  ),
                  subtitle: Text(
                      '${depositEntryTypeLabels[d.entryType] ?? d.entryType} · ${depositMethodLabels[d.method] ?? d.method} · ${formatDate(d.submittedAt)}'),
                  trailing: StatusBadge(status: d.status),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
