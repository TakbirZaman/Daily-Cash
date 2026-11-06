import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/utils/money.dart';
import '../../../models/transaction_model.dart';
import '../../../services/firestore_service.dart';

/// Quick-entry sheet: amount, optional note, one tap to save.
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

    final FirestoreService db = FirestoreService.instance;
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
        decoration: BoxDecoration(
          color: pal.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_editing) ...<Widget>[
                Text(S.t('edit_entry'),
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: pal.text)),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^[0-9০-৯]*\.?[0-9০-৯]{0,2}')),
                ],
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: pal.text),
                decoration: _decoration(pal, S.t('amount'), prefix: '৳ '),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: pal.text),
                decoration: _decoration(pal, S.t('note_label'), hint: S.t('note_hint')),
              ),
              if (widget.suggestions.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: <Widget>[
                    for (final String s in widget.suggestions)
                      ActionChip(
                        label: Text(s),
                        onPressed: () {
                          _note.text = s;
                          _note.selection = TextSelection.collapsed(offset: s.length);
                        },
                      ),
                  ],
                ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.expense, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _button(
                      _editing ? S.t('save_income') : S.t('add_income'),
                      AppColors.income,
                      TransactionType.income,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _button(
                      _editing ? S.t('save_expense') : S.t('add_expense'),
                      AppColors.expense,
                      TransactionType.expense,
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

  Widget _button(String label, Color color, String type) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () => _save(type),
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }

  InputDecoration _decoration(AppPalette pal, String label, {String? prefix, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      filled: true,
      fillColor: pal.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
