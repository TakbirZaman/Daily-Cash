import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../../models/transaction_model.dart';

/// One row. Income and expense are told apart by icon direction, a +/− sign and color.
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
    final Color color = tx.isIncome ? pal.incomeText : pal.expenseText;
    final Color soft = tx.isIncome ? pal.incomeSoft : pal.expenseSoft;
    final String title = tx.note ?? (tx.isIncome ? S.t('income') : S.t('expense'));
    final String when = S.digits(DateFormat('d MMM, h:mm a', S.locale).format(tx.timestamp));

    final Widget card = Material(
      color: pal.card,
      borderRadius: Rad.all(Rad.r16),
      child: InkWell(
        borderRadius: Rad.all(Rad.r16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.x12),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
                child: Center(
                  child: PhosphorIcon(
                    tx.isIncome ? PhosphorIconsRegular.arrowDownLeft : PhosphorIconsRegular.arrowUpRight,
                    size: 24,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: Space.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title3(pal.text)),
                    const SizedBox(height: Space.x2),
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(when,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption5(pal.muted)),
                        ),
                        if (tx.pending) ...<Widget>[
                          const SizedBox(width: Space.x4),
                          Tooltip(
                            message: S.t('syncing'),
                            child: PhosphorIcon(PhosphorIconsRegular.cloudArrowUp,
                                size: 16, color: pal.muted),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.x8),
              Text(Money.signed(tx.amount, income: tx.isIncome), style: AppText.body1(color)),
            ],
          ),
        ),
      ),
    );

    if (onDelete == null) return card;

    return Dismissible(
      key: ValueKey<String>(tx.id),
      direction: DismissDirection.endToStart,
      // Returning false keeps the widget in the tree; the live data stream
      // removes the row itself, so the list never gets out of sync.
      confirmDismiss: (DismissDirection _) async {
        onDelete!();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Space.x24),
        decoration: BoxDecoration(color: Brand.expense, borderRadius: Rad.all(Rad.r16)),
        child: const PhosphorIcon(PhosphorIconsRegular.trash, size: 24, color: Colors.white),
      ),
      child: card,
    );
  }
}
