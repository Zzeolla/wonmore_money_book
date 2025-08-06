import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final double rowHeight;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final void Function(DateTime)? onPageChanged;
  final Map<DateTime, Map<String, int>> dailySummary;

  const CalendarWidget({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.rowHeight,
    required this.onDaySelected,
    this.onPageChanged,
    required this.dailySummary,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _internalFocusedDay;

  @override
  void initState() {
    super.initState();
    _internalFocusedDay = widget.focusedDay;
  }

  void _goToPreviousMonth() {
    setState(() {
      _internalFocusedDay = DateTime(
        _internalFocusedDay.year,
        _internalFocusedDay.month - 1,
      );
    });
    widget.onPageChanged?.call(_internalFocusedDay);
  }

  void _goToNextMonth() {
    setState(() {
      _internalFocusedDay = DateTime(
        _internalFocusedDay.year,
        _internalFocusedDay.month + 1,
      );
    });
    widget.onPageChanged?.call(_internalFocusedDay);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100) {
            _goToNextMonth();
          } else if (details.primaryVelocity! > 100) {
            _goToPreviousMonth();
          }
        }
      },
      child: TableCalendar(
        locale: 'ko_KR',
        focusedDay: _internalFocusedDay,
        firstDay: DateTime.utc(1900, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        headerVisible: false,
        sixWeekMonthsEnforced: true,
        daysOfWeekHeight: 32,
        rowHeight: widget.rowHeight,
        availableGestures: AvailableGestures.none, // 내부 제스처 막고 외부로 처리
        selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
        onDaySelected: widget.onDaySelected,
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            if (day.weekday == DateTime.sunday) {
              return Center(
                child: Text('일', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
              );
            } else if (day.weekday == DateTime.saturday) {
              return Center(
                child: Text('토', style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold)),
              );
            } else {
              return Center(
                child: Text(
                  _weekdayString(day.weekday),
                  style: TextStyle(color: Colors.black87, fontSize: 14),
                ),
              );
            }
          },
          defaultBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, widget.dailySummary);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, widget.dailySummary, isToday: true);
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, widget.dailySummary, isSelected: true);
          },
          outsideBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, widget.dailySummary, isOutside: true);
          },
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Colors.deepPurpleAccent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(
      DateTime day,
      Map<DateTime, Map<String, int>> dailySummary, {
        bool isToday = false,
        bool isSelected = false,
        bool isOutside = false,
      }) {
    final summary = dailySummary[DateTime(day.year, day.month, day.day)];
    final income = summary?['income'] ?? 0;
    final expense = summary?['expense'] ?? 0;

    Color bgColor = Colors.grey.shade100;
    if (isToday) bgColor = Colors.amberAccent.withOpacity(0.5);
    if (isSelected) bgColor = Colors.transparent;
    if (isOutside) bgColor = Colors.transparent;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: Colors.amber, width: 1.5) : null,
      ),
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${day.day}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 10)),
          SizedBox(height: 2),
          Text(
            income > 0 ? '+${_formatAmount(income)}' : '',
            style: TextStyle(color: Colors.blue, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
          Text(
            expense > 0 ? '-${_formatAmount(expense)}' : '',
            style: TextStyle(color: Colors.red, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount == 0) return '';
    if (amount.abs() >= 1000000) {
      double m = amount / 1000000;
      return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    }
    return amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  static String _weekdayString(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '월';
      case DateTime.tuesday:
        return '화';
      case DateTime.wednesday:
        return '수';
      case DateTime.thursday:
        return '목';
      case DateTime.friday:
        return '금';
      default:
        return '';
    }
  }
}