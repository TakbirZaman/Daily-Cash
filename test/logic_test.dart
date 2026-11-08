import 'package:daily_cash/core/l10n/strings.dart';
import 'package:daily_cash/core/utils/note_suggestions.dart';
import 'package:daily_cash/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionModel _tx(String id, String? note, {String type = 'expense'}) => TransactionModel(
      id: id,
      amount: 10,
      type: type,
      timestamp: DateTime(2026, 11, 8, 9, 30),
      note: note,
    );

void main() {
  group('Bangla digits', () {
    tearDown(() => S.bn = false);

    test('converts to Bangla and back', () {
      S.bn = true;
      expect(S.digits('1,250.5'), equals('১,২৫০.৫'));
      expect(S.toEnglishDigits('১২.৫'), equals('12.5'));
    });

    test('leaves English untouched when Bangla is off', () {
      S.bn = false;
      expect(S.digits('1,250'), equals('1,250'));
    });
  });

  group('TransactionModel', () {
    test('server row round trip keeps every field', () {
      final TransactionModel t = _tx('a1', 'Bazar', type: 'income');
      final TransactionModel? back =
          TransactionModel.fromRow(t.toRow('user-1')..['amount'] = 10);
      expect(back, isNotNull);
      expect(back!.id, equals('a1'));
      expect(back.type, equals('income'));
      expect(back.note, equals('Bazar'));
      expect(back.timestamp.toUtc(), equals(t.timestamp.toUtc()));
    });

    test('phone copy round trip', () {
      final TransactionModel t = _tx('b2', null);
      final TransactionModel? back = TransactionModel.fromLocal(t.toLocal());
      expect(back, isNotNull);
      expect(back!.note, isNull);
      expect(back.timestamp, equals(t.timestamp));
    });

    test('rejects rows with an unknown type', () {
      final Map<String, dynamic> row = _tx('c3', 'x').toRow('u')..['type'] = 'refund';
      expect(TransactionModel.fromRow(row), isNull);
    });
  });

  group('NoteSuggestions', () {
    test('most used notes come first and merge by case', () {
      final List<TransactionModel> all = <TransactionModel>[
        _tx('1', 'Rickshaw'),
        _tx('2', 'rickshaw'),
        _tx('3', 'Tea'),
      ];
      final List<String> out = NoteSuggestions.build(all);
      expect(out.first, equals('Rickshaw'));
      expect(out.where((String s) => s.toLowerCase() == 'rickshaw').length, equals(1));
    });

    test('fills up with defaults and respects max', () {
      final List<String> out = NoteSuggestions.build(<TransactionModel>[], max: 4);
      expect(out.length, equals(4));
    });
  });
}
