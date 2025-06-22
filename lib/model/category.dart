import 'package:drift/drift.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

// 카테고리 테이블 (먼저 정의)
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text().nullable()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<TransactionType>()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get iconName => text().withDefault(const Constant('category'))(); // 아이콘 이름
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF9E9E9E))(); // 색상 값 (ARGB)
  TextColumn get ownerId => text().nullable()();
  TextColumn get createdBy => text().nullable()(); // 생성자 ID
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get updatedBy => text().nullable()(); // 수정자 ID
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}