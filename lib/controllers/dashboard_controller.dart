import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart';
import '../services/ledger_service.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({required this.uid, LedgerService? service})
      : _service = service ?? LedgerService.instance {
    _sub = _service.watchTransactions(uid).listen(_onData, onError: (Object _) {});
  }

  final String uid;
  final LedgerService _service;
  StreamSubscription<List<TransactionModel>>? _sub;

  List<TransactionModel> _all = const <TransactionModel>[];
  bool hasLoaded = false;
  double balance = 0;
  double todayIncome = 0;
  double todayExpense = 0;

  List<TransactionModel> get all => _all;
  List<TransactionModel> get recent => _all.length > 50 ? _all.sublist(0, 50) : _all;

  void _onData(List<TransactionModel> list) {
    try {
      final DateTime now = DateTime.now();
      double bal = 0, inc = 0, exp = 0;
      for (final TransactionModel t in list) {
        bal += t.isIncome ? t.amount : -t.amount;
        final bool today = t.timestamp.year == now.year &&
            t.timestamp.month == now.month &&
            t.timestamp.day == now.day;
        if (today) {
          if (t.isIncome) {
            inc += t.amount;
          } else {
            exp += t.amount;
          }
        }
      }
      _all = list;
      balance = bal;
      todayIncome = inc;
      todayExpense = exp;
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
