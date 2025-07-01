import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// 자산 테이블
class Assets extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text()();
  IntColumn get targetAmount => integer().nullable()();
  TextColumn get ownerId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}