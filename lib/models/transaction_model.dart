import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toMap() => <String, dynamic>{
        'amount': amount,
        'type': type,
        'timestamp': Timestamp.fromDate(timestamp),
        'note': note ?? '',
      };

  /// Returns null for malformed documents so one bad record never crashes the list.
  static TransactionModel? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final Map<String, dynamic>? d = doc.data();
      if (d == null) return null;

      final num? amount = d['amount'] as num?;
      final String? type = d['type'] as String?;
      if (amount == null ||
          (type != TransactionType.income && type != TransactionType.expense)) {
        return null;
      }

      final Object? rawTs = d['timestamp'];
      final DateTime ts = rawTs is Timestamp ? rawTs.toDate() : DateTime.now();
      final String note = (d['note'] as String? ?? '').trim();

      return TransactionModel(
        id: doc.id,
        amount: amount.toDouble(),
        type: type!,
        timestamp: ts,
        note: note.isEmpty ? null : note,
        pending: doc.metadata.hasPendingWrites,
      );
    } catch (_) {
      return null;
    }
  }
}
