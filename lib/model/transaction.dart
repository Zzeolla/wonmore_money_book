
// 거래 내역 테이블 (마지막에 정의)
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:wonmore_money_book/model/asset.dart';
import 'package:wonmore_money_book/model/category.dart';
import 'package:wonmore_money_book/model/installment.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class Transactions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  DateTimeColumn get date => dateTime()();
  IntColumn get amount => integer()();
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get categoryId => text().nullable().customConstraint('NULL REFERENCES categories(id) ON DELETE SET NULL')();
  TextColumn get assetId => text().nullable().customConstraint('NULL REFERENCES assets(id) ON DELETE SET NULL')();
  TextColumn get title => text().nullable()(); // 거래 내역 (예: 편의점, 택시비 등)
  TextColumn get memo => text().nullable()();
  TextColumn get installmentId => text().nullable().customConstraint('NULL REFERENCES installments(id) ON DELETE CASCADE')();
  TextColumn get ownerId => text().nullable()();
  TextColumn get budgetId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isAuto => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}