import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:wonmore_money_book/model/asset.dart';
import 'package:wonmore_money_book/model/category.dart';
import 'package:wonmore_money_book/model/period_type.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class FavoriteRecords extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  IntColumn get amount => integer()();
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get period => textEnum<PeriodType>()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get lastGeneratedDate => dateTime().nullable()();
  // IntColumn get originalDay => integer().nullable()(); // 원래 설정된 날짜의 일자
  TextColumn get categoryId => text().nullable().customConstraint('NULL REFERENCES categories(id) ON DELETE SET NULL')();
  TextColumn get assetId => text().nullable().customConstraint('NULL REFERENCES assets(id) ON DELETE SET NULL')();
  TextColumn get title => text().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get ownerId => text().nullable()();
  TextColumn get budgetId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}