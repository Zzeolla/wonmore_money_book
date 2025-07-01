import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class Todos extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get title => text()();
  TextColumn get memo => text().nullable()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  TextColumn get ownerId => text().nullable()();
  DateTimeColumn get remindAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}