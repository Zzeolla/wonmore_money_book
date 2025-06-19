import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/period_type.dart';
import 'package:drift/drift.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';

class RepeatTransactionService {
  final MoneyProvider _provider;

  RepeatTransactionService(this._provider);

  Future<void> generateTodayRepeatedTransactions({FavoriteRecord? favoriteRecord}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final repeatedRecords = favoriteRecord != null
      ? [favoriteRecord]
      : await (_provider.database.select(_provider.database.favoriteRecords)
      ..where((r) => r.period.equals(PeriodType.none.name).not()))
        .get();

    for (final record in repeatedRecords) {
      final startDate = record.startDate ?? today;
      final startTime = TimeOfDay.fromDateTime(startDate);
      
      // 매월 반복의 경우 원래 날짜의 일자를 저장
      final originalDay = record.period == PeriodType.everyMonth ? startDate.day : null;

      final DateTime baseDate = record.lastGeneratedDate ??
          _genInitialBackDate(record.period, startDate);

      DateTime current = DateTime(baseDate.year, baseDate.month, baseDate.day);
      DateTime? prevDate; // 이전 날짜를 저장하여 무한 루프 방지

      while (true) {
        final nextDate = _getNextRepeatDate(record.period, current, originalDay);

        if (nextDate == null || 
            nextDate.isAfter(today) || 
            (prevDate != null && nextDate.isAtSameMomentAs(prevDate))) break;

        final generatedDateTime = DateTime(
          nextDate.year,
          nextDate.month,
          nextDate.day,
          startTime.hour,
          startTime.minute,
        );

        // 거래 생성
        await _provider.addTransaction(TransactionsCompanion(
          date: drift.Value(generatedDateTime),
          amount: drift.Value(record.amount),
          type: drift.Value(record.type),
          categoryId: record.categoryId == null
              ? const drift.Value.absent()
              : drift.Value(record.categoryId),
          assetId:
          record.assetId == null ? const drift.Value.absent() : drift.Value(record.assetId),
          title: record.title == null ? const drift.Value.absent() : drift.Value(record.title),
          memo: record.memo == null ? const drift.Value.absent() : drift.Value(record.memo),
          userId: Value(record.userId),
          createdAt: drift.Value(DateTime.now()),
          updatedAt: drift.Value(DateTime.now()),
          createdBy: Value(record.userId),
          updatedBy: Value(record.userId),
        ));

        prevDate = current;
        current = nextDate; // 다음 루프를 위한 갱신
      }
      // lastGeneratedDate 갱신
      final lastGenDateTime = DateTime(
          current.year,
          current.month,
          current.day,
          startTime.hour,
          startTime.minute
      );
      await _provider.updateFavoriteRecord(
          record.id, FavoriteRecordsCompanion(lastGeneratedDate: drift.Value(lastGenDateTime)));
    }
  }

  DateTime? _getNextRepeatDate(PeriodType period, DateTime from, int? originalDay) {
    switch (period) {
      case PeriodType.everyDay:
        return from.add(const Duration(days: 1));
      case PeriodType.everyWeek:
        return from.add(const Duration(days: 7));
      case PeriodType.everyMonth:
        if (originalDay == null) {
          return DateTime(from.year, from.month + 1, from.day);
        }
        // 다음 달의 마지막 날 구하기
        final nextMonth = DateTime(from.year, from.month + 1, 1);
        final endOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0);
        // 원래 날짜가 다음 달의 마지막 날보다 크면 마지막 날로 조정
        final safeDay = originalDay > endOfNextMonth.day ? endOfNextMonth.day : originalDay;
        return DateTime(from.year, from.month + 1, safeDay);
      case PeriodType.endOfMonth:
        // 현재 날짜가 이미 해당 월의 마지막 날인지 확인
        final nextMonth = DateTime(from.year, from.month + 1, 1);
        final endOfThisMonth = nextMonth.subtract(const Duration(days: 1));
        
        if (from.day == endOfThisMonth.day) {
          // 현재 날짜가 이미 마지막 날이면 다음 달의 마지막 날을 반환
          final nextNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 1);
          final endOfNextMonth = nextNextMonth.subtract(const Duration(days: 1));
          return DateTime(endOfNextMonth.year, endOfNextMonth.month, endOfNextMonth.day);
        } else {
          // 현재 날짜가 마지막 날이 아니면 이번 달의 마지막 날을 반환
          return DateTime(endOfThisMonth.year, endOfThisMonth.month, endOfThisMonth.day);
        }
      default:
        return null;
    }
  }

  DateTime _addMonthConsideringEndOfMonth(DateTime from) {
    final year = from.year;
    final month = from.month + 1;
    final day = from.day;

    // 다음 달의 마지막 날 구하기
    final nextMonthStart = (month > 12) ? DateTime(year + 1, 1) : DateTime(year, month);
    final endOfNextMonth = DateTime(nextMonthStart.year, nextMonthStart.month + 1, 0);
    
    // 원래 날짜가 다음 달의 마지막 날보다 크면 마지막 날로 조정
    final safeDay = day > endOfNextMonth.day ? endOfNextMonth.day : day;

    return DateTime(
      month > 12 ? year + 1 : year,
      month > 12 ? 1 : month,
      safeDay,
    );
  }

  _genInitialBackDate(PeriodType period, DateTime from) {
    switch (period) {
      case PeriodType.everyDay:
        return from.subtract(const Duration(days: 1));
      case PeriodType.everyWeek:
        return from.subtract(const Duration(days: 7));
      case PeriodType.everyMonth:
        final prevMonth = DateTime(from.year, from.month - 1, from.day);
        return prevMonth;
      case PeriodType.endOfMonth:
        final prevMonth = DateTime(from.year, from.month - 1, 1);
        final endOfPrevMonth = DateTime(prevMonth.year, prevMonth.month + 1, 0);
        return DateTime(endOfPrevMonth.year, endOfPrevMonth.month, endOfPrevMonth.day);
      default:
        return from;
    }
  }
}
