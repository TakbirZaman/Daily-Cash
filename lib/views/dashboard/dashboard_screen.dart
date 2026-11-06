import 'package:flutter/material.dart';

import '../../controllers/dashboard_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/strings.dart';
import '../../core/utils/money.dart';
import '../../core/utils/note_suggestions.dart';
import '../../models/transaction_model.dart';
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
      floatingActionButton: SizedBox(
        width: 76,
        height: 76,
        child: FloatingActionButton(
          onPressed: _openEditor,
          backgroundColor: AppColors.income,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 44),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? _) {
          final List<TransactionModel> items = _controller.recent;

          return CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _Header(
                  name: widget.name,
                  balance: _controller.balance,
                  onCalendar: () => _push(CalendarScreen(uid: widget.uid)),
                  onReport: () => _push(ReportScreen(uid: widget.uid)),
                  onSearch: () => _push(HistoryScreen(uid: widget.uid)),
                  onSettings: () => _push(const SettingsScreen()),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: SummaryCard(
                          label: S.t('today_income'),
                          amount: _controller.todayIncome,
                          color: AppColors.income,
                          icon: Icons.south_west_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SummaryCard(
                          label: S.t('today_expense'),
                          amount: _controller.todayExpense,
                          color: AppColors.expense,
                          icon: Icons.north_east_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(S.t('recent'),
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: pal.text)),
                ),
              ),
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _controller.hasLoaded ? S.t('empty') : S.t('loading'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: pal.muted, fontSize: 15),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (BuildContext _, int __) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext ctx, int i) => TransactionTile(
                      tx: items[i],
                      onTap: () => _openEditor(existing: items[i]),
                      onDelete: () => deleteWithUndo(ctx, widget.uid, items[i]),
                    ),
                  ),
                ),
            ],
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
    required this.onCalendar,
    required this.onReport,
    required this.onSearch,
    required this.onSettings,
  });

  final String name;
  final double balance;
  final VoidCallback onCalendar;
  final VoidCallback onReport;
  final VoidCallback onSearch;
  final VoidCallback onSettings;

  Widget _icon(IconData icon, String tip, VoidCallback onTap) {
    return IconButton(
      tooltip: tip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: Colors.white, size: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 12, 32),
      decoration: const BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('${S.t('hello')}$name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              _icon(Icons.calendar_month_rounded, S.t('calendar'), onCalendar),
              _icon(Icons.bar_chart_rounded, S.t('report'), onReport),
              _icon(Icons.search_rounded, S.t('history'), onSearch),
              _icon(Icons.settings_rounded, S.t('settings'), onSettings),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(S.t('balance'),
                style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Money.format(balance),
                style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
