import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../models/transaction_model.dart';
import '../../../services/ledger_service.dart';

/// Quick entry: amount, optional note, one tap to save.
/// The date is never asked; the service stamps DateTime.now().
/// Pass [existing] to edit an entry instead (its date is kept).
class TransactionSheet extends StatefulWidget {
  const TransactionSheet({
    super.key,
    required this.uid,
    this.existing,
    this.suggestions = const <String>[],
  });

  final String uid;
  final TransactionModel? existing;
  final List<String> suggestions;

  @override
  State<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<TransactionSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  String? _error;
  bool _saved = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final TransactionModel? e = widget.existing;
    _amount = TextEditingController(text: e == null ? '' : Money.raw(e.amount));
    _note = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save(String type) {
    if (_saved) return; // ignore double taps
    final double? value =
        double.tryParse(S.toEnglishDigits(_amount.text).replaceAll(',', '').trim());
    if (value == null || value <= 0) {
      setState(() => _error = S.t('err_amount'));
      return;
    }

    final LedgerService db = LedgerService.instance;
    final bool ok = _editing
        ? db.updateTransaction(widget.uid, widget.existing!.id,
            amount: value, type: type, note: _note.text)
        : db.addTransaction(widget.uid, amount: value, type: type, note: _note.text);

    if (ok) {
      _saved = true;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop<(String, double)>((_editing ? 'updated' : type, value));
    } else {
      setState(() => _error = S.t('err_save'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: pal.bg, borderRadius: Rad.top(Rad.r24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.x24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_editing) ...<Widget>[
                Text(S.t('edit_entry'), style: AppText.heading6(pal.text)),
                const SizedBox(height: Space.x16),
              ],
              TextField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^[0-9০-৯]*\.?[0-9০-৯]{0,2}')),
                ],
                style: AppText.heading5(pal.text),
                decoration: appInput(context, label: S.t('amount'), prefixText: '৳ '),
              ),
              const SizedBox(height: Space.x12),
              TextField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                style: AppText.body3(pal.text),
                decoration: appInput(context, label: S.t('note_label'), hint: S.t('note_hint')),
              ),
              if (widget.suggestions.isNotEmpty) ...<Widget>[
                const SizedBox(height: Space.x12),
                Wrap(
                  spacing: Space.x8,
                  runSpacing: Space.x8,
                  children: <Widget>[
                    for (final String s in widget.suggestions)
                      ActionChip(
                        label: Text(s, style: AppText.buttonSm(pal.text)),
                        backgroundColor: pal.card,
                        side: BorderSide(color: pal.border),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        onPressed: () {
                          _note.text = s;
                          _note.selection = TextSelection.collapsed(offset: s.length);
                        },
                      ),
                  ],
                ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: Space.x12),
                Text(_error!, style: AppText.body4(pal.expenseText)),
              ],
              const SizedBox(height: Space.x24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppButton(
                      label: _editing ? S.t('save_income') : S.t('add_income'),
                      color: Brand.income,
                      onPressed: () => _save(TransactionType.income),
                    ),
                  ),
                  const SizedBox(width: Space.x12),
                  Expanded(
                    child: AppButton(
                      label: _editing ? S.t('save_expense') : S.t('add_expense'),
                      color: Brand.expense,
                      onPressed: () => _save(TransactionType.expense),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
