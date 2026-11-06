import 'package:intl/intl.dart';

import '../l10n/strings.dart';

class Money {
  Money._();

  static final NumberFormat _fmt = NumberFormat('#,##0.##', 'en');

  /// "৳ 1,250" (Bangla digits when the app is in Bangla).
  static String format(double value) => '৳ ${S.digits(_fmt.format(value))}';

  static String signed(double value, {required bool income}) =>
      '${income ? '+' : '−'}${format(value)}';

  /// Plain number for spreadsheets / typing fields: "1250" or "12.5".
  static String raw(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}
