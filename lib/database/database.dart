import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:wonmore_money_book/model/asset.dart';
import 'package:wonmore_money_book/model/category.dart';
import 'package:wonmore_money_book/model/transaction.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/model/todo.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Categories, Assets, Transactions, Todos])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // 데이터베이스 최초 생성 시 실행
        await m.createAll();
        // 기본 카테고리 데이터 삽입
        await _insertDefaultCategories();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 3) {
          // Todos 테이블 추가
          await m.createTable(todos);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      }
    );
  }

  // 기본 카테고리 데이터 삽입
  Future<void> _insertDefaultCategories() async {
    int order_income = 0;
    int order_expense = 0;

    // 수입 카테고리
    await into(categories).insert(CategoriesCompanion.insert(
      name: '급여',
      type: TransactionType.income,
      iconName: Value('attach_money'),
      colorValue: Value(0xFF4CAF50), // Colors.green
      sortOrder: Value(order_income++),
    ));
    await into(categories).insert(CategoriesCompanion.insert(
      name: '용돈',
      type: TransactionType.income,
      iconName: Value('account_balance_wallet'),
      colorValue: Value(0xFF009688), // Colors.teal
      sortOrder: Value(order_income++),
    ));
    await into(categories).insert(CategoriesCompanion.insert(
      name: '부수입',
      type: TransactionType.income,
      iconName: Value('payments'),
      colorValue: Value(0xFF8BC34A), // Colors.lightGreen
      sortOrder: Value(order_income++),
    ));

    // 지출 카테고리
    await into(categories).insert(CategoriesCompanion.insert(
      name: '식비',
      type: TransactionType.expense,
      iconName: Value('lunch_dining'),
      colorValue: Value(0xFFFF9800), // Colors.orange
      sortOrder: Value(order_expense++),
    ));
    await into(categories).insert(CategoriesCompanion.insert(
      name: '교통비',
      type: TransactionType.expense,
      iconName: Value('directions_bus'),
      colorValue: Value(0xFF03A9F4), // Colors.lightBlue
      sortOrder: Value(order_expense++),
    ));

    // 추가 기본 카테고리
    await into(categories).insert(CategoriesCompanion.insert(
      name: '쇼핑',
      type: TransactionType.expense,
      iconName: Value('shopping_bag'),
      colorValue: Value(0xFFFF4081), // Colors.pinkAccent
      sortOrder: Value(order_expense++),
    ));
    await into(categories).insert(CategoriesCompanion.insert(
      name: '문화생활',
      type: TransactionType.expense,
      iconName: Value('movie'),
      colorValue: Value(0xFF9C27B0), // Colors.purple
      sortOrder: Value(order_expense++),
    ));
    await into(categories).insert(CategoriesCompanion.insert(
      name: '주거비',
      type: TransactionType.expense,
      iconName: Value('home'),
      colorValue: Value(0xFF795548), // Colors.brown
      sortOrder: Value(order_expense++),
    ));
    await into(categories).insert(CategoriesCompanion.insert(
      name: '통신비',
      type: TransactionType.expense,
      iconName: Value('phone_android'),
      colorValue: Value(0xFF3F51B5), // Colors.indigo
      sortOrder: Value(order_expense++),
    ));
    await into(categories).insert(CategoriesCompanion.insert(
      name: '보험료',
      type: TransactionType.expense,
      iconName: Value('security'),
      colorValue: Value(0xFFF44336), // Colors.red
      sortOrder: Value(order_expense++),
    ));
    await into(categories).insert(CategoriesCompanion.insert(
      name: '교육비',
      type: TransactionType.expense,
      iconName: Value('school'),
      colorValue: Value(0xFF673AB7), // Colors.deepPurple
      sortOrder: Value(order_expense++),
    ));
    await into(categories).insert(CategoriesCompanion.insert(
      name: '기타',
      type: TransactionType.expense,
      iconName: Value('category'),
      colorValue: Value(0xFF9E9E9E), // Colors.grey
      sortOrder: Value(order_expense++),
    ));
  }

  Future<bool> deleteCategory(int id) async {
    await (delete(categories)..where((c) => c.id.equals(id))).go();
    return true;
  }

  Future<void> reorderCategories(List<Category> reorderedList) async {
    await batch((batch) {
      for (int i = 0; i < reorderedList.length; i++) {
        batch.update(
          categories,
          CategoriesCompanion(sortOrder: Value(i)),
          where: (c) => c.id.equals(reorderedList[i].id),
        );
      }
    });
  }

  Future<List<Category>> getCategoriesByType(TransactionType type) {
    return (select(categories)
      ..where((c) => c.type.equals(type.name))
      ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
        .get();
  }

}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}