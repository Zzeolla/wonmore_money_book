import 'package:drift/drift.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

// 카테고리 테이블 (먼저 정의)
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<TransactionType>()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))(); // 기본 카테고리 여부
  TextColumn get iconName => text().withDefault(const Constant('category'))(); // 아이콘 이름
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF9E9E9E))(); // 색상 값 (ARGB)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get userId => text().nullable()();
  TextColumn get createdBy => text().nullable()(); // 생성자 ID
  TextColumn get updatedBy => text().nullable()(); // 수정자 ID
}