import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../controllers/dashboard_controller.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/money.dart';
import '../../core/utils/note_suggestions.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reveal.dart';
import '../../core/widgets/skeleton.dart';
import '../../models/transaction_model.dart';
import '../../services/ledger_service.dart';
import '../calendar/calendar_screen.dart';
import '../history/history_screen.dart';
import '../report/report_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/summary_card.dart';
import 'widgets/transaction_tile.dart';
import 'widgets/tx_actions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.uid, required this.name});

  final String uid;
  final String name;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController(uid: widget.uid);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => page));
  }

  void _openEditor({TransactionModel? existing}) {
    openTransactionEditor(
      context,
      uid: widget.uid,
      existing: existing,
      suggestions: NoteSuggestions.build(_controller.all),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;

    return Scaffold(
      floatingActionButton: Pressable(
        child: Tooltip(
          message: S.t('add_entry'),
          child: Material(
            color: Brand.income,
            elevation: 4,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _openEditor,
              child: const SizedBox(
                width: 72,
                height: 72,
                child: Center(
                  child: PhosphorIcon(PhosphorIconsRegular.plus, size: 36, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? _) {
          final List<TransactionModel> items = _controller.recent;
          final bool loading = !_controller.hasLoaded;

          return RefreshIndicator(
            color: Brand.income,
            backgroundColor: pal.card,
            onRefresh: LedgerService.instance.sync,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: _Header(
                    name: widget.name,
                    balance: _controller.balance,
                    loading: loading,
                    onCalendar: () => _push(CalendarScreen(uid: widget.uid)),
                    onReport: () => _push(ReportScreen(uid: widget.uid)),
                    onSearch: () => _push(HistoryScreen(uid: widget.uid)),
                    onSettings: () => _push(const SettingsScreen()),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Space.x24, Space.x24, Space.x24, Space.x8),
                    child: Reveal(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: SummaryCard(
                              label: S.t('today_income'),
                              amount: _controller.todayIncome,
                              color: Brand.income,
                              icon: PhosphorIconsRegular.arrowDownLeft,
                              loading: loading,
                            ),
                          ),
                          const SizedBox(width: Space.x12),
                          Expanded(
                            child: SummaryCard(
                              label: S.t('today_expense'),
                              amount: _controller.todayExpense,
                              color: Brand.expense,
                              icon: PhosphorIconsRegular.arrowUpRight,
                              loading: loading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Space.x24, Space.x24, Space.x24, Space.x12),
                    child: Text(S.t('recent'), style: AppText.heading6(pal.text)),
                  ),
                ),
                if (loading)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(Space.x24, 0, Space.x24, Space.x96),
                    sliver: SliverToBoxAdapter(child: SkeletonList()),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Reveal(
                      child: EmptyState(
                        icon: PhosphorIconsRegular.wallet,
                        title: S.t('empty_title'),
                        body: S.t('empty_body'),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(Space.x24, 0, Space.x24, Space.x96),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (BuildContext _, int __) =>
                          const SizedBox(height: Space.x12),
                      itemBuilder: (BuildContext ctx, int i) => TransactionTile(
                        tx: items[i],
                        onTap: () => _openEditor(existing: items[i]),
                        onDelete: () => deleteWithUndo(ctx, widget.uid, items[i]),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.balance,
    required this.loading,
    required this.onCalendar,
    required this.onReport,
    required this.onSearch,
    required this.onSettings,
  });

  final String name;
  final double balance;
  final bool loading;
  final VoidCallback onCalendar;
  final VoidCallback onReport;
  final VoidCallback onSearch;
  final VoidCallback onSettings;

  Widget _icon(IconData icon, String tip, VoidCallback onTap) {
    return IconButton(
      tooltip: tip,
      onPressed: onTap,
      icon: PhosphorIcon(icon, size: 24, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          Space.x24, MediaQuery.of(context).padding.top + Space.x16, Space.x12, Space.x32),
      decoration: BoxDecoration(color: pal.header, borderRadius: Rad.bottom(Rad.r24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: Space.x12),
            child: Text('${S.t('hello')}$name',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title1(pal.onHeader)),
          ),
          const SizedBox(height: Space.x8),
          Row(
            children: <Widget>[
              _icon(PhosphorIconsRegular.calendarBlank, S.t('calendar'), onCalendar),
              _icon(PhosphorIconsRegular.chartBar, S.t('report'), onReport),
              _icon(PhosphorIconsRegular.magnifyingGlass, S.t('history'), onSearch),
              _icon(PhosphorIconsRegular.gear, S.t('settings'), onSettings),
            ],
          ),
          const SizedBox(height: Space.x16),
          Padding(
            padding: const EdgeInsets.only(right: Space.x12),
            child: Text(S.t('balance'), style: AppText.caption1(pal.onHeaderMuted)),
          ),
          const SizedBox(height: Space.x4),
          Padding(
            padding: const EdgeInsets.only(right: Space.x12),
            child: loading
                ? const Skeleton(width: 192, height: 48, color: Color(0x29FFFFFF))
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(Money.format(balance), style: AppText.heading2(pal.onHeader)),
                  ),
          ),
        ],
      ),
    );
  }
}
