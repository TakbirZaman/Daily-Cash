import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/utils/money.dart';
import '../../../models/transaction_model.dart';
import '../../../services/firestore_service.dart';
import 'add_transaction_sheet.dart';

/// Opens the add sheet (or the edit sheet when [existing] is given),
/// then shows a short confirmation.
Future<void> openTransactionEditor(
  BuildContext context, {
  required String uid,
  TransactionModel? existing,
  List<String> suggestions = const <String>[],
}) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  final (String, double)? result = await showModalBottomSheet<(String, double)>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext _) =>
        TransactionSheet(uid: uid, existing: existing, suggestions: suggestions),
  );
  if (result == null) return;

  final bool isUpdate = result.$1 == 'updated';
  final bool income = result.$1 == TransactionType.income;
  final Color color =
      isUpdate ? AppColors.ink : (income ? AppColors.income : AppColors.expense);
  final String label = isUpdate
      ? S.t('updated')
      : (income ? S.t('income_added') : S.t('expense_added'));

  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      backgroundColor: color,
      duration: const Duration(seconds: 2),
      content: Text('$label: ${Money.format(result.$2)}',
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
    ));
}

/// Deletes instantly and offers a few seconds to undo.
void deleteWithUndo(BuildContext context, String uid, TransactionModel tx) {
  final FirestoreService service = FirestoreService.instance;
  service.deleteTransaction(uid, tx.id);

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text('${S.t('deleted')}: ${Money.format(tx.amount)}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: S.t('undo'),
          onPressed: () => service.restoreTransaction(uid, tx),
        ),
      ),
    );
}
