import 'package:flutter/material.dart';

import '../../controllers/history_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/strings.dart';
import '../../core/utils/note_suggestions.dart';
import '../../models/transaction_model.dart';
import '../dashboard/widgets/transaction_tile.dart';
import '../dashboard/widgets/tx_actions.dart';

/// All entries with search (note or amount) and an All / Income / Expense filter.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.uid});

  final String uid;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryController _c;

  @override
  void initState() {
    super.initState();
    _c = HistoryController(uid: widget.uid);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _chip(String label, HistoryFilter value, Color color) {
    final bool selected = _c.filter == value;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : context.pal.text)),
      selected: selected,
      selectedColor: color,
      showCheckmark: false,
      onSelected: (_) => _c.setFilter(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('history'), style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (BuildContext context, Widget? _) {
          final List<TransactionModel> results = _c.results;

          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  onChanged: _c.setQuery,
                  style: TextStyle(color: pal.text),
                  decoration: InputDecoration(
                    hintText: S.t('search_hint'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: pal.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: <Widget>[
                    _chip(S.t('all'), HistoryFilter.all, AppColors.ink),
                    const SizedBox(width: 8),
                    _chip(S.t('income'), HistoryFilter.income, AppColors.income),
                    const SizedBox(width: 8),
                    _chip(S.t('expense'), HistoryFilter.expense, AppColors.expense),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text(
                          _c.hasLoaded ? S.t('no_results') : S.t('loading'),
                          style: TextStyle(color: pal.muted, fontSize: 15),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        itemCount: results.length,
                        separatorBuilder: (BuildContext _, int __) => const SizedBox(height: 10),
                        itemBuilder: (BuildContext ctx, int i) {
                          final TransactionModel tx = results[i];
                          return TransactionTile(
                            tx: tx,
                            onTap: () => openTransactionEditor(
                              ctx,
                              uid: widget.uid,
                              existing: tx,
                              suggestions: NoteSuggestions.build(_c.all),
                            ),
                            onDelete: () => deleteWithUndo(ctx, widget.uid, tx),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
