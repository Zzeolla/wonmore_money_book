import 'package:drift/drift.dart';

class Installments extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get totalAmount => integer()();
  IntColumn get months => integer()();
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