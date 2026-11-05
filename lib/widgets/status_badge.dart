import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color get _bg {
    switch (status) {
      case 'approved':
      case 'active':
        return Colors.green.shade100;
      case 'pending':
        return Colors.amber.shade100;
      case 'rejected':
      case 'suspended':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color get _fg {
    switch (status) {
      case 'approved':
      case 'active':
        return Colors.green.shade800;
      case 'pending':
        return Colors.amber.shade800;
      case 'rejected':
      case 'suspended':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: _fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
