import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../controllers/calendar_controller.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/note_suggestions.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../../models/transaction_model.dart';
import '../dashboard/widgets/summary_card.dart';
import '../dashboard/widgets/transaction_tile.dart';
import '../dashboard/widgets/tx_actions.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.uid});

  final String uid;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CalendarController _c;

  @override
  void initState() {
    super.initState();
    _c = CalendarController(uid: widget.uid);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _dot(Color color) => Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: Space.x2),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;

    return Scaffold(
      appBar: appBarFor(context, S.t('calendar')),
      body: ListenableBuilder(
        listenable: _c,
        builder: (BuildContext context, Widget? _) {
          return CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(Space.x24, Space.x4, Space.x24, 0),
                  padding: const EdgeInsets.only(bottom: Space.x8),
                  decoration: BoxDecoration(color: pal.card, borderRadius: Rad.all(Rad.r24)),
                  child: TableCalendar<int>(
                    locale: S.locale,
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    focusedDay: _c.focusedDay,
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const <CalendarFormat, String>{
                      CalendarFormat.month: 'Month',
                    },
                    eventLoader: (DateTime d) => _c.hasAny(d) ? <int>[1] : <int>[],
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: AppText.title3(pal.text),
                      leftChevronIcon:
                          PhosphorIcon(PhosphorIconsRegular.caretLeft, size: 24, color: pal.text),
                      rightChevronIcon:
                          PhosphorIcon(PhosphorIconsRegular.caretRight, size: 24, color: pal.text),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: AppText.caption3(pal.muted),
                      weekendStyle: AppText.caption3(pal.muted),
                    ),
                    selectedDayPredicate: (DateTime d) => isSameDay(_c.selectedDay, d),
                    onDaySelected: (DateTime selected, DateTime focused) =>
                        _c.selectDay(selected, focused),
                    onPageChanged: _c.onPageChanged,
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: AppText.body5(pal.text),
                      weekendTextStyle: AppText.body5(pal.text),
                      outsideTextStyle: AppText.body5(pal.muted),
                      selectedDecoration:
                          const BoxDecoration(color: Brand.income, shape: BoxShape.circle),
                      selectedTextStyle: AppText.body4(Colors.white),
                      todayDecoration:
                          BoxDecoration(color: pal.incomeSoft, shape: BoxShape.circle),
                      todayTextStyle: AppText.body4(pal.text),
                    ),
                    calendarBuilders: CalendarBuilders<int>(
                      markerBuilder: (BuildContext context, DateTime day, List<int> events) {
                        return Positioned(
                          bottom: Space.x4,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              if (_c.hasIncome(day)) _dot(pal.incomeText),
                              if (_c.hasExpense(day)) _dot(pal.expenseText),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Space.x24, Space.x24, Space.x24, Space.x12),
                  child: Text(
                    S.digits(DateFormat('EEEE, d MMMM y', S.locale).format(_c.selectedDay)),
                    style: AppText.heading6(pal.text),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.x24),
                  child: Row(
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
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Space.x16)),
              if (!_c.hasLoaded)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(Space.x24, 0, Space.x24, Space.x32),
                  sliver: SliverToBoxAdapter(child: SkeletonList(count: 2)),
                )
              else if (_c.items.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: PhosphorIconsRegular.calendarBlank,
                    title: S.t('day_empty_title'),
                    body: S.t('day_empty_body'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(Space.x24, 0, Space.x24, Space.x32),
                  sliver: SliverList.separated(
                    itemCount: _c.items.length,
                    separatorBuilder: (BuildContext _, int __) =>
                        const SizedBox(height: Space.x12),
                    itemBuilder: (BuildContext ctx, int i) {
                      final TransactionModel tx = _c.items[i];
                      return TransactionTile(
                        tx: tx,
                        onTap: () => openTransactionEditor(
                          ctx,
                          uid: widget.uid,
                          existing: tx,
                          suggestions: NoteSuggestions.defaults(),
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
