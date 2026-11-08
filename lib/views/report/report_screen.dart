import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../controllers/report_controller.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/reveal.dart';
import '../../core/widgets/skeleton.dart';
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
        ..showSnackBar(SnackBar(content: Text(S.t('month_empty_title'))));
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
      appBar: appBarFor(
        context,
        S.t('report'),
        actions: <Widget>[
          PopupMenuButton<String>(
            enabled: !_exporting,
            color: pal.card,
            shape: RoundedRectangleBorder(borderRadius: Rad.all(Rad.r12)),
            icon: PhosphorIcon(PhosphorIconsRegular.shareNetwork, size: 24, color: pal.text),
            onSelected: _export,
            itemBuilder: (BuildContext _) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'pdf',
                child: Text(S.t('export_pdf'), style: AppText.body5(pal.text)),
              ),
              PopupMenuItem<String>(
                value: 'excel',
                child: Text(S.t('export_excel'), style: AppText.body5(pal.text)),
              ),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (BuildContext context, Widget? _) {
          final String monthLabel = S.digits(DateFormat('MMMM y', S.locale).format(_c.month));

          return ListView(
            padding: const EdgeInsets.fromLTRB(Space.x24, 0, Space.x24, Space.x32),
            children: <Widget>[
              if (_exporting) ...<Widget>[
                ClipRRect(
                  borderRadius: Rad.all(Rad.r4),
                  child: const LinearProgressIndicator(minHeight: 4, color: Brand.income),
                ),
                const SizedBox(height: Space.x8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    onPressed: _c.previous,
                    icon: PhosphorIcon(PhosphorIconsRegular.caretLeft, size: 24, color: pal.text),
                  ),
                  Text(monthLabel, style: AppText.title2(pal.text)),
                  IconButton(
                    onPressed: _c.isCurrentMonth ? null : _c.next,
                    icon: PhosphorIcon(PhosphorIconsRegular.caretRight,
                        size: 24, color: _c.isCurrentMonth ? pal.border : pal.text),
                  ),
                ],
              ),
              const SizedBox(height: Space.x8),
              Container(
                padding: const EdgeInsets.all(Space.x24),
                decoration: BoxDecoration(color: pal.header, borderRadius: Rad.all(Rad.r24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(S.t('month_balance'), style: AppText.caption1(pal.onHeaderMuted)),
                    const SizedBox(height: Space.x4),
                    if (!_c.hasLoaded)
                      const Skeleton(width: 160, height: 40, color: Color(0x29FFFFFF))
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(Money.format(_c.net), style: AppText.heading3(pal.onHeader)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Space.x12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SummaryCard(
                      label: S.t('total_income'),
                      amount: _c.income,
                      color: Brand.income,
                      icon: PhosphorIconsRegular.arrowDownLeft,
                      loading: !_c.hasLoaded,
                    ),
                  ),
                  const SizedBox(width: Space.x12),
                  Expanded(
                    child: SummaryCard(
                      label: S.t('total_expense'),
                      amount: _c.expense,
                      color: Brand.expense,
                      icon: PhosphorIconsRegular.arrowUpRight,
                      loading: !_c.hasLoaded,
                    ),
                  ),
                ],
              ),
              if (_c.hasLoaded && _c.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Space.x24),
                  child: EmptyState(
                    icon: PhosphorIconsRegular.chartBar,
                    title: S.t('month_empty_title'),
                    body: S.t('month_empty_body'),
                  ),
                )
              else if (_c.items.isNotEmpty) ...<Widget>[
                const SizedBox(height: Space.x24),
                Text(S.t('daily'), style: AppText.heading6(pal.text)),
                const SizedBox(height: Space.x12),
                Reveal(
                  child: _DailyBars(income: _c.dailyIncome, expense: _c.dailyExpense, pal: pal),
                ),
                if (_c.topExpenses.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Space.x24),
                  Text(S.t('top_spend'), style: AppText.heading6(pal.text)),
                  const SizedBox(height: Space.x12),
                  for (final MapEntry<String?, double> e in _c.topExpenses) ...<Widget>[
                    _TopRow(
                      label: e.key ?? S.t('no_note'),
                      amount: e.value,
                      share: _c.expense <= 0 ? 0 : e.value / _c.expense,
                      pal: pal,
                    ),
                    const SizedBox(height: Space.x12),
                  ],
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
    const double chartHeight = 112;

    double barHeight(double v) =>
        v <= 0 ? 0 : (v / maxValue * chartHeight).clamp(4.0, chartHeight).toDouble();

    // Outer card is 16 with 12 padding, so the bars use 16 − 12 = 4.
    return Container(
      padding: const EdgeInsets.all(Space.x12),
      decoration: BoxDecoration(color: pal.card, borderRadius: Rad.all(Rad.r16)),
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
                      padding: const EdgeInsets.symmetric(horizontal: Space.x2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              height: barHeight(income[i]),
                              decoration: BoxDecoration(
                                color: pal.incomeText,
                                borderRadius: Rad.all(Rad.r2),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: barHeight(expense[i]),
                              decoration: BoxDecoration(
                                color: pal.expenseText,
                                borderRadius: Rad.all(Rad.r2),
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
          const SizedBox(height: Space.x8),
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
                          style: AppText.caption5(pal.muted),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
          const SizedBox(height: Space.x8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _legend(pal.incomeText, S.t('income'), pal),
              const SizedBox(width: Space.x16),
              _legend(pal.expenseText, S.t('expense'), pal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label, AppPalette pal) {
    return Row(
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: Rad.all(Rad.r2)),
        ),
        const SizedBox(width: Space.x4),
        Text(label, style: AppText.caption4(pal.muted)),
      ],
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
    return Container(
      padding: const EdgeInsets.all(Space.x12),
      decoration: BoxDecoration(color: pal.card, borderRadius: Rad.all(Rad.r16)),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(label,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title3(pal.text)),
              ),
              const SizedBox(width: Space.x8),
              Text(Money.format(amount), style: AppText.body4(pal.expenseText)),
            ],
          ),
          const SizedBox(height: Space.x8),
          // Card is 16 with 12 padding, so the bar uses 16 − 12 = 4.
          ClipRRect(
            borderRadius: Rad.all(Rad.r4),
            child: LinearProgressIndicator(
              value: share.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              backgroundColor: pal.expenseSoft,
              valueColor: AlwaysStoppedAnimation<Color>(pal.expenseText),
            ),
          ),
        ],
      ),
    );
  }
}
