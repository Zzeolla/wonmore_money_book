enum PeriodType { none, everyDay, everyWeek, everyMonth, endOfMonth }

String? periodTypeToKo(PeriodType type) {
  switch (type) {
    case PeriodType.everyDay:
      return '매일';
    case PeriodType.everyWeek:
      return '매주';
    case PeriodType.everyMonth:
      return '매달';
    case PeriodType.endOfMonth:
      return '월말';
    case PeriodType.none:
      return '없음';
  }
}

// 매일, 매주, 매월, 월말,