import 'package:drift/drift.dart';

class BudgetPermissions extends Table {
  TextColumn get id => text()(); // row ID
  TextColumn get budgetId => text()(); // Budgets.id
  TextColumn get userId => text()();   // Users.id

  @override
  Set<Column> get primaryKey => {id};
}
