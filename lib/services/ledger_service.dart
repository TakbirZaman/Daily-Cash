import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, SupabaseClient;

import '../models/transaction_model.dart';

class _Op {
  const _Op(this.seq, {required this.isDelete});
  final int seq;
  final bool isDelete;
}

/// Offline first ledger.
///
/// Every change is applied to a copy kept on the phone straight away, so the app
/// feels instant and works with no internet. Changes wait in a queue and are sent
/// to Supabase whenever the connection allows. Nothing here ever throws.
class LedgerService {
  LedgerService._();
  static final LedgerService instance = LedgerService._();

  SupabaseClient get _db => Supabase.instance.client;

  String? _uid;
  Future<void>? _initFuture;
  List<TransactionModel> _items = <TransactionModel>[];
  final Map<String, _Op> _ops = <String, _Op>{};
  int _seq = 0;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  Timer? _timer;
  int _tick = 0;
  bool _flushing = false;
  bool _pulling = false;
  Future<void> _writeChain = Future<void>.value();

  // ---------------------------------------------------------------- start

  Future<void> _ensure(String uid) {
    if (_uid == uid && _initFuture != null) return _initFuture!;
    _uid = uid;
    _initFuture = _init(uid);
    return _initFuture!;
  }

  Future<void> _init(String uid) async {
    _items = <TransactionModel>[];
    _ops.clear();
    await _loadFromDisk(uid);
    _notify();
    _timer ??= Timer.periodic(const Duration(seconds: 20), (Timer _) {
      _tick++;
      if (_ops.isNotEmpty) unawaited(flush());
      if (_tick % 6 == 0) unawaited(sync());
    });
    unawaited(sync());
  }

  // ---------------------------------------------------------------- streams

  Stream<List<TransactionModel>> watchTransactions(String uid) =>
      _watch(uid, (TransactionModel _) => true);

  /// [start] inclusive, [end] exclusive.
  Stream<List<TransactionModel>> watchRange(String uid, DateTime start, DateTime end) {
    return _watch(
      uid,
      (TransactionModel t) => !t.timestamp.isBefore(start) && t.timestamp.isBefore(end),
    );
  }

  Stream<List<TransactionModel>> watchDay(String uid, DateTime day) {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = DateTime(day.year, day.month, day.day + 1);
    return watchRange(uid, start, end);
  }

  Stream<List<TransactionModel>> _watch(String uid, bool Function(TransactionModel) where) {
    late final StreamController<List<TransactionModel>> ctrl;
    StreamSubscription<void>? sub;

    List<TransactionModel> select() => <TransactionModel>[
          for (final TransactionModel t in _items)
            if (where(t)) t.withPending(_ops.containsKey(t.id)),
        ];

    ctrl = StreamController<List<TransactionModel>>(
      onListen: () async {
        await _ensure(uid);
        if (ctrl.isClosed) return;
        sub = _changes.stream.listen((_) {
          if (!ctrl.isClosed) ctrl.add(select());
        });
        ctrl.add(select());
      },
      onCancel: () async {
        await sub?.cancel();
        await ctrl.close();
      },
    );
    return ctrl.stream;
  }

  // ---------------------------------------------------------------- changes

  bool addTransaction(
    String uid, {
    required double amount,
    required String type,
    String? note,
  }) {
    try {
      final TransactionModel tx = TransactionModel(
        id: _newId(),
        amount: amount,
        type: type,
        timestamp: DateTime.now(), // set automatically, never asked from the user
        note: _clean(note),
      );
      unawaited(_apply(uid, () {
        _items.add(tx);
        _ops[tx.id] = _Op(++_seq, isDelete: false);
      }));
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
      unawaited(_apply(uid, () {
        final int i = _items.indexWhere((TransactionModel t) => t.id == id);
        if (i < 0) return;
        _items[i] = TransactionModel(
          id: id,
          amount: amount,
          type: type,
          timestamp: _items[i].timestamp,
          note: _clean(note),
        );
        _ops[id] = _Op(++_seq, isDelete: false);
      }));
      return true;
    } catch (_) {
      return false;
    }
  }

  void deleteTransaction(String uid, String id) {
    unawaited(_apply(uid, () {
      _items.removeWhere((TransactionModel t) => t.id == id);
      _ops[id] = _Op(++_seq, isDelete: true);
    }));
  }

  /// Used by "Undo": puts the same record back with its original date.
  void restoreTransaction(String uid, TransactionModel tx) {
    unawaited(_apply(uid, () {
      _items.removeWhere((TransactionModel t) => t.id == tx.id);
      _items.add(tx.withPending(false));
      _ops[tx.id] = _Op(++_seq, isDelete: false);
    }));
  }

  Future<void> _apply(String uid, void Function() change) async {
    try {
      await _ensure(uid);
      change();
      _sortItems();
      _notify();
      _persist();
      unawaited(flush());
    } catch (_) {}
  }

  // ---------------------------------------------------------------- sync

