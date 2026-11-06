import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transaction_model.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  /// Call once, right after Firebase.initializeApp().
  static void enableOfflinePersistence() {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {}
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _txRef(String uid) =>
      _db.collection('users').doc(uid).collection('transactions');

  Stream<List<TransactionModel>> _list(Query<Map<String, dynamic>> query) {
    return query
        .snapshots(includeMetadataChanges: true)
        .map((QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
            .map(TransactionModel.fromDoc)
            .whereType<TransactionModel>()
            .toList())
        .handleError((Object _) {});
  }

  /// Everything, newest first. Served from the local cache first, so it works offline.
  Stream<List<TransactionModel>> watchTransactions(String uid) =>
      _list(_txRef(uid).orderBy('timestamp', descending: true));

  /// [start] inclusive, [end] exclusive. Single-field range, so no index is needed.
  Stream<List<TransactionModel>> watchRange(String uid, DateTime start, DateTime end) {
    return _list(_txRef(uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true));
  }

  Stream<List<TransactionModel>> watchDay(String uid, DateTime day) {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = DateTime(day.year, day.month, day.day + 1);
    return watchRange(uid, start, end);
  }

  /// Fire-and-forget on purpose: offline, Firestore's write future only completes
  /// once the server confirms. The local cache updates instantly and the write
  /// syncs automatically when the connection returns.
  bool addTransaction(
    String uid, {
    required double amount,
    required String type,
    String? note,
  }) {
    try {
      final DocumentReference<Map<String, dynamic>> ref = _txRef(uid).doc();
      final TransactionModel tx = TransactionModel(
        id: ref.id,
        amount: amount,
        type: type,
        timestamp: DateTime.now(), // set automatically, never asked from the user
        note: _clean(note),
      );
      unawaited(ref.set(tx.toMap()).catchError((Object _) {}));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Edits amount / type / note. The original date stays the same.
  bool updateTransaction(
    String uid,
    String id, {
    required double amount,
    required String type,
    String? note,
  }) {
    try {
      unawaited(_txRef(uid).doc(id).update(<String, dynamic>{
        'amount': amount,
        'type': type,
        'note': _clean(note) ?? '',
      }).catchError((Object _) {}));
      return true;
    } catch (_) {
      return false;
    }
  }

  void deleteTransaction(String uid, String id) {
    try {
      unawaited(_txRef(uid).doc(id).delete().catchError((Object _) {}));
    } catch (_) {}
  }

  /// Used by "Undo": puts the same record back with its original date.
  void restoreTransaction(String uid, TransactionModel tx) {
    try {
      unawaited(_txRef(uid).doc(tx.id).set(tx.toMap()).catchError((Object _) {}));
    } catch (_) {}
  }

  void saveProfile(String uid, String name) {
    try {
      unawaited(_db
          .collection('users')
          .doc(uid)
          .set(<String, dynamic>{'name': name.trim()}, SetOptions(merge: true))
          .catchError((Object _) {}));
    } catch (_) {}
  }

  String? _clean(String? note) {
    final String? n = note?.trim();
    return (n == null || n.isEmpty) ? null : n;
  }
}
