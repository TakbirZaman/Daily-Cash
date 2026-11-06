import '../../models/transaction_model.dart';
import '../l10n/strings.dart';

/// Quick-note chips: the user's most-used notes first, then sensible defaults.
class NoteSuggestions {
  NoteSuggestions._();

  static List<String> defaults() => <String>[
        S.t('sug_food'),
        S.t('sug_transport'),
        S.t('sug_bazar'),
        S.t('sug_bills'),
        S.t('sug_salary'),
        S.t('sug_medicine'),
      ];

  static List<String> build(List<TransactionModel> all, {int max = 8}) {
    final Map<String, int> counts = <String, int>{};
    final Map<String, String> display = <String, String>{};

    for (final TransactionModel t in all) {
      final String? n = t.note?.trim();
      if (n == null || n.isEmpty || n.length > 24) continue;
      final String key = n.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
      display.putIfAbsent(key, () => n);
    }

    final List<String> keys = counts.keys.toList()
      ..sort((String a, String b) => counts[b]!.compareTo(counts[a]!));

    final List<String> out = <String>[
      for (final String k in keys.take(max)) display[k]!,
    ];

    for (final String d in defaults()) {
      if (out.length >= max) break;
      if (!out.any((String o) => o.toLowerCase() == d.toLowerCase())) out.add(d);
    }
    return out;
  }
}
