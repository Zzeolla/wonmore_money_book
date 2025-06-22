
// 거래 내역 테이블 (마지막에 정의)
import 'package:drift/drift.dart';
import 'package:wonmore_money_book/model/asset.dart';
import 'package:wonmore_money_book/model/category.dart';
import 'package:wonmore_money_book/model/installment.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get amount => integer()();
  TextColumn get type => textEnum<TransactionType>()();
  IntColumn get categoryId => integer().nullable().customConstraint('NULL REFERENCES categories(id) ON DELETE SET NULL')();
  IntColumn get assetId => integer().nullable().customConstraint('NULL REFERENCES assets(id) ON DELETE SET NULL')();
  TextColumn get title => text().nullable()(); // 거래 내역 (예: 편의점, 택시비 등)
  TextColumn get memo => text().nullable()();
  IntColumn get installmentId => integer().nullable().customConstraint('NULL REFERENCES installments(id) ON DELETE CASCADE')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}