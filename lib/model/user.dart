import 'package:drift/drift.dart';

class Users extends Table {
  TextColumn get id => text()(); // Supabase UID
  TextColumn get email => text()();
  TextColumn get nickname => text()();
  TextColumn get profileImagePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}