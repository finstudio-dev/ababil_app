class Deposit {
  final String id;
  final String memberId;
  final double amount;
  final String method; // bkash | nagad | rocket | bank | cash | other
  final String? transactionRef;
  final String? note;
  final String? receiptUrl; // storage path, not a public URL
  final DateTime periodMonth;
  final String status; // pending | approved | rejected
  final String source; // member | admin
  final String entryType; // deposit | withdrawal | bonus | adjustment
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? adminNote;

  Deposit({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.method,
    required this.transactionRef,
    required this.note,
    required this.receiptUrl,
    required this.periodMonth,
    required this.status,
    required this.source,
    required this.entryType,
    required this.submittedAt,
    required this.reviewedAt,
    required this.adminNote,
  });

  factory Deposit.fromMap(Map<String, dynamic> map) {
    return Deposit(
      id: map['id'] as String,
      memberId: map['member_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      method: map['method'] as String,
      transactionRef: map['transaction_ref'] as String?,
      note: map['note'] as String?,
      receiptUrl: map['receipt_url'] as String?,
      periodMonth: DateTime.parse(map['period_month'] as String),
      status: map['status'] as String,
      source: map['source'] as String? ?? 'member',
      entryType: map['entry_type'] as String? ?? 'deposit',
      submittedAt: DateTime.parse(map['submitted_at'] as String),
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.parse(map['reviewed_at'] as String)
          : null,
      adminNote: map['admin_note'] as String?,
    );
  }
}

const Map<String, String> depositMethodLabels = {
  'bkash': 'bKash',
  'nagad': 'Nagad',
  'rocket': 'Rocket',
  'bank': 'Bank Transfer',
  'cash': 'Cash',
  'other': 'Other',
};

const Map<String, String> depositEntryTypeLabels = {
  'deposit': 'Deposit',
  'withdrawal': 'Withdrawal',
  'bonus': 'Bonus',
  'adjustment': 'Adjustment',
};
