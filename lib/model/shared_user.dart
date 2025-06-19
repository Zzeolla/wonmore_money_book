import 'package:drift/drift.dart';

class SharedUsers extends Table {
  TextColumn get id => text()(); // row ID
  TextColumn get ownerId => text()(); // 그룹의 주인 (Users.id)
  TextColumn get userId => text()(); // 초대된 사용자 ID
  TextColumn get nickname => text()();
  TextColumn get profileImagePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
