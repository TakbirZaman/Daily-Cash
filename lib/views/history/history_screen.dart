import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../controllers/history_controller.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/note_suggestions.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/app_choice_chip.dart';
import '../../core/widgets/app_input.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
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

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;

    return Scaffold(
      appBar: appBarFor(context, S.t('history')),
      body: ListenableBuilder(
        listenable: _c,
        builder: (BuildContext context, Widget? _) {
          final List<TransactionModel> results = _c.results;

          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.x24, Space.x4, Space.x24, Space.x12),
                child: TextField(
                  onChanged: _c.setQuery,
                  style: AppText.body3(pal.text),
                  decoration: appInput(
                    context,
                    label: S.t('search_hint'),
                    prefixIcon: PhosphorIconsRegular.magnifyingGlass,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.x24),
                child: Row(
                  children: <Widget>[
                    AppChoiceChip(
                      label: S.t('all'),
                      selected: _c.filter == HistoryFilter.all,
                      color: pal.header,
                      onTap: () => _c.setFilter(HistoryFilter.all),
                    ),
                    const SizedBox(width: Space.x8),
                    AppChoiceChip(
                      label: S.t('income'),
                      selected: _c.filter == HistoryFilter.income,
                      color: Brand.income,
                      onTap: () => _c.setFilter(HistoryFilter.income),
                    ),
                    const SizedBox(width: Space.x8),
                    AppChoiceChip(
                      label: S.t('expense'),
                      selected: _c.filter == HistoryFilter.expense,
                      color: Brand.expense,
                      onTap: () => _c.setFilter(HistoryFilter.expense),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.x12),
              Expanded(
                child: !_c.hasLoaded
                    ? const SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: Space.x24),
                        child: SkeletonList(count: 5),
                      )
                    : results.isEmpty
                        ? EmptyState(
                            icon: PhosphorIconsRegular.magnifyingGlass,
                            title: S.t('results_empty_title'),
                            body: S.t('results_empty_body'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                                Space.x24, Space.x4, Space.x24, Space.x32),
                            itemCount: results.length,
                            separatorBuilder: (BuildContext _, int __) =>
                                const SizedBox(height: Space.x12),
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
