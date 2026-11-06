import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/l10n/strings.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

enum HistoryFilter { all, income, expense }

class HistoryController extends ChangeNotifier {
  HistoryController({required this.uid, FirestoreService? service})
      : _service = service ?? FirestoreService.instance {
    _sub = _service.watchTransactions(uid).listen(_onData, onError: (Object _) {});
  }

  final String uid;
  final FirestoreService _service;
  StreamSubscription<List<TransactionModel>>? _sub;

  List<TransactionModel> _all = const <TransactionModel>[];
  bool hasLoaded = false;
  String _query = '';
  HistoryFilter _filter = HistoryFilter.all;

  List<TransactionModel> get all => _all;
  HistoryFilter get filter => _filter;

  List<TransactionModel> get results {
    final String q = S.toEnglishDigits(_query).trim().toLowerCase();
    return _all.where((TransactionModel t) {
      if (_filter == HistoryFilter.income && !t.isIncome) return false;
      if (_filter == HistoryFilter.expense && t.isIncome) return false;
      if (q.isEmpty) return true;
      final String note = (t.note ?? '').toLowerCase();
      final String amount = t.amount.toString();
      return note.contains(q) || amount.contains(q);
    }).toList();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setFilter(HistoryFilter value) {
    _filter = value;
    notifyListeners();
  }

  void _onData(List<TransactionModel> list) {
    _all = list;
    hasLoaded = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
