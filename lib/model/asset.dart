import 'package:drift/drift.dart';

// 자산 테이블
class Assets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get balance => integer().withDefault(const Constant(0))();
  IntColumn get goalAmount => integer().nullable()();
  TextColumn get type => text().withDefault(const Constant('현금'))(); // 기본값: 현금
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get userId => text().nullable()();
  TextColumn get createdBy => text().nullable()(); // 생성자 ID
  TextColumn get updatedBy => text().nullable()(); // 수정자 ID
}