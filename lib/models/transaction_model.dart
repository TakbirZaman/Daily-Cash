class TransactionType {
  TransactionType._();
  static const String income = 'income';
  static const String expense = 'expense';
}

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.timestamp,
    this.note,
    this.pending = false,
  });

  final String id;
  final double amount;
  final String type; // "income" | "expense"
  final DateTime timestamp;
  final String? note;

  /// True while this record is saved on the phone but not yet synced to the server.
  final bool pending;

  bool get isIncome => type == TransactionType.income;

  TransactionModel withPending(bool value) => TransactionModel(
        id: id,
        amount: amount,
        type: type,
        timestamp: timestamp,
        note: note,
        pending: value,
      );

  // ---- server row (Supabase) ----

  Map<String, dynamic> toRow(String userId) => <String, dynamic>{
        'id': id,
        'user_id': userId,
        'amount': amount,
        'type': type,
        'note': note ?? '',
        'created_at': timestamp.toUtc().toIso8601String(),
      };

  /// Returns null for malformed rows so one bad record never crashes the list.
  static TransactionModel? fromRow(Map<String, dynamic> r) {
    try {
      final String? id = r['id'] as String?;
      final num? amount = r['amount'] as num?;
      final String? type = r['type'] as String?;
      final String? created = r['created_at'] as String?;
      if (id == null ||
          amount == null ||
          created == null ||
          (type != TransactionType.income && type != TransactionType.expense)) {
        return null;
      }
      final String note = (r['note'] as String? ?? '').trim();
      return TransactionModel(
        id: id,
        amount: amount.toDouble(),
        type: type!,
        timestamp: DateTime.parse(created).toLocal(),
        note: note.isEmpty ? null : note,
      );
    } catch (_) {
      return null;
    }
  }

  // ---- local copy on the phone ----

  Map<String, dynamic> toLocal() => <String, dynamic>{
        'id': id,
        'amount': amount,
        'type': type,
        'ts': timestamp.millisecondsSinceEpoch,
        'note': note ?? '',
      };

  static TransactionModel? fromLocal(Map<String, dynamic> m) {
    try {
      final String? id = m['id'] as String?;
      final num? amount = m['amount'] as num?;
      final String? type = m['type'] as String?;
      final int? ts = (m['ts'] as num?)?.toInt();
      if (id == null ||
          amount == null ||
          ts == null ||
          (type != TransactionType.income && type != TransactionType.expense)) {
        return null;
      }
      final String note = (m['note'] as String? ?? '').trim();
      return TransactionModel(
        id: id,
        amount: amount.toDouble(),
        type: type!,
        timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
        note: note.isEmpty ? null : note,
      );
    } catch (_) {
      return null;
    }
  }
}
