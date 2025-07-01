import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:wonmore_money_book/model/asset.dart';
import 'package:wonmore_money_book/model/category.dart';

class Installments extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  DateTimeColumn get date => dateTime()();
  IntColumn get totalAmount => integer()();
  IntColumn get months => integer()();
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