  /// Sends queued changes to Supabase, oldest first. Stops at the first failure
  /// (usually "no internet") and tries again on the next timer tick.
  Future<void> flush() async {
    final String? uid = _uid;
    if (uid == null || _flushing || _pulling) return;
    _flushing = true;
    bool failed = false;
    try {
      for (final MapEntry<String, _Op> entry in _ops.entries.toList()) {
        final String id = entry.key;
        final _Op op = entry.value;
        try {
          if (op.isDelete) {
            await _db.from('transactions').delete().eq('id', id);
          } else {
            final TransactionModel? tx = _find(id);
            if (tx != null) {
              await _db.from('transactions').upsert(tx.toRow(uid));
            }
          }
        } catch (_) {
          failed = true;
          break;
        }
        if (_ops[id]?.seq == op.seq) _ops.remove(id);
        _notify();
        _persist();
      }
    } finally {
      _flushing = false;
    }
    if (!failed && _ops.isNotEmpty) unawaited(flush());
  }

  /// Downloads the server copy and merges it with what is waiting to be sent.
  Future<void> sync() async {
    final String? uid = _uid;
    if (uid == null || _pulling) return;
    await flush();

    _pulling = true; // pauses flush so a change cannot slip between download and merge
    try {
      final List<Map<String, dynamic>> rows = await _fetchAll(uid);
      if (_uid != uid) return;

      final Map<String, TransactionModel> merged = <String, TransactionModel>{};
      for (final Map<String, dynamic> r in rows) {
        final TransactionModel? t = TransactionModel.fromRow(r);
        if (t != null) merged[t.id] = t;
      }
      // Changes not sent yet win over the server copy.
      for (final MapEntry<String, _Op> e in _ops.entries) {
        if (e.value.isDelete) {
          merged.remove(e.key);
        } else {
          final TransactionModel? local = _find(e.key);
          if (local != null) merged[e.key] = local;
        }
      }
      _items = merged.values.toList();
      _sortItems();
      _notify();
      _persist();
    } catch (_) {
      // Offline or server problem: keep working from the phone copy.
    } finally {
      _pulling = false;
      unawaited(flush());
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAll(String uid) async {
    const int page = 1000; // Supabase returns at most 1000 rows per request
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    int from = 0;
    while (true) {
      final List<Map<String, dynamic>> chunk = await _db
          .from('transactions')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .order('id')
          .range(from, from + page - 1);
      out.addAll(chunk);
      if (chunk.length < page) break;
      from += page;
    }
    return out;
  }

  // ---------------------------------------------------------------- helpers

  TransactionModel? _find(String id) {
    for (final TransactionModel t in _items) {
      if (t.id == id) return t;
    }
    return null;
  }

  void _sortItems() =>
      _items.sort((TransactionModel a, TransactionModel b) => b.timestamp.compareTo(a.timestamp));

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  String? _clean(String? note) {
    final String? n = note?.trim();
    return (n == null || n.isEmpty) ? null : n;
  }

  /// UUID v4, made on the phone so entries can be created offline.
  String _newId() {
    final Random r = Random.secure();
    final List<int> b = List<int>.generate(16, (int _) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final String h = b.map((int x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }

  // ---------------------------------------------------------------- disk

  Future<File> _file(String uid) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/ledger_$uid.json');
  }

  Future<void> _loadFromDisk(String uid) async {
    try {
      final File f = await _file(uid);
      if (!await f.exists()) return;
      final Object? data = jsonDecode(await f.readAsString());
      if (data is! Map<String, dynamic>) return;

      final Object? items = data['items'];
      if (items is List) {
        for (final Object? e in items) {
          if (e is Map<String, dynamic>) {
            final TransactionModel? t = TransactionModel.fromLocal(e);
            if (t != null) _items.add(t);
          }
        }
      }
      final Object? ops = data['ops'];
      if (ops is List) {
        for (final Object? e in ops) {
          if (e is Map<String, dynamic> && e['id'] is String) {
            _ops[e['id'] as String] = _Op(++_seq, isDelete: e['delete'] == true);
          }
        }
      }
      _sortItems();
    } catch (_) {
      // Damaged file: start empty, the next sync restores everything from the server.
      _items = <TransactionModel>[];
      _ops.clear();
    }
  }

  void _persist() {
    final String? uid = _uid;
    if (uid == null) return;
    final String json = jsonEncode(<String, dynamic>{
      'items': _items.map((TransactionModel t) => t.toLocal()).toList(),
      'ops': <Map<String, dynamic>>[
        for (final MapEntry<String, _Op> e in _ops.entries)
          <String, dynamic>{'id': e.key, 'delete': e.value.isDelete},
      ],
    });
    // One write at a time, through a temp file, so a crash can never half write the copy.
    _writeChain = _writeChain.then((_) async {
      try {
        final File f = await _file(uid);
        final File tmp = File('${f.path}.tmp');
        await tmp.writeAsString(json, flush: true);
        await tmp.rename(f.path);
      } catch (_) {}
    });
  }
}
