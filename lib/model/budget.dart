
import 'package:drift/drift.dart';

class Budgets extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get ownerId => text()(); // Users.id
  TextColumn get name => text()(); // 개별 가계부 이름

  @override
  Set<Column> get primaryKey => {id};
}
