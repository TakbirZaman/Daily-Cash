import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../controllers/calendar_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/strings.dart';
import '../../core/utils/note_suggestions.dart';
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
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('calendar'), style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (BuildContext context, Widget? _) {
          return CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: pal.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
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
                      titleTextStyle: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800, color: pal.text),
                      leftChevronIcon: Icon(Icons.chevron_left, color: pal.text),
                      rightChevronIcon: Icon(Icons.chevron_right, color: pal.text),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: pal.muted),
                      weekendStyle: TextStyle(color: pal.muted),
                    ),
                    selectedDayPredicate: (DateTime d) => isSameDay(_c.selectedDay, d),
                    onDaySelected: (DateTime selected, DateTime focused) =>
                        _c.selectDay(selected, focused),
                    onPageChanged: _c.onPageChanged,
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: TextStyle(color: pal.text),
                      weekendTextStyle: TextStyle(color: pal.text),
                      outsideTextStyle: TextStyle(color: pal.muted),
                      selectedDecoration: const BoxDecoration(
                          color: AppColors.income, shape: BoxShape.circle),
                      selectedTextStyle: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800),
                      todayDecoration: const BoxDecoration(
                          color: Color(0x4D16A36A), shape: BoxShape.circle),
                      todayTextStyle:
                          TextStyle(color: pal.text, fontWeight: FontWeight.w700),
                    ),
                    calendarBuilders: CalendarBuilders<int>(
                      markerBuilder: (BuildContext context, DateTime day, List<int> events) {
                        return Positioned(
                          bottom: 3,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              if (_c.hasIncome(day)) _dot(AppColors.income),
                              if (_c.hasExpense(day)) _dot(AppColors.expense),
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Text(
                    S.digits(DateFormat('EEEE, d MMMM y', S.locale).format(_c.selectedDay)),
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: pal.text),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
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
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (_c.items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _c.hasLoaded ? S.t('no_tx_day') : S.t('loading'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: pal.muted, fontSize: 15),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: _c.items.length,
                    separatorBuilder: (BuildContext _, int __) => const SizedBox(height: 10),
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
