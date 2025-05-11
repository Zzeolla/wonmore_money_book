import 'package:flutter/material.dart';

/// PickerMode: 연/월, 연/월/일, 연/월/일/시/분
enum PickerMode { yearMonth, date, dateTime }

/// 연/월만 선택하는 다이얼로그 (Dropdown 기반)
Future<DateTime?> showYearMonthPickerDialog({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  Color? primaryColor,
}) async {
  int selectedYear = initialDate.year;
  int selectedMonth = initialDate.month;

  return showDialog<DateTime>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('연/월 선택'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 연도 선택
            DropdownButton<int>(
              value: selectedYear,
              items: [
                for (int y = firstDate.year; y <= lastDate.year; y++)
                  DropdownMenuItem(value: y, child: Text('$y년'))
              ],
              onChanged: (y) {
                if (y != null) {
                  selectedYear = y;
                  (context as Element).markNeedsBuild();
                }
              },
            ),
            SizedBox(width: 16),
            // 월 선택
            DropdownButton<int>(
              value: selectedMonth,
              items: [
                for (int m = 1; m <= 12; m++)
                  DropdownMenuItem(value: m, child: Text('$m월'))
              ],
              onChanged: (m) {
                if (m != null) {
                  selectedMonth = m;
                  (context as Element).markNeedsBuild();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(DateTime(selectedYear, selectedMonth));
            },
            child: Text('확인'),
          ),
        ],
      );
    },
  );
}

/// 커스텀 날짜/시간 선택 유틸
Future<DateTime?> showCustomDateTimePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required PickerMode mode,
  Color? primaryColor,
}) async {
  // 1. 연/월만 선택
  if (mode == PickerMode.yearMonth) {
    return await showYearMonthPickerDialog(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      primaryColor: primaryColor,
    );
  }
  // 2. 연/월/일만 선택
  else if (mode == PickerMode.date) {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor ?? Theme.of(context).primaryColor,
          ),
        ),
        child: child ?? SizedBox(),
      ),
    );
    return pickedDate;
  }
  // 3. 연/월/일/시/분 선택
  else if (mode == PickerMode.dateTime) {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor ?? Theme.of(context).primaryColor,
          ),
        ),
        child: child ?? SizedBox(),
      ),
    );
    if (pickedDate == null) return null;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: DateTime.now().hour,
        minute: DateTime.now().minute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFA79BFF), // 보라색
              onPrimary: Colors.white,
              surface: Colors.white, // 배경을 흰색으로
              onSurface: Colors.black,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white, // 배경 흰색
              dialBackgroundColor: Color(0xFFFFF8E1), // 시계(다이얼) 노란색
              dialHandColor: Color(0xFFA79BFF),
              entryModeIconColor: Color(0xFFA79BFF),
            ),
          ),
          child: child ?? SizedBox(),
        );
      },
    );
    if (pickedTime == null) return null;
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }
  return null;
} 