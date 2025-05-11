
// 거래 내역 테이블 (마지막에 정의)
import 'package:drift/drift.dart';
import 'package:wonmore_money_book/model/asset.dart';
import 'package:wonmore_money_book/model/category.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get amount => integer()();
  TextColumn get type => textEnum<TransactionType>()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get assetId => integer().nullable().references(Assets, #id)();
  TextColumn get title => text().nullable()(); // 거래 내역 (예: 편의점, 택시비 등)
  TextColumn get memo => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get userId => text().nullable()(); // Supabase 연동 시 사용
  TextColumn get createdBy => text().nullable()(); // 생성자 ID
  TextColumn get updatedBy => text().nullable()(); // 수정자 ID
}
