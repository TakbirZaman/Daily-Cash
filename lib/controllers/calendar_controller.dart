import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

class CalendarController extends ChangeNotifier {
  CalendarController({required this.uid, FirestoreService? service})
      : _service = service ?? FirestoreService.instance {
    selectDay(DateTime.now());
  }

  final String uid;
  final FirestoreService _service;
  StreamSubscription<List<TransactionModel>>? _daySub;
  StreamSubscription<List<TransactionModel>>? _monthSub;

  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();
  List<TransactionModel> items = const <TransactionModel>[];
  double income = 0;
  double expense = 0;
  bool hasLoaded = false;

  // Days (in the visible month) that have entries, for the calendar dots.
  final Set<int> _incomeDays = <int>{};
  final Set<int> _expenseDays = <int>{};
  int _markerMonthKey = -1;

  static int _key(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  bool hasIncome(DateTime d) => _incomeDays.contains(_key(d));
  bool hasExpense(DateTime d) => _expenseDays.contains(_key(d));
  bool hasAny(DateTime d) => hasIncome(d) || hasExpense(d);

  void selectDay(DateTime day, [DateTime? focused]) {
    selectedDay = DateTime(day.year, day.month, day.day);
    focusedDay = focused ?? selectedDay;
    hasLoaded = false;
    _daySub?.cancel();
    _daySub = _service.watchDay(uid, selectedDay).listen(_onDay, onError: (Object _) {});
    _syncMarkers(focusedDay);
    notifyListeners();
  }

  /// Called when the user swipes to another month.
  void onPageChanged(DateTime focused) {
    focusedDay = focused;
    _syncMarkers(focused);
  }

  void _syncMarkers(DateTime focused) {
    final int monthKey = focused.year * 100 + focused.month;
    if (monthKey == _markerMonthKey) return;
    _markerMonthKey = monthKey;
    _monthSub?.cancel();
    // A week of padding on both sides covers the greyed-out days in the grid.
    final DateTime start = DateTime(focused.year, focused.month, 1 - 7);
    final DateTime end = DateTime(focused.year, focused.month + 1, 1 + 7);
    _monthSub = _service.watchRange(uid, start, end).listen(_onMonth, onError: (Object _) {});
  }

  void _onDay(List<TransactionModel> list) {
    double inc = 0, exp = 0;
    for (final TransactionModel t in list) {
      if (t.isIncome) {
        inc += t.amount;
      } else {
        exp += t.amount;
      }
    }
    items = list;
    income = inc;
    expense = exp;
    hasLoaded = true;
    notifyListeners();
  }

  void _onMonth(List<TransactionModel> list) {
    _incomeDays.clear();
    _expenseDays.clear();
    for (final TransactionModel t in list) {
      final int k = _key(t.timestamp);
      if (t.isIncome) {
        _incomeDays.add(k);
      } else {
        _expenseDays.add(k);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _daySub?.cancel();
    _monthSub?.cancel();
    super.dispose();
  }
}
