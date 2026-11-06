import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

class ReportController extends ChangeNotifier {
  ReportController({required this.uid, FirestoreService? service})
      : _service = service ?? FirestoreService.instance {
    _load();
  }

  final String uid;
  final FirestoreService _service;
  StreamSubscription<List<TransactionModel>>? _sub;

  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  List<TransactionModel> items = const <TransactionModel>[];
  bool hasLoaded = false;
  double income = 0;
  double expense = 0;
  List<double> dailyIncome = const <double>[];
  List<double> dailyExpense = const <double>[];
  List<MapEntry<String?, double>> topExpenses = const <MapEntry<String?, double>>[];

  double get net => income - expense;
  int get daysInMonth => DateTime(month.year, month.month + 1, 0).day;

  bool get isCurrentMonth {
    final DateTime now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  void previous() {
    month = DateTime(month.year, month.month - 1);
    _load();
  }

  void next() {
    if (isCurrentMonth) return;
    month = DateTime(month.year, month.month + 1);
    _load();
  }

  void _load() {
    hasLoaded = false;
    _sub?.cancel();
    final DateTime end = DateTime(month.year, month.month + 1);
    _sub = _service.watchRange(uid, month, end).listen(_onData, onError: (Object _) {});
    notifyListeners();
  }

  void _onData(List<TransactionModel> list) {
    try {
      final int days = daysInMonth;
      final List<double> inc = List<double>.filled(days, 0);
      final List<double> exp = List<double>.filled(days, 0);
      double totalInc = 0, totalExp = 0;

      final Map<String, double> byNote = <String, double>{};
      final Map<String, String?> label = <String, String?>{};

      for (final TransactionModel t in list) {
        final int i = t.timestamp.day - 1;
        if (i < 0 || i >= days) continue;
        if (t.isIncome) {
          inc[i] += t.amount;
          totalInc += t.amount;
        } else {
          exp[i] += t.amount;
          totalExp += t.amount;
          final String key = (t.note ?? '').toLowerCase();
          byNote[key] = (byNote[key] ?? 0) + t.amount;
          label.putIfAbsent(key, () => t.note);
        }
      }

      final List<String> keys = byNote.keys.toList()
        ..sort((String a, String b) => byNote[b]!.compareTo(byNote[a]!));

      items = list;
      income = totalInc;
      expense = totalExp;
      dailyIncome = inc;
      dailyExpense = exp;
      topExpenses = <MapEntry<String?, double>>[
        for (final String k in keys.take(5)) MapEntry<String?, double>(label[k], byNote[k]!),
      ];
      hasLoaded = true;
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
