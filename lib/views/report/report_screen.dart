import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/report_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/strings.dart';
import '../../core/utils/money.dart';
import '../../services/export_service.dart';
import '../dashboard/widgets/summary_card.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.uid});

  final String uid;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final ReportController _c;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _c = ReportController(uid: widget.uid);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _export(String kind) async {
    if (_exporting) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    if (_c.items.isEmpty) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(S.t('no_month'))));
      return;
    }

    setState(() => _exporting = true);
    final bool ok = kind == 'pdf'
        ? await ExportService.sharePdf(
            month: _c.month, items: _c.items, income: _c.income, expense: _c.expense)
        : await ExportService.shareExcel(
            month: _c.month, items: _c.items, income: _c.income, expense: _c.expense);
    if (mounted) setState(() => _exporting = false);

    if (!ok) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(S.t('export_failed'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('report'), style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: <Widget>[
          if (_exporting)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.ios_share_rounded),
              onSelected: _export,
              itemBuilder: (BuildContext _) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'pdf', child: Text(S.t('export_pdf'))),
                PopupMenuItem<String>(value: 'excel', child: Text(S.t('export_excel'))),
              ],
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (BuildContext context, Widget? _) {
          final String monthLabel =
              S.digits(DateFormat('MMMM y', S.locale).format(_c.month));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    onPressed: _c.previous,
                    icon: Icon(Icons.chevron_left_rounded, color: pal.text, size: 30),
                  ),
                  Text(monthLabel,
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: pal.text)),
                  IconButton(
                    onPressed: _c.isCurrentMonth ? null : _c.next,
                    icon: Icon(Icons.chevron_right_rounded,
                        color: _c.isCurrentMonth ? pal.muted : pal.text, size: 30),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(S.t('month_balance'),
                        style: const TextStyle(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(Money.format(_c.net),
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SummaryCard(
                      label: S.t('total_income'),
                      amount: _c.income,
                      color: AppColors.income,
                      icon: Icons.south_west_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SummaryCard(
                      label: S.t('total_expense'),
                      amount: _c.expense,
                      color: AppColors.expense,
                      icon: Icons.north_east_rounded,
                    ),
                  ),
                ],
              ),
              if (_c.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    _c.hasLoaded ? S.t('no_month') : S.t('loading'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: pal.muted, fontSize: 15),
                  ),
                )
              else ...<Widget>[
                const SizedBox(height: 24),
                Text(S.t('daily'),
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: pal.text)),
                const SizedBox(height: 12),
                _DailyBars(income: _c.dailyIncome, expense: _c.dailyExpense, pal: pal),
                if (_c.topExpenses.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 24),
                  Text(S.t('top_spend'),
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800, color: pal.text)),
                  const SizedBox(height: 12),
                  for (final MapEntry<String?, double> e in _c.topExpenses)
                    _TopRow(
                      label: e.key ?? S.t('no_note'),
                      amount: e.value,
                      share: _c.expense <= 0 ? 0 : e.value / _c.expense,
                      pal: pal,
                    ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DailyBars extends StatelessWidget {
  const _DailyBars({required this.income, required this.expense, required this.pal});

  final List<double> income;
  final List<double> expense;
  final AppPalette pal;

  @override
  Widget build(BuildContext context) {
    double maxValue = 1;
    for (int i = 0; i < income.length; i++) {
      if (income[i] > maxValue) maxValue = income[i];
      if (expense[i] > maxValue) maxValue = expense[i];
    }
    const double chartHeight = 110;

    double barHeight(double v) => v <= 0 ? 0 : (v / maxValue * chartHeight).clamp(3, chartHeight);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (int i = 0; i < income.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              height: barHeight(income[i]),
                              decoration: BoxDecoration(
                                color: AppColors.income,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: barHeight(expense[i]),
                              decoration: BoxDecoration(
                                color: AppColors.expense,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              for (int i = 0; i < income.length; i++)
                Expanded(
                  child: (i == 0 || (i + 1) % 5 == 0)
                      ? Text(
                          S.digits('${i + 1}'),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: TextStyle(fontSize: 10, color: pal.muted),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.label,
    required this.amount,
    required this.share,
    required this.pal,
  });

  final String label;
  final double amount;
  final double share;
  final AppPalette pal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: pal.text)),
                ),
                const SizedBox(width: 8),
                Text(Money.format(amount),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.expense)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: share.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: pal.expenseSoft,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.expense),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
