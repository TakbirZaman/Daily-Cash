import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/utils/money.dart';
import '../../../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.tx, this.onTap, this.onDelete});

  final TransactionModel tx;

  /// Tap to edit.
  final VoidCallback? onTap;

  /// When set, the tile can be swiped left to delete.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;
    final Color color = tx.isIncome ? AppColors.income : AppColors.expense;
    final Color soft = tx.isIncome ? pal.incomeSoft : pal.expenseSoft;
    final String title = tx.note ?? (tx.isIncome ? S.t('income') : S.t('expense'));
    final String when = S.digits(DateFormat('d MMM, h:mm a', S.locale).format(tx.timestamp));

    final Widget card = Material(
      color: pal.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
                child: Icon(
                  tx.isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: pal.text)),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(when,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.5, color: pal.muted)),
                        ),
                        if (tx.pending) ...<Widget>[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: S.t('syncing'),
                            child: Icon(Icons.cloud_upload_outlined,
                                size: 14, color: pal.muted),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(Money.signed(tx.amount, income: tx.isIncome),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        ),
      ),
    );

    if (onDelete == null) return card;

    return Dismissible(
      key: ValueKey<String>(tx.id),
      direction: DismissDirection.endToStart,
      // Returning false keeps the widget in the tree; the live Firestore stream
      // removes the row itself, so the list never gets out of sync.
      confirmDismiss: (DismissDirection _) async {
        onDelete!();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      child: card,
    );
  }
}
