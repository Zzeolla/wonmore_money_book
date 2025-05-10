import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final double rowHeight;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final void Function(DateTime)? onPageChanged;

  const CalendarWidget({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.rowHeight,
    required this.onDaySelected,
    this.onPageChanged
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      locale: 'ko_KR',
      focusedDay: widget.focusedDay,
      firstDay: DateTime.utc(1900, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      headerVisible: false,
      sixWeekMonthsEnforced: true,
      daysOfWeekHeight: 32,
      rowHeight: widget.rowHeight,
      selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
      onDaySelected: widget.onDaySelected,
      onPageChanged: (focusedDay) {
        if (widget.onPageChanged != null) {
          widget.onPageChanged!(focusedDay);
        }
      },
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      calendarBuilders: CalendarBuilders(
        dowBuilder: (context, day) {
          if (day.weekday == DateTime.sunday) {
            return Center(
              child: Text('일', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
            );
          } else if (day.weekday == DateTime.saturday) {
            return Center(
              child: Text('토', style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
            );
          } else {
            return Center(
              child: Text(
                _weekdayString(day.weekday),
                style: TextStyle(color: Colors.black87, fontSize: 16),
              ),
            );
          }
        },
        defaultBuilder: (context, day, focusedDay) {
          return _buildDayCell('${day.day}', Colors.grey.shade100, Colors.black87);
        },
        todayBuilder: (context, day, focusedDay) {
          return _buildDayCell('${day.day}', Colors.amberAccent.withOpacity(0.5), Colors.black);
        },
        selectedBuilder: (context, day, focusedDay) {
          return Container(
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amber, width: 2),
              borderRadius: BorderRadius.circular(8),
              color: Colors.transparent,
            ),
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                '${day.day}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          );
        },
        outsideBuilder: (context, day, focusedDay) {
          return _buildDayCell('${day.day}', Colors.transparent, Colors.grey);
        },
      ),
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: Colors.deepPurpleAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  static Widget _buildDayCell(String text, Color bgColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Text(
          text,
          style: TextStyle(fontSize: 14, color: textColor),
        ),
      ),
    );
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