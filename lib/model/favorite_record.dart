import 'package:drift/drift.dart';
import 'package:wonmore_money_book/model/asset.dart';
import 'package:wonmore_money_book/model/category.dart';
import 'package:wonmore_money_book/model/period_type.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class FavoriteRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amount => integer()();
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get period => textEnum<PeriodType>()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get lastGeneratedDate => dateTime().nullable()();
  IntColumn get originalDay => integer().nullable()(); // 원래 설정된 날짜의 일자
  IntColumn get categoryId => integer().nullable().customConstraint('NULL REFERENCES categories(id) ON DELETE SET NULL')();
  IntColumn get assetId => integer().nullable().customConstraint('NULL REFERENCES assets(id) ON DELETE SET NULL')();
  TextColumn get title => text().nullable()();
  TextColumn get memo => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get userId => text().nullable()(); // Supabase 연동 시 사용
  TextColumn get createdBy => text().nullable()(); // 생성자 ID
  TextColumn get updatedBy => text().nullable()(); // 수정자 ID
